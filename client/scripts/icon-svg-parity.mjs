import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import crypto from 'node:crypto'
import { spawn } from 'node:child_process'
import { chromium } from 'playwright'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const repoRoot = path.resolve(__dirname, '..', '..')

const circularBase = process.env.CIRCULAR_BASE || 'http://127.0.0.1:5173'
const linearBase = process.env.LINEAR_BASE || 'https://linear.app/fintoc'
const circularStorage = process.env.CIRCULAR_STORAGE_STATE || '/tmp/circular-prod-storage-state.json'
const linearStorage = process.env.LINEAR_STORAGE_STATE || '/tmp/linear-storage-state.json'
const apiBase = process.env.API_BASE || 'http://127.0.0.1:3000'
const manifestPath =
  process.env.ICON_PARITY_MANIFEST || path.join(repoRoot, 'parity', 'manifests', 'icon-svg-targets.json')
const defaultTeamKey = process.env.ICON_PARITY_TEAM_KEY || 'ONB'
const autoResumeEnabled = process.env.ICON_PARITY_AUTO_RESUME !== '0'
const autoResumeTimeoutMs = Math.max(
  Number.parseInt(process.env.ICON_PARITY_AUTO_RESUME_TIMEOUT_MS || '90000', 10) || 90000,
  5000,
)
const sweepLimit = Math.max(Number.parseInt(process.env.ICON_PARITY_SWEEP_LIMIT || '150', 10) || 150, 10)
const sweepScreenshotLimit = Math.max(
  Number.parseInt(process.env.ICON_PARITY_SWEEP_SCREENSHOT_LIMIT || '20', 10) || 20,
  0,
)

const runId = new Date().toISOString().replace(/[:.]/g, '-').replace('T', '_').replace('Z', '')
const reportsRoot = path.join(repoRoot, 'parity', 'reports', 'icon-svg')
const runDir = path.join(reportsRoot, runId)
const shotsDir = path.join(runDir, 'shots')
const svgsDir = path.join(runDir, 'svgs')

function stableNow() {
  return new Date().toISOString()
}

function hashOf(text) {
  return crypto.createHash('sha256').update(text).digest('hex')
}

function toArray(value) {
  if (!value) return []
  if (Array.isArray(value)) return value.filter(Boolean)
  return [value]
}

function withTeamKey(route, teamKey) {
  if (!route) return route
  return route.replace(/\{TEAM_KEY\}/g, teamKey || defaultTeamKey)
}

async function exists(filePath) {
  try {
    await fs.access(filePath)
    return true
  } catch {
    return false
  }
}

async function canReach(url) {
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), 3000)
  try {
    const response = await fetch(url, { method: 'GET', signal: controller.signal })
    return response.status > 0
  } catch {
    return false
  } finally {
    clearTimeout(timeout)
  }
}

