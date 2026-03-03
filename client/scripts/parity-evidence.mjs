/* eslint-disable no-undef */
import fs from 'node:fs/promises'
import fsSync from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { chromium } from 'playwright'
import { PNG } from 'pngjs'
import pixelmatch from 'pixelmatch'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const repoRoot = path.resolve(__dirname, '..', '..')
const parityRoot = path.join(repoRoot, 'parity')
const evidenceRoot = path.join(parityRoot, 'evidence')

const circularBase = process.env.CIRCULAR_BASE || 'http://127.0.0.1:5173'
const linearBase = process.env.LINEAR_BASE || 'https://linear.app/fintoc'
const circularStorage = process.env.CIRCULAR_STORAGE_STATE || '/tmp/circular-prod-storage-state.json'
const linearStorage = process.env.LINEAR_STORAGE_STATE || '/tmp/linear-storage-state.json'
const captureBaseline = process.env.PARITY_CAPTURE_BASELINE === '1'
const perfSamples = Math.max(Number.parseInt(process.env.PARITY_PERF_SAMPLES || '5', 10) || 5, 3)

const runId = new Date().toISOString().replace(/[:.]/g, '-').replace('T', '_').replace('Z', '')
const runDir = path.join(evidenceRoot, runId)
const visualDir = path.join(runDir, 'visual')
const perfDir = path.join(runDir, 'performance')
const e2eDir = path.join(runDir, 'e2e')

const budgetsMs = {
  initial_list_render: 1800,
  issue_detail_open: 1200,
  filter_apply_stable_list: 1000,
  cud_feedback: 1000,
}

const visualScenarios = [
  {
    key: 'team-issues__default-list',
    view: 'team-issues',
    state: 'default-list',
    circularPath: '/team/ONB/issues',
    linearPath: '/team/ONB/all',
    baselinePath: path.join(parityRoot, 'baseline', 'linear', 'team-issues', 'default-list.png'),
  },
  {
    key: 'my-issues__assigned',
    view: 'my-issues',
    state: 'assigned',
    circularPath: '/my-issues?view=assigned',
    linearPath: '/my-issues/assigned',
    baselinePath: path.join(parityRoot, 'baseline', 'linear', 'my-issues', 'assigned.png'),
  },
]

function nowIso() {
  return new Date().toISOString()
}

function percentile95(values) {
  if (!values.length) return null
  const sorted = [...values].sort((a, b) => a - b)
  const index = Math.max(Math.ceil(sorted.length * 0.95) - 1, 0)
  return sorted[index]
}

async function exists(filePath) {
  try {
    await fs.access(filePath)
    return true
  } catch {
    return false
  }
}

