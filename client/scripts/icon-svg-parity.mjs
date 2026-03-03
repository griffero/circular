/* eslint-disable no-console */
import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import crypto from 'node:crypto'
import { chromium } from 'playwright'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const repoRoot = path.resolve(__dirname, '..', '..')

const circularBase = process.env.CIRCULAR_BASE || 'http://127.0.0.1:5173'
const circularStorage = process.env.CIRCULAR_STORAGE_STATE || '/tmp/circular-prod-storage-state.json'
const manifestPath =
  process.env.ICON_PARITY_MANIFEST || path.join(repoRoot, 'parity', 'manifests', 'icon-svg-targets.json')

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
  lines.push(`- Captured: ${result.summary.captured}`)
  lines.push(`- Missing SVG: ${result.summary.missingSvg}`)
  lines.push(`- Errors: ${result.summary.errors}`)
  lines.push(`- Unique SVG hashes: ${result.summary.uniqueHashes}`)
  lines.push('')

  lines.push('## Targets')
  lines.push('')
  lines.push('| ID | Route | Status | SVG hash | Files |')
  lines.push('|---|---|---|---|---|')
  for (const item of result.targets) {
    const files = []
    if (item.files?.screenshot) files.push(`shot: ${item.files.screenshot}`)
    if (item.files?.svg) files.push(`svg: ${item.files.svg}`)
    lines.push(
      `| ${item.id} | ${item.route} | ${item.status} | ${item.svgHash ? item.svgHash.slice(0, 12) : '-'} | ${files.join('<br>') || '-'} |`,
    )
  }

  return `${lines.join('\n')}\n`
}

async function run() {
  await ensureDirs()

  const manifest = await readManifest()
  const blockers = []

  const reachable = await canReach(circularBase)
  if (!reachable) blockers.push(`Circular app is unreachable at ${circularBase}`)

  const hasStorage = await exists(circularStorage)
  if (!hasStorage) blockers.push(`Missing storage state file at ${circularStorage}`)

  const runResult = {
    generatedAt: stableNow(),
    runId,
    manifestPath: path.relative(repoRoot, manifestPath),
    circularBase,
    blockers,
    targets: [],
    summary: {
      total: manifest.targets.length,
      captured: 0,
      missingSvg: 0,
      errors: 0,
      uniqueHashes: 0,
    },
  }

  if (blockers.length) {
    await writeJson(path.join(runDir, 'results.json'), runResult)
    await fs.writeFile(path.join(runDir, 'report.md'), reportMarkdown(runResult), 'utf8')
    await writeJson(path.join(reportsRoot, 'latest.json'), {
      runId,
      generatedAt: runResult.generatedAt,
      status: 'blocked',
      runDir: path.relative(repoRoot, runDir),
    })
    console.log(JSON.stringify({ status: 'blocked', blockers, runDir: path.relative(repoRoot, runDir) }, null, 2))
    return
  }

  const browser = await chromium.launch({ headless: true })
  const context = await browser.newContext({
    storageState: circularStorage,
    viewport: { width: 1536, height: 960 },
  })
  const page = await context.newPage()

  try {
    for (const target of manifest.targets) {
      const entry = {
        id: target.id,
        description: target.description || null,
        route: target.route,
        selector: target.selector,
        svgSelector: target.svgSelector || 'svg',
        status: 'ok',
        error: null,
        svgHash: null,
        files: {
          screenshot: null,
          svg: null,
        },
      }

      try {
        await page.goto(`${circularBase}${target.route}`, { waitUntil: 'domcontentloaded', timeout: 30000 })
        await page.waitForLoadState('networkidle', { timeout: 10000 }).catch(() => {})
        await page.waitForTimeout(400)

        const host = page.locator(target.selector).first()
        await host.waitFor({ state: 'visible', timeout: 10000 })

        const svgNode = target.svgSelector === 'self' ? host : host.locator(target.svgSelector).first()
        const svgVisible = await svgNode.isVisible().catch(() => false)

        if (!svgVisible) {
          entry.status = 'missing_svg'
          runResult.summary.missingSvg += 1
        } else {
          const svgText = await svgNode.evaluate((node) => node.outerHTML)
          const normalized = normalizeSvg(svgText)
          const svgHash = hashOf(normalized)
          entry.svgHash = svgHash

          const svgFile = path.join(svgsDir, `${target.id}.svg`)
          await fs.writeFile(svgFile, `${normalized}\n`, 'utf8')
          entry.files.svg = path.relative(repoRoot, svgFile)

          runResult.summary.captured += 1
        }

        const shotFile = path.join(shotsDir, `${target.id}.png`)
        await host.screenshot({ path: shotFile })
        entry.files.screenshot = path.relative(repoRoot, shotFile)
      } catch (error) {
        entry.status = 'error'
        entry.error = String(error)
        runResult.summary.errors += 1
      }

      runResult.targets.push(entry)
    }
  } finally {
    await context.close().catch(() => {})
    await browser.close().catch(() => {})
  }

  const uniqueHashes = new Set(runResult.targets.map((t) => t.svgHash).filter(Boolean))
  runResult.summary.uniqueHashes = uniqueHashes.size

  await writeJson(path.join(runDir, 'results.json'), runResult)
  await fs.writeFile(path.join(runDir, 'report.md'), reportMarkdown(runResult), 'utf8')

  const resolvedManifest = {
    generatedAt: runResult.generatedAt,
    runId,
    sourceManifest: path.relative(repoRoot, manifestPath),
    entries: runResult.targets.map((t) => ({
      id: t.id,
      route: t.route,
      selector: t.selector,
      svgSelector: t.svgSelector,
      status: t.status,
      svgHash: t.svgHash,
      svgFile: t.files.svg,
      screenshotFile: t.files.screenshot,
    })),
  }
  await writeJson(path.join(runDir, 'manifest.resolved.json'), resolvedManifest)

  await writeJson(path.join(reportsRoot, 'latest.json'), {
    runId,
    generatedAt: runResult.generatedAt,
    status: runResult.summary.errors ? 'partial' : 'ok',
    runDir: path.relative(repoRoot, runDir),
    reportFile: path.relative(repoRoot, path.join(runDir, 'report.md')),
    resultsFile: path.relative(repoRoot, path.join(runDir, 'results.json')),
  })

  console.log(
    JSON.stringify(
      {
        status: runResult.summary.errors ? 'partial' : 'ok',
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
