#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EMAIL="${PARITY_AUTH_EMAIL:-cristobal@fintoc.com}"
API_BASE="${API_BASE:-http://127.0.0.1:3000}"
CIRCULAR_BASE="${CIRCULAR_BASE:-http://127.0.0.1:5173}"
OUTPUT_PATH="${CIRCULAR_STORAGE_STATE:-/tmp/circular-prod-storage-state.json}"

if [[ $# -gt 0 ]]; then
  EMAIL="$1"
fi

wait_for_url() {
  local url="$1"
  local label="$2"
  local attempts="${3:-45}"
  local i code
  for i in $(seq 1 "$attempts"); do
    code="$(curl -sS -o /dev/null -w '%{http_code}' "$url" || true)"
    if [[ "$code" =~ ^2|3 ]]; then
      return 0
    fi
    sleep 1
  done
  echo "Timed out waiting for ${label} (${url})" >&2
  return 1
}

wait_for_url "${API_BASE}/up" "Rails API"
wait_for_url "${CIRCULAR_BASE}" "Circular frontend"

printf 'Requesting magic link for %s\n' "$EMAIL"
magic_response="$(curl -sS -X POST "${API_BASE}/api/v1/auth/magic-link" \
  -H 'Content-Type: application/json' \
  --data "{\"email\":\"${EMAIL}\"}")"
printf '%s\n' "$magic_response"

# Fetch the latest token directly from DB (same token issued for the email in this run).
# This makes the flow reproducible in local dev even when background email delivery is unavailable.
TOKEN="$(
  cd "$ROOT_DIR"
  eval "$(rbenv init - bash)"
  rbenv shell 3.2.2
  bundle exec rails runner "
    email = '${EMAIL}'.downcase
    user = User.where('LOWER(email) = ?', email).first
    abort('user_not_found') if user.nil?

    team = Team.find_or_create_by!(key: 'ONB') do |record|
      record.name = 'Onboarding'
      record.description = 'Parity automation fixture team'
      record.color = '#5e6ad2'
    end

    TeamMembership.find_or_create_by!(user: user, team: team) do |membership|
      membership.role = 'lead'
    end

    if team.workflow_states.none?
      [
        ['Backlog', 'backlog', '#6b7280', 0],
        ['Todo', 'unstarted', '#8b5cf6', 1],
        ['In Progress', 'started', '#f59e0b', 2],
        ['Done', 'completed', '#22c55e', 3],
        ['Canceled', 'canceled', '#ef4444', 4]
      ].each do |name, state_type, color, position|
        team.workflow_states.create!(name: name, state_type: state_type, color: color, position: position)
      end
    end

    if team.issues.none?
      backlog = team.workflow_states.find_by(state_type: 'backlog') || team.workflow_states.first
      team.issues.create!(
        title: 'Parity Seed Issue',
        description: 'Seeded automatically for parity evidence flows',
        creator: user,
        assignee: user,
        priority: 3,
        workflow_state: backlog
      )
    end

    # Keep fixture state stable for evidence captures by removing probe issues from prior runs.
    team.issues.where(%q{title ILIKE 'Parity %' OR title ILIKE 'Delete %'}).where.not(title: 'Parity Seed Issue').find_each(&:destroy!)

    puts user.magic_link_token.to_s
  "
)"

if [[ -z "$TOKEN" ]]; then
  echo "Failed to retrieve magic link token for ${EMAIL}" >&2
  exit 1
fi

printf 'Captured token for %s; writing storage state to %s\n' "$EMAIL" "$OUTPUT_PATH"

(
  cd "$ROOT_DIR/client"
  CIRCULAR_BASE="$CIRCULAR_BASE" VERIFY_TOKEN="$TOKEN" OUTPUT_PATH="$OUTPUT_PATH" node --input-type=module <<'NODE'
import { chromium } from 'playwright'

const base = process.env.CIRCULAR_BASE || 'http://127.0.0.1:5173'
const token = process.env.VERIFY_TOKEN
const output = process.env.OUTPUT_PATH || '/tmp/circular-prod-storage-state.json'

if (!token) {
  throw new Error('Missing VERIFY_TOKEN')
}

const browser = await chromium.launch({ headless: true })
const context = await browser.newContext({ viewport: { width: 1536, height: 960 } })
const page = await context.newPage()

await page.goto(`${base}/auth/verify?token=${encodeURIComponent(token)}`, { waitUntil: 'domcontentloaded', timeout: 30000 })
await page.waitForSelector('[data-testid="app-shell-ready"]', { timeout: 30000 })
await context.storageState({ path: output })
await browser.close()

console.log(`storage_state_written=${output}`)
NODE
)

echo "Circular storage-state bootstrap complete"