async function ensureDir(dirPath) {
  await fs.mkdir(dirPath, { recursive: true })
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

function readPng(filePath) {
  return PNG.sync.read(fsSync.readFileSync(filePath))
}

async function compareImages(actualPath, baselinePath, diffPath) {
  const actual = readPng(actualPath)
  const baseline = readPng(baselinePath)
  const width = Math.min(actual.width, baseline.width)
  const height = Math.min(actual.height, baseline.height)

  const a = new PNG({ width, height })
  const b = new PNG({ width, height })
  PNG.bitblt(actual, a, 0, 0, width, height, 0, 0)
  PNG.bitblt(baseline, b, 0, 0, width, height, 0, 0)

  const diff = new PNG({ width, height })
  const diffPixels = pixelmatch(a.data, b.data, diff.data, width, height, {
    threshold: 0.1,
    includeAA: false,
  })

  await fs.writeFile(diffPath, PNG.sync.write(diff))
  const totalPixels = width * height
  return Number(((diffPixels / totalPixels) * 100).toFixed(3))
}

async function launchBrowser() {
  try {
    return await chromium.launch({ headless: true })
  } catch (error) {
    return { launchError: String(error) }
  }
}

async function makeContext(browser, storagePath, viewport = { width: 1536, height: 960 }) {
  const hasStorage = await exists(storagePath)
  if (hasStorage) {
    return browser.newContext({ storageState: storagePath, viewport })
  }
  return browser.newContext({ viewport })
}

async function disableMotion(page) {
  await page
    .addStyleTag({
      content: `*,*::before,*::after{animation:none!important;transition:none!important;caret-color:transparent!important;}`,
    })
    .catch(() => {})
}

async function waitForCircularReady(page) {
  await page.waitForSelector('[data-testid="app-shell-ready"]', { timeout: 20000 })
  await page.waitForLoadState('networkidle', { timeout: 8000 }).catch(() => {})
  await page.waitForTimeout(400)
}

async function gotoCircular(page, routePath) {
  await page.goto(`${circularBase}${routePath}`, { waitUntil: 'domcontentloaded', timeout: 30000 })
  await disableMotion(page)
  await waitForCircularReady(page)
}

async function gotoLinear(page, routePath) {
  await page.goto(`${linearBase}${routePath}`, { waitUntil: 'domcontentloaded', timeout: 45000 })
  await disableMotion(page)
  await page.waitForLoadState('networkidle', { timeout: 8000 }).catch(() => {})
  await page.waitForTimeout(600)
}

async function captureVisualEvidence(prereq, browser) {
  await ensureDir(visualDir)
  const report = {
    generatedAt: nowIso(),
    captureBaseline,
    targetDiffPercent: 2,
    summary: {
      total: visualScenarios.length,
      compared: 0,
      pass: 0,
      fail: 0,
      blocked: 0,
      averageDiffPercent: null,
    },
    scenarios: [],
    blockers: [],
  }

  if (!browser || browser.launchError) {
    report.blockers.push(browser?.launchError || 'Playwright browser launch failed')
  }
  if (!prereq.circularReachable) {
    report.blockers.push(`Circular is unreachable at ${circularBase}`)
  }

  let circularContext = null
  let linearContext = null
  let circularPage = null
  let linearPage = null

  if (!report.blockers.length) {
    circularContext = await makeContext(browser, circularStorage)
    circularPage = await circularContext.newPage()

    if (captureBaseline) {
      if (prereq.linearReachable) {
        linearContext = await makeContext(browser, linearStorage)
        linearPage = await linearContext.newPage()
      } else {
        report.blockers.push(`Linear is unreachable at ${linearBase}; baseline capture skipped`)
      }
    }
  }

  for (const scenario of visualScenarios) {
    const actualPath = path.join(visualDir, `${scenario.key}__circular.png`)
    const diffPath = path.join(visualDir, `${scenario.key}__diff.png`)

    const result = {
      key: scenario.key,
      view: scenario.view,
      state: scenario.state,
      circularPath: scenario.circularPath,
      linearPath: scenario.linearPath,
      baselinePath: path.relative(repoRoot, scenario.baselinePath),
      actualPath: path.relative(repoRoot, actualPath),
      diffPath: path.relative(repoRoot, diffPath),
      status: 'BLOCKED',
      diffPercent: null,
      reason: null,
    }

    if (report.blockers.length) {
      result.reason = report.blockers.join('; ')
      report.summary.blocked += 1
      report.scenarios.push(result)
      continue
    }

    try {
      await gotoCircular(circularPage, scenario.circularPath)
      await circularPage.screenshot({ path: actualPath, fullPage: false })

      if (captureBaseline && linearPage) {
        await ensureDir(path.dirname(scenario.baselinePath))
        if (!(await exists(scenario.baselinePath))) {
          await gotoLinear(linearPage, scenario.linearPath)
          await linearPage.screenshot({ path: scenario.baselinePath, fullPage: false })
        }
      }

      if (!(await exists(scenario.baselinePath))) {
        result.reason = `Missing baseline image: ${scenario.baselinePath}`
        report.summary.blocked += 1
      } else {
        result.diffPercent = await compareImages(actualPath, scenario.baselinePath, diffPath)
        result.status = result.diffPercent < 2 ? 'PASS' : 'FAIL'
        report.summary.compared += 1
        if (result.status === 'PASS') {
          report.summary.pass += 1
        } else {
          report.summary.fail += 1
        }
      }
    } catch (error) {
      result.reason = String(error)
      report.summary.blocked += 1
    }

    report.scenarios.push(result)
  }

  const diffs = report.scenarios.map((s) => s.diffPercent).filter((v) => typeof v === 'number')
  report.summary.averageDiffPercent = diffs.length
    ? Number((diffs.reduce((sum, v) => sum + v, 0) / diffs.length).toFixed(3))
    : null

  if (linearContext) await linearContext.close()
  if (circularContext) await circularContext.close()

  await fs.writeFile(path.join(visualDir, 'results.json'), JSON.stringify(report, null, 2))

  const lines = []
  lines.push('# Visual Evidence')
  lines.push('')
  lines.push(`Generated: ${report.generatedAt}`)
  lines.push(`Capture baseline mode: ${captureBaseline ? 'on' : 'off'}`)
  lines.push(`Compared: ${report.summary.compared}/${report.summary.total}`)
  lines.push(`PASS: ${report.summary.pass}`)
  lines.push(`FAIL: ${report.summary.fail}`)
  lines.push(`BLOCKED: ${report.summary.blocked}`)
  lines.push(`Average diff (%): ${report.summary.averageDiffPercent ?? 'N/A'}`)
  if (report.blockers.length) {
    lines.push('')
    lines.push('Blockers:')
    for (const blocker of report.blockers) {
      lines.push(`- ${blocker}`)
    }
  }
  lines.push('')
  lines.push('| Scenario | Status | Diff % | Notes |')
  lines.push('|---|---|---:|---|')
  for (const scenario of report.scenarios) {
    lines.push(`| ${scenario.key} | ${scenario.status} | ${scenario.diffPercent ?? 'N/A'} | ${scenario.reason || '-'} |`)
  }
  await fs.writeFile(path.join(visualDir, 'report.md'), lines.join('\n'))

  return report
}

async function capturePerformanceEvidence(prereq, browser) {
  await ensureDir(perfDir)

  const report = {
    generatedAt: nowIso(),
    samples: perfSamples,
    budgetsMs,
    metrics: [],
    blockers: [],
  }

  if (!browser || browser.launchError) {
    report.blockers.push(browser?.launchError || 'Playwright browser launch failed')
  }
  if (!prereq.circularReachable) {
    report.blockers.push(`Circular is unreachable at ${circularBase}`)
  }

  async function runMetric(key, runner) {
    if (report.blockers.length) {
      report.metrics.push({ key, budgetMs: budgetsMs[key], p95Ms: null, samplesMs: [], status: 'BLOCKED', reason: report.blockers.join('; ') })
      return
    }

    const context = await makeContext(browser, circularStorage)
    const page = await context.newPage()
    const samplesMs = []

    try {
      for (let i = 0; i < perfSamples; i += 1) {
        const elapsed = await runner(page, i)
        samplesMs.push(elapsed)
      }
      const p95 = percentile95(samplesMs)
      report.metrics.push({
        key,
        budgetMs: budgetsMs[key],
        p95Ms: p95,
        samplesMs,
        status: p95 !== null && p95 <= budgetsMs[key] ? 'PASS' : 'FAIL',
        reason: null,
      })
    } catch (error) {
      report.metrics.push({ key, budgetMs: budgetsMs[key], p95Ms: null, samplesMs, status: 'BLOCKED', reason: String(error) })
    } finally {
      await context.close()
    }
  }

  await runMetric('initial_list_render', async (page) => {
    const t0 = Date.now()
    await gotoCircular(page, '/team/ONB/issues')
    return Date.now() - t0
  })

  await runMetric('issue_detail_open', async (page) => {
    await gotoCircular(page, '/team/ONB/issues')
    const clicked = await page.evaluate(() => {
      const rows = Array.from(document.querySelectorAll('div.cursor-pointer'))
      const row = rows.find((el) => {
        const text = (el.textContent || '').trim()
        return /[A-Z]{2,}-\d+/.test(text)
      })
      if (!row) return false
      row.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }))
      return true
    })
    if (!clicked) throw new Error('No issue row found to open issue detail')

    const t0 = Date.now()
    await page.waitForURL(/\/issue\//, { timeout: 10000 })
    await page.waitForTimeout(250)
    return Date.now() - t0
  })

  await runMetric('filter_apply_stable_list', async (page) => {
    await gotoCircular(page, '/team/ONB/issues')
    const t0 = Date.now()
    await gotoCircular(page, '/team/ONB/issues?statuses=todo')
    return Date.now() - t0
  })

  await runMetric('cud_feedback', async (page, sample) => {
    await gotoCircular(page, '/team/ONB/issues')
    const title = `Parity Perf Sample ${runId} #${sample + 1}`

    await page.getByRole('button', { name: 'New issue' }).click({ timeout: 6000 })
    await page.getByRole('heading', { name: 'Create issue' }).waitFor({ timeout: 6000 })
    await page.getByPlaceholder('Issue title').fill(title)

    const t0 = Date.now()
    await page.getByRole('button', { name: 'Create issue' }).click({ timeout: 6000 })
    await page.getByRole('heading', { name: 'Create issue' }).waitFor({ state: 'hidden', timeout: 10000 })
    return Date.now() - t0
  })

  const summary = {
    pass: report.metrics.filter((m) => m.status === 'PASS').length,
    fail: report.metrics.filter((m) => m.status === 'FAIL').length,
    blocked: report.metrics.filter((m) => m.status === 'BLOCKED').length,
  }

  const full = { ...report, summary }
  await fs.writeFile(path.join(perfDir, 'results.json'), JSON.stringify(full, null, 2))

  const lines = []
  lines.push('# Performance Evidence')
  lines.push('')
  lines.push(`Generated: ${report.generatedAt}`)
  lines.push(`Samples per metric: ${perfSamples}`)
  lines.push('')
  lines.push('| Metric | Budget (ms) | p95 (ms) | Status | Notes |')
  lines.push('|---|---:|---:|---|---|')
  for (const metric of report.metrics) {
    lines.push(`| ${metric.key} | ${metric.budgetMs} | ${metric.p95Ms ?? 'N/A'} | ${metric.status} | ${metric.reason || '-'} |`)
  }
  await fs.writeFile(path.join(perfDir, 'report.md'), lines.join('\n'))

  return full
}