function isLoopbackUrl(url) {
  try {
    const parsed = new URL(url)
    return ['127.0.0.1', 'localhost', '::1'].includes(parsed.hostname)
  } catch {
    return false
  }
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

async function waitForReachable(url, timeoutMs = autoResumeTimeoutMs) {
  const deadline = Date.now() + timeoutMs
  while (Date.now() < deadline) {
    if (await canReach(url)) return true
    await wait(1000)
  }
  return false
}

function spawnShell(command) {
  const shell = '/bin/bash'
  const child = spawn(shell, ['-lc', command], {
    cwd: repoRoot,
    env: process.env,
    stdio: 'ignore',
  })
  return child
}

async function stopManagedProcesses(processes) {
  for (const proc of processes) {
    if (!proc || proc.killed) continue
    proc.kill('SIGTERM')
  }

  const deadline = Date.now() + 8000
  while (Date.now() < deadline) {
    const alive = processes.filter((proc) => proc && !proc.killed && proc.exitCode === null)
    if (!alive.length) return
    await wait(250)
  }

  for (const proc of processes) {
    if (!proc || proc.killed || proc.exitCode !== null) continue
    proc.kill('SIGKILL')
  }
}

async function ensureCircularRuntime() {
  const managed = []
  const notes = []

  let circularReachable = await canReach(circularBase)
  if (circularReachable) {
    return { circularReachable, managed, notes }
  }

  if (!autoResumeEnabled) {
    notes.push('Circular auto-resume disabled via ICON_PARITY_AUTO_RESUME=0')
    return { circularReachable, managed, notes }
  }

  if (!isLoopbackUrl(circularBase)) {
    notes.push(`Skipping Circular auto-resume because CIRCULAR_BASE is not loopback: ${circularBase}`)
    return { circularReachable, managed, notes }
  }

  const apiHealthUrl = `${apiBase.replace(/\/$/, '')}/up`
  let apiReachable = await canReach(apiHealthUrl)
  if (!apiReachable && isLoopbackUrl(apiBase)) {
    notes.push(`Starting Rails server for parity auto-resume (${apiBase})`)
    const rails = spawnShell(
      'if command -v rbenv >/dev/null 2>&1; then eval "$(rbenv init - bash)"; rbenv shell 3.2.2; fi; bundle exec rails server -b 127.0.0.1 -p 3000',
    )
    managed.push(rails)
    apiReachable = await waitForReachable(apiHealthUrl)
    if (!apiReachable) {
      notes.push(`Rails auto-resume failed to reach ${apiHealthUrl}`)
    }
  }

  notes.push(`Starting Vite dev server for parity auto-resume (${circularBase})`)
  const vite = spawnShell('npm --prefix client run dev -- --host 127.0.0.1 --port 5173 --strictPort')
  managed.push(vite)
  circularReachable = await waitForReachable(circularBase)
  if (!circularReachable) {
    notes.push(`Vite auto-resume failed to reach ${circularBase}`)
  }

  return { circularReachable, managed, notes }
}

async function ensureDirs() {
  await fs.mkdir(runDir, { recursive: true })
  await fs.mkdir(shotsDir, { recursive: true })
  await fs.mkdir(svgsDir, { recursive: true })
}

function normalizeSvg(svg) {
  return svg.replace(/\s+/g, ' ').trim()
}

async function writeJson(filePath, data) {
  await fs.writeFile(filePath, `${JSON.stringify(data, null, 2)}\n`)
}

async function readManifest() {
  const raw = await fs.readFile(manifestPath, 'utf8')
  const parsed = JSON.parse(raw)
  if (!Array.isArray(parsed.targets) || parsed.targets.length === 0) {
    throw new Error(`Manifest has no targets: ${manifestPath}`)
  }
  return parsed
}

function reportMarkdown(result) {
  const lines = []
  lines.push('# Icon/SVG Parity Capture Report')
  lines.push('')
  lines.push(`Generated: ${result.generatedAt}`)
  lines.push(`Run ID: ${result.runId}`)
  lines.push(`Manifest: ${result.manifestPath}`)
  lines.push(`Circular base: ${result.circularBase}`)
  lines.push(`Linear base: ${result.linearBase}`)
  lines.push(`Team key: ${result.teamKey}`)
  lines.push('')

  if (result.blockers.length) {
    lines.push('## Blockers')
    for (const blocker of result.blockers) {
      lines.push(`- ${blocker}`)
    }
    lines.push('')
  }

  lines.push('## Summary')
  lines.push(`- Targets: ${result.summary.total}`)
  lines.push(`- Captured (Circular): ${result.summary.captured.circular}`)
  lines.push(`- Captured (Linear): ${result.summary.captured.linear}`)
  lines.push(`- Missing SVG (Circular): ${result.summary.missingSvg.circular}`)
  lines.push(`- Missing SVG (Linear): ${result.summary.missingSvg.linear}`)
  lines.push(`- Errors: ${result.summary.errors}`)
  lines.push(`- Unique SVG hashes: ${result.summary.uniqueHashes}`)
  lines.push(`- Targets with hash overlap: ${result.summary.hashOverlapTargets}`)
  lines.push('')

  lines.push('## Targets')
  lines.push('')
  lines.push('| ID | Circular | Linear | Overlap | Files |')
  lines.push('|---|---|---|---|---|')
  for (const item of result.targets) {
    const files = []
    if (item.circular?.files?.screenshots?.length) files.push(`c-shots: ${item.circular.files.screenshots.length}`)
    if (item.circular?.files?.svgs?.length) files.push(`c-svgs: ${item.circular.files.svgs.length}`)
    if (item.linear?.files?.screenshots?.length) files.push(`l-shots: ${item.linear.files.screenshots.length}`)
    if (item.linear?.files?.svgs?.length) files.push(`l-svgs: ${item.linear.files.svgs.length}`)
    lines.push(
      `| ${item.id} | ${item.circular?.status || '-'} | ${item.linear?.status || '-'} | ${item.hashOverlap?.count || 0} | ${files.join('<br>') || '-'} |`,
    )
  }

  return `${lines.join('\n')}\n`
}

async function contextFor(browser, storagePath) {
  const config = { viewport: { width: 1536, height: 960 } }
  if (await exists(storagePath)) config.storageState = storagePath
  return browser.newContext(config)
}

async function resolveTeamKey(browser, circularReady, hasCircularStorage) {
  if (!circularReady || !hasCircularStorage) return defaultTeamKey
  const context = await contextFor(browser, circularStorage)
  const page = await context.newPage()
  try {
    await page.goto(`${circularBase}/my-issues`, { waitUntil: 'domcontentloaded', timeout: 30000 })
    await page.waitForLoadState('networkidle', { timeout: 8000 }).catch(() => {})
    const key = await page.evaluate(async () => {
      const response = await fetch('/api/v1/auth/me', {
        method: 'GET',
        credentials: 'include',
        headers: { Accept: 'application/json' },
      })
      if (!response.ok) return null
      const payload = await response.json()
      return payload?.teams?.[0]?.key || null
    })
    return key || defaultTeamKey
  } catch {
    return defaultTeamKey
  } finally {
    await context.close().catch(() => {})
  }
}

function resolveSurfaceTarget(target, app, teamKey) {
  const scoped = target?.[app] && typeof target[app] === 'object' ? target[app] : {}
  const route = withTeamKey(scoped.route || target.route, teamKey)
  const selectors = toArray(scoped.selector || target.selector)
  const svgSelectors = toArray(scoped.svgSelector || target.svgSelector || 'svg')
  const mode = scoped.mode || target.mode || (selectors.length ? 'single' : 'sweep')
  const maxSvg = Number.parseInt(scoped.maxSvg || target.maxSvg || sweepLimit, 10) || sweepLimit
  const requiresAuth = Boolean(scoped.requiresAuth ?? target.requiresAuth ?? false)
  return { route, selectors, svgSelectors, mode, maxSvg, requiresAuth }
}

async function pickVisibleLocator(page, selectors) {
  for (const selector of selectors) {
    const locator = page.locator(selector).first()
    const visible = await locator.isVisible().catch(() => false)
    if (visible) return { locator, selector }
    await locator.waitFor({ state: 'visible', timeout: 3000 }).catch(() => {})
    const becameVisible = await locator.isVisible().catch(() => false)
    if (becameVisible) return { locator, selector }
  }
  return null
}

async function pickHeuristicLocator(page, target) {
  const id = (target?.id || '').toLowerCase()
  const description = (target?.description || '').toLowerCase()
  const isHomeLike = id.includes('home') || description.includes('home navigation')
  if (!isHomeLike) return null

  const fallbacks = [
    "aside nav button[aria-label*='Workspace Menu']",
    "button[aria-label*='Workspace Menu']",
    "aside nav a[href*='/pulse/']",
    "a[href*='/pulse/']",
    "aside nav a[href*='/my-issues/assigned']",
  ]
  for (const selector of fallbacks) {
    const locator = page.locator(selector).first()
    const visible = await locator.isVisible().catch(() => false)
    if (visible) return { locator, selector: `heuristic:${selector}` }
    await locator.waitFor({ state: 'visible', timeout: 2000 }).catch(() => {})
    const becameVisible = await locator.isVisible().catch(() => false)
    if (becameVisible) return { locator, selector: `heuristic:${selector}` }
  }
  return null
}

async function pickVisibleSvg(host, svgSelectors) {
  for (const svgSelector of svgSelectors) {
    const candidate = svgSelector === 'self' ? host : host.locator(svgSelector).first()
    const visible = await candidate.isVisible().catch(() => false)
    if (visible) return { locator: candidate, svgSelector }
  }
  return null
}

async function captureSingleTarget({ page, target, app, resolved }) {
  const entry = {
    route: resolved.route,
    mode: 'single',
    status: 'ok',
    error: null,
    selectorUsed: null,
    svgSelectorUsed: null,
    svgHashes: [],
    files: { screenshots: [], svgs: [] },
  }

  const hostPick = (await pickVisibleLocator(page, resolved.selectors)) || (await pickHeuristicLocator(page, target))
  if (!hostPick) {
    entry.status = 'error'
    entry.error = `No visible selector matched: ${resolved.selectors.join(' | ')}`
    return entry
  }
  entry.selectorUsed = hostPick.selector

  const svgPick = await pickVisibleSvg(hostPick.locator, resolved.svgSelectors)
  if (!svgPick) {
    entry.status = 'missing_svg'
    const shotPath = path.join(shotsDir, `${target.id}__${app}.png`)
    await hostPick.locator.screenshot({ path: shotPath }).catch(() => {})
    entry.files.screenshots.push(path.relative(repoRoot, shotPath))
    return entry
  }
  entry.svgSelectorUsed = svgPick.svgSelector

  const svgText = await svgPick.locator.evaluate((node) => node.outerHTML)
  const normalized = normalizeSvg(svgText)
  const hash = hashOf(normalized)
  const svgPath = path.join(svgsDir, `${target.id}__${app}__${hash.slice(0, 12)}.svg`)
  await fs.writeFile(svgPath, `${normalized}\n`, 'utf8')
  entry.svgHashes.push(hash)
  entry.files.svgs.push(path.relative(repoRoot, svgPath))

  const shotPath = path.join(shotsDir, `${target.id}__${app}.png`)
  await hostPick.locator.screenshot({ path: shotPath })
  entry.files.screenshots.push(path.relative(repoRoot, shotPath))

  return entry
}

async function captureSweepTarget({ page, target, app, resolved }) {
  const entry = {
    route: resolved.route,
    mode: 'sweep',
    status: 'ok',
    error: null,
    selectorUsed: null,
    svgSelectorUsed: 'svg:visible',
    svgHashes: [],
    files: { screenshots: [], svgs: [] },
  }

  const nodes = page.locator('svg:visible')
  const total = Math.min(await nodes.count(), resolved.maxSvg)
  if (!total) {
    entry.status = 'missing_svg'
    return entry
  }

  const seen = new Set()
  let screenshotCount = 0
  for (let i = 0; i < total; i += 1) {
    const node = nodes.nth(i)
    const svgText = await node.evaluate((el) => el.outerHTML).catch(() => null)
    if (!svgText) continue
    const normalized = normalizeSvg(svgText)
    const hash = hashOf(normalized)
    if (seen.has(hash)) continue
    seen.add(hash)
    entry.svgHashes.push(hash)

    const svgPath = path.join(svgsDir, `${target.id}__${app}__${hash.slice(0, 12)}.svg`)
    await fs.writeFile(svgPath, `${normalized}\n`, 'utf8')
    entry.files.svgs.push(path.relative(repoRoot, svgPath))

    if (screenshotCount < sweepScreenshotLimit) {
      const shotPath = path.join(shotsDir, `${target.id}__${app}__${hash.slice(0, 12)}.png`)
      await node.screenshot({ path: shotPath }).catch(() => {})
      entry.files.screenshots.push(path.relative(repoRoot, shotPath))
      screenshotCount += 1
    }
  }

  if (!entry.svgHashes.length) entry.status = 'missing_svg'
  return entry
}

async function captureForApp({ app, page, baseUrl, reachable, storageExists, target, teamKey }) {
  const resolved = resolveSurfaceTarget(target, app, teamKey)
  const empty = {
    route: resolved.route,
    mode: resolved.mode,
    status: 'blocked',
    error: null,
    selectorUsed: null,
    svgSelectorUsed: null,
    svgHashes: [],
    files: { screenshots: [], svgs: [] },
  }

  if (!resolved.route) {
    empty.status = 'skipped'
    empty.error = `No route configured for ${app}`
    return empty
  }

  if (!reachable) {
    empty.error = `${app} app is unreachable at ${baseUrl}`
    return empty
  }

  if (resolved.requiresAuth && !storageExists) {
    empty.error = `${app} target requires auth storage-state, missing at ${
      app === 'circular' ? circularStorage : linearStorage
    }`
    return empty
  }

  try {
    await page.goto(`${baseUrl}${resolved.route}`, { waitUntil: 'domcontentloaded', timeout: 45000 })
    await page.waitForLoadState('networkidle', { timeout: 12000 }).catch(() => {})
    await page.waitForTimeout(500)
    return resolved.mode === 'sweep'
      ? captureSweepTarget({ page, target, app, resolved })
      : captureSingleTarget({ page, target, app, resolved })
  } catch (error) {
    empty.status = 'error'
    empty.error = String(error)
    return empty
  }
}

async function run() {
  await ensureDirs()

  const manifest = await readManifest()
  const runtime = await ensureCircularRuntime()
  const managedProcesses = runtime.managed
  const blockers = []
  for (const note of runtime.notes) {
    if (/failed|disabled|Skipping/.test(note)) blockers.push(note)
  }

  const circularReachable = runtime.circularReachable
  const linearReachable = await canReach(linearBase)
  const hasCircularStorage = await exists(circularStorage)
  const hasLinearStorage = await exists(linearStorage)

  if (!circularReachable) blockers.push(`Circular app is unreachable at ${circularBase}`)
  if (!linearReachable) blockers.push(`Linear app is unreachable at ${linearBase}`)
  if (!hasCircularStorage) blockers.push(`Missing Circular storage state file at ${circularStorage}`)
  if (!hasLinearStorage) blockers.push(`Missing Linear storage state file at ${linearStorage}`)

  const runResult = {
    generatedAt: stableNow(),
    runId,
    manifestPath: path.relative(repoRoot, manifestPath),
    circularBase,
    linearBase,
    teamKey: defaultTeamKey,
    prereq: {
      circularReachable,
      linearReachable,
      circularStorageExists: hasCircularStorage,
      linearStorageExists: hasLinearStorage,
    },
    blockers,
    targets: [],
    summary: {
      total: manifest.targets.length,
      captured: {
        circular: 0,
        linear: 0,
      },
      missingSvg: {
        circular: 0,
        linear: 0,
      },
      errors: 0,
      uniqueHashes: 0,
      hashOverlapTargets: 0,
    },
  }

  try {
    const browser = await chromium.launch({ headless: true }).catch((error) => error)
    if (browser instanceof Error) {
      blockers.push(`Playwright launch failed: ${String(browser)}`)
    }

    let circularContext = null
    let linearContext = null
    let circularPage = null
    let linearPage = null
    try {
      if (!(browser instanceof Error)) {
        runResult.teamKey = await resolveTeamKey(browser, circularReachable, hasCircularStorage)
        if (circularReachable) {
          circularContext = await contextFor(browser, circularStorage)
          circularPage = await circularContext.newPage()
        }
        if (linearReachable) {
          linearContext = await contextFor(browser, linearStorage)
          linearPage = await linearContext.newPage()
        }
      }
      for (const target of manifest.targets) {
        const circularEntry = await captureForApp({
          app: 'circular',
          page: circularPage,
          baseUrl: circularBase,
          reachable: circularReachable && Boolean(circularPage),
          storageExists: hasCircularStorage,
          target,
          teamKey: runResult.teamKey,
        })
        const linearEntry = await captureForApp({
          app: 'linear',
          page: linearPage,
          baseUrl: linearBase,
          reachable: linearReachable && Boolean(linearPage),
          storageExists: hasLinearStorage,
          target,
          teamKey: runResult.teamKey,
        })

        const circularHashes = new Set(circularEntry.svgHashes)
        const linearHashes = new Set(linearEntry.svgHashes)
        const overlap = [...circularHashes].filter((hash) => linearHashes.has(hash))

        const entry = {
          id: target.id,
          description: target.description || null,
          circular: circularEntry,
          linear: linearEntry,
          hashOverlap: {
            count: overlap.length,
            sample: overlap.slice(0, 10),
          },
        }

        if (circularEntry.status === 'missing_svg') runResult.summary.missingSvg.circular += 1
        if (linearEntry.status === 'missing_svg') runResult.summary.missingSvg.linear += 1
        if (circularEntry.status === 'error' || linearEntry.status === 'error') runResult.summary.errors += 1
        runResult.summary.captured.circular += circularEntry.svgHashes.length
        runResult.summary.captured.linear += linearEntry.svgHashes.length
        if (overlap.length) runResult.summary.hashOverlapTargets += 1

        runResult.targets.push(entry)
      }
    } finally {
      await circularContext?.close().catch(() => {})
      await linearContext?.close().catch(() => {})
      if (!(browser instanceof Error)) {
        await browser.close().catch(() => {})
      }
    }
  } finally {
    await stopManagedProcesses(managedProcesses)
  }

  const uniqueHashes = new Set(
    runResult.targets.flatMap((target) => [...target.circular.svgHashes, ...target.linear.svgHashes]),
  )
  runResult.summary.uniqueHashes = uniqueHashes.size

  await writeJson(path.join(runDir, 'results.json'), runResult)
  await fs.writeFile(path.join(runDir, 'report.md'), reportMarkdown(runResult), 'utf8')

  const resolvedManifest = {
    generatedAt: runResult.generatedAt,
    runId,
    sourceManifest: path.relative(repoRoot, manifestPath),
    teamKey: runResult.teamKey,
    entries: runResult.targets,
  }
  await writeJson(path.join(runDir, 'manifest.resolved.json'), resolvedManifest)

  const status =
    runResult.summary.errors > 0
      ? 'partial'
      : runResult.summary.captured.circular + runResult.summary.captured.linear > 0
        ? 'ok'
        : 'blocked'

  await writeJson(path.join(reportsRoot, 'latest.json'), {
    runId,
    generatedAt: runResult.generatedAt,
    status,
    runDir: path.relative(repoRoot, runDir),
    reportFile: path.relative(repoRoot, path.join(runDir, 'report.md')),
    resultsFile: path.relative(repoRoot, path.join(runDir, 'results.json')),
  })

  console.log(
    JSON.stringify(
      {
        status,
        runDir: path.relative(repoRoot, runDir),
        summary: runResult.summary,
      },
      null,
      2,
    ),
  )
}

run().catch((error) => {
  console.error(error)
  process.exit(1)
})