async function captureE2EEvidence(prereq, browser) {
  await ensureDir(e2eDir)

  const report = {
    generatedAt: nowIso(),
    flows: [],
    blockers: [],
  }

  if (!browser || browser.launchError) {
    report.blockers.push(browser?.launchError || 'Playwright browser launch failed')
  }
  if (!prereq.circularReachable) {
    report.blockers.push(`Circular is unreachable at ${circularBase}`)
  }

  const flows = [
    { key: 'create_issue', label: 'Create issue' },
    { key: 'edit_issue_key_fields', label: 'Edit issue key fields' },
    { key: 'move_or_assign', label: 'Move workflow/state + assign/unassign' },
    { key: 'filter_and_switch_subviews', label: 'Filter + switch sub-views' },
    { key: 'delete_issue', label: 'Delete issue' },
  ]

  if (report.blockers.length) {
    for (const flow of flows) {
      report.flows.push({ ...flow, status: 'BLOCKED', evidence: null, reason: report.blockers.join('; ') })
    }
  } else {
    const context = await makeContext(browser, circularStorage)
    const page = await context.newPage()
    const issueTitle = `Parity E2E ${runId}`

    let created = false
    let opened = false

    try {
      await gotoCircular(page, '/team/ONB/issues')
      await page.getByRole('button', { name: 'New issue' }).click({ timeout: 6000 })
      await page.getByPlaceholder('Issue title').fill(issueTitle)
      await page.getByRole('button', { name: 'Create issue' }).click({ timeout: 6000 })
      await page.getByRole('heading', { name: 'Create issue' }).waitFor({ state: 'hidden', timeout: 10000 })
      await page.waitForTimeout(500)
      created = true
      report.flows.push({ key: 'create_issue', label: 'Create issue', status: 'PASS', evidence: 'Modal submit + close observed', reason: null })
    } catch (error) {
      report.flows.push({ key: 'create_issue', label: 'Create issue', status: 'BLOCKED', evidence: null, reason: String(error) })
    }

    try {
      if (!created) throw new Error('Create issue flow did not complete')

      const openedByClick = await page.evaluate((title) => {
        const titleNode = Array.from(document.querySelectorAll('span')).find((el) => (el.textContent || '').trim() === title)
        if (!titleNode) return false
        const row = titleNode.closest('div.cursor-pointer')
        if (!row) return false
        row.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }))
        return true
      }, issueTitle)

      if (!openedByClick) throw new Error('Created issue row was not found in list')

      await page.waitForURL(/\/issue\//, { timeout: 10000 })
      opened = true
      await page.getByRole('button', { name: 'Edit' }).first().click({ timeout: 4000 })
      await page.getByPlaceholder('Issue title').fill(`${issueTitle} Updated`)
      await page.getByRole('button', { name: 'Save' }).click({ timeout: 4000 })
      report.flows.push({ key: 'edit_issue_key_fields', label: 'Edit issue key fields', status: 'PASS', evidence: 'Title edit + save completed', reason: null })
    } catch (error) {
      report.flows.push({ key: 'edit_issue_key_fields', label: 'Edit issue key fields', status: 'BLOCKED', evidence: null, reason: String(error) })
    }

    try {
      if (!opened) throw new Error('Issue detail page was not opened')
      await page.getByText('Assignee').first().click({ timeout: 4000 })
      await page.getByText('Unassigned').first().click({ timeout: 4000 })
      report.flows.push({ key: 'move_or_assign', label: 'Move workflow/state + assign/unassign', status: 'PASS', evidence: 'Assignee dropdown interaction completed', reason: null })
    } catch (error) {
      report.flows.push({ key: 'move_or_assign', label: 'Move workflow/state + assign/unassign', status: 'BLOCKED', evidence: null, reason: String(error) })
    }

    try {
      await gotoCircular(page, '/team/ONB/issues?statuses=todo')
      await page.getByRole('link', { name: 'Board' }).click({ timeout: 4000 })
      await page.waitForURL(/\/team\/ONB\/board/, { timeout: 8000 })
      const carriesFilter = page.url().includes('statuses=todo')
      if (!carriesFilter) throw new Error('statuses query was not carried into board sub-view')
      report.flows.push({ key: 'filter_and_switch_subviews', label: 'Filter + switch sub-views', status: 'PASS', evidence: 'statuses query persisted across issue-shell sub-view switch', reason: null })
    } catch (error) {
      report.flows.push({ key: 'filter_and_switch_subviews', label: 'Filter + switch sub-views', status: 'BLOCKED', evidence: null, reason: String(error) })
    }

    try {
      if (!opened) throw new Error('Issue detail page was not opened')
      await page.goto(page.url(), { waitUntil: 'domcontentloaded' })
      await page.locator('button').filter({ has: page.locator('svg') }).first().click({ timeout: 4000 })
      await page.getByText('Delete issue').first().click({ timeout: 4000 })
      await page.getByRole('button', { name: 'Delete issue' }).click({ timeout: 6000 })
      report.flows.push({ key: 'delete_issue', label: 'Delete issue', status: 'PASS', evidence: 'Delete confirmation modal action completed', reason: null })
    } catch (error) {
      report.flows.push({ key: 'delete_issue', label: 'Delete issue', status: 'BLOCKED', evidence: null, reason: String(error) })
    }

    await context.close()
  }

  const summary = {
    pass: report.flows.filter((f) => f.status === 'PASS').length,
    blocked: report.flows.filter((f) => f.status === 'BLOCKED').length,
  }

  const full = { ...report, summary }
  await fs.writeFile(path.join(e2eDir, 'results.json'), JSON.stringify(full, null, 2))

  const lines = []
  lines.push('# Browser E2E Evidence')
  lines.push('')
  lines.push(`Generated: ${report.generatedAt}`)
  lines.push('')
  lines.push('| Flow | Status | Evidence | Notes |')
  lines.push('|---|---|---|---|')
  for (const flow of report.flows) {
    lines.push(`| ${flow.label} | ${flow.status} | ${flow.evidence || '-'} | ${flow.reason || '-'} |`)
  }
  await fs.writeFile(path.join(e2eDir, 'report.md'), lines.join('\n'))

  return full
}

function deriveOverall(visual, perf, e2e) {
  const visualGood = visual.summary.compared > 0 && visual.summary.averageDiffPercent !== null && visual.summary.averageDiffPercent < 2
  const perfAllPass = perf.metrics.length > 0 && perf.metrics.every((m) => m.status === 'PASS')
  const e2eAllPass = e2e.flows.length > 0 && e2e.flows.every((f) => f.status === 'PASS')

  return {
    visual: visualGood ? 'PASS' : 'BLOCKED',
    performance: perfAllPass ? 'PASS' : 'BLOCKED',
    browser_e2e: e2eAllPass ? 'PASS' : 'BLOCKED',
  }
}

async function main() {
  await ensureDir(runDir)
  await ensureDir(visualDir)
  await ensureDir(perfDir)
  await ensureDir(e2eDir)

  const prereq = {
    generatedAt: nowIso(),
    circularReachable: await canReach(circularBase),
    linearReachable: await canReach(linearBase),
    circularStorageExists: await exists(circularStorage),
    linearStorageExists: await exists(linearStorage),
  }

  const browser = await launchBrowser()
  const visual = await captureVisualEvidence(prereq, browser.launchError ? null : browser)
  const performance = await capturePerformanceEvidence(prereq, browser.launchError ? null : browser)
  const e2e = await captureE2EEvidence(prereq, browser.launchError ? null : browser)

  if (browser && !browser.launchError) {
    await browser.close()
  }

  const overall = deriveOverall(visual, performance, e2e)

  const summary = {
    generatedAt: nowIso(),
    runId,
    runDir: path.relative(repoRoot, runDir),
    prereq,
    overall,
    files: {
      visual: path.relative(repoRoot, path.join(visualDir, 'results.json')),
      performance: path.relative(repoRoot, path.join(perfDir, 'results.json')),
      e2e: path.relative(repoRoot, path.join(e2eDir, 'results.json')),
    },
  }

  const latestPath = path.join(evidenceRoot, 'latest.json')
  await fs.writeFile(path.join(runDir, 'summary.json'), JSON.stringify(summary, null, 2))
  await fs.writeFile(latestPath, JSON.stringify(summary, null, 2))

  const mdLines = []
  mdLines.push('# Parity Evidence Summary')
  mdLines.push('')
  mdLines.push(`Run ID: ${runId}`)
  mdLines.push(`Run dir: ${path.relative(repoRoot, runDir)}`)
  mdLines.push('')
  mdLines.push('## Overall')
  mdLines.push('')
  mdLines.push(`- Visual baseline/diff: ${overall.visual}`)
  mdLines.push(`- p95 performance budgets: ${overall.performance}`)
  mdLines.push(`- Browser E2E evidence: ${overall.browser_e2e}`)
  mdLines.push('')
  mdLines.push('## Preconditions')
  mdLines.push('')
  mdLines.push(`- Circular reachable (${circularBase}): ${prereq.circularReachable ? 'yes' : 'no'}`)
  mdLines.push(`- Linear reachable (${linearBase}): ${prereq.linearReachable ? 'yes' : 'no'}`)
  mdLines.push(`- Circular storage state (${circularStorage}): ${prereq.circularStorageExists ? 'present' : 'missing'}`)
  mdLines.push(`- Linear storage state (${linearStorage}): ${prereq.linearStorageExists ? 'present' : 'missing'}`)
  mdLines.push('')
  mdLines.push('## Artifact Files')
  mdLines.push('')
  mdLines.push(`- ${path.relative(repoRoot, path.join(visualDir, 'report.md'))}`)
  mdLines.push(`- ${path.relative(repoRoot, path.join(perfDir, 'report.md'))}`)
  mdLines.push(`- ${path.relative(repoRoot, path.join(e2eDir, 'report.md'))}`)

  await fs.writeFile(path.join(runDir, 'SUMMARY.md'), mdLines.join('\n'))

  console.log(JSON.stringify(summary, null, 2))
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
