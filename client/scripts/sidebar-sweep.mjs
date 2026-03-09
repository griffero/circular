import fs from 'node:fs/promises'
import fsSync from 'node:fs'
import path from 'node:path'
import { chromium } from 'playwright'
import { PNG } from 'pngjs'
import pixelmatch from 'pixelmatch'

const outputDir = '/tmp/circular-linear-sidebar-sweep'
const linearStorage = '/tmp/linear-storage-state.json'
const circularStorage = '/tmp/circular-prod-storage-state.json'
const circularBase = process.env.CIRCULAR_BASE || 'http://127.0.0.1:5173'
const linearBase = process.env.LINEAR_BASE || 'https://linear.app/fintoc'

const viewPairs = [
  { key: 'onb-triage', circular: '/team/ONB/triage', linear: '/team/ONB/triage', linearReadyText: 'Triage' },
  { key: 'onb-issues', circular: '/team/ONB/issues', linear: '/team/ONB/all', linearReadyText: 'All issues' },
  { key: 'onb-cycles-current', circular: '/team/ONB/cycles/current', linear: '/team/ONB/cycle/active', linearReadyText: 'Cycle' },
  { key: 'onb-cycles-upcoming', circular: '/team/ONB/cycles/upcoming', linear: '/team/ONB/cycle/upcoming', linearReadyText: 'Upcoming' },
  { key: 'onb-projects', circular: '/team/ONB/projects', linear: '/team/ONB/projects/all', linearReadyText: 'All projects' },
  { key: 'onb-views', circular: '/team/ONB/views', linear: '/team/ONB/views/issues', linearReadyText: 'Views' },
  { key: 'brd-triage', circular: '/team/BRD/triage', linear: '/team/BRD/triage', linearReadyText: 'Triage' },
  { key: 'brd-issues', circular: '/team/BRD/issues', linear: '/team/BRD/all', linearReadyText: 'All issues' },
  { key: 'brd-cycles-current', circular: '/team/BRD/cycles/current', linear: '/team/BRD/cycle/active', linearReadyText: 'Cycle' },
  { key: 'brd-cycles-upcoming', circular: '/team/BRD/cycles/upcoming', linear: '/team/BRD/cycle/upcoming', linearReadyText: 'Upcoming' },
  { key: 'brd-projects', circular: '/team/BRD/projects', linear: '/team/BRD/projects/all', linearReadyText: 'All projects' },
  { key: 'brd-views', circular: '/team/BRD/views', linear: '/team/BRD/views/issues', linearReadyText: 'Views' },
]

const viewFilter = process.env.VIEW_FILTER
const activeViewPairs = viewFilter
  ? viewPairs.filter((pair) => pair.key.includes(viewFilter))
  : viewPairs

const viewports = [
  { name: 'desktop', width: 1536, height: 960 },
]

function readLinearDarkModeFromStorageState() {
  try {
    const raw = fsSync.readFileSync(linearStorage, 'utf8')
    const state = JSON.parse(raw)
    const origin = (state.origins || []).find((o) => o.origin === 'https://linear.app')
    const darkEntry = (origin?.localStorage || []).find((item) => item.name === 'darkMode')
    return darkEntry?.value === 'true'
  } catch {
    return false
  }
}

function readPng(filePath) {
  return PNG.sync.read(fsSync.readFileSync(filePath))
}

async function compareImages(circularPath, linearPath, diffPath) {
  const c = readPng(circularPath)
  const l = readPng(linearPath)
  const width = Math.min(c.width, l.width)
  const height = Math.min(c.height, l.height)
  const a = new PNG({ width, height })
  const b = new PNG({ width, height })
  PNG.bitblt(c, a, 0, 0, width, height, 0, 0)
  PNG.bitblt(l, b, 0, 0, width, height, 0, 0)
  const diff = new PNG({ width, height })
  const diffPixels = pixelmatch(a.data, b.data, diff.data, width, height, { threshold: 0.1, includeAA: false })
  await fs.writeFile(diffPath, PNG.sync.write(diff))
  return Number(((diffPixels / (width * height)) * 100).toFixed(3))
}

async function prep(page, url, outPath, opts = {}) {
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 45000 })
  await page.addStyleTag({ content: '*,*::before,*::after{animation:none!important;transition:none!important;}' }).catch(() => {})
  if (opts.circular) {
    await page.waitForSelector('[data-testid="app-shell-ready"]', { timeout: 30000 })
    await page.waitForLoadState('networkidle', { timeout: 12000 }).catch(() => {})

    // Require spinner-free stability window before capture.
    const stableChecks = 8
    for (let i = 0; i < stableChecks; i += 1) {
      const hasSpinner = await page.evaluate(() => document.querySelectorAll('.animate-spin').length > 0)
      if (hasSpinner) {
        throw new Error('Circular view still loading (spinner visible)')
      }
      await page.waitForTimeout(200)
    }
  }
  if (opts.linearReadyText) {
    await page.waitForFunction((expected) => {
      const body = document.body?.innerText || ''
      return body.includes(expected)
    }, opts.linearReadyText, { timeout: 25000 })
  }
  await page.waitForTimeout(1200)
  await page.screenshot({ path: outPath, fullPage: false })
}

async function prepWithRetry(page, url, outPath, opts = {}, attempts = 2) {
  let lastError = null
  for (let i = 1; i <= attempts; i += 1) {
    try {
      await prep(page, url, outPath, opts)
      return
    } catch (err) {
      lastError = err
      if (i < attempts) {
        await page.waitForTimeout(1200)
      }
    }
  }
  throw lastError
}

async function main() {
  await fs.mkdir(outputDir, { recursive: true })
  let browser
  try {
    browser = await chromium.launch({ channel: 'chrome', headless: true })
  } catch {
    browser = await chromium.launch({ headless: true })
  }

  const results = []

  for (const viewport of viewports) {
    const linearDarkMode = readLinearDarkModeFromStorageState()
    const lc = await browser.newContext({ storageState: linearStorage, viewport: { width: viewport.width, height: viewport.height } })
    const cc = await browser.newContext({ storageState: circularStorage, viewport: { width: viewport.width, height: viewport.height } })
    const lp = await lc.newPage()
    const cp = await cc.newPage()
    await cp.addInitScript((isDark) => {
      localStorage.setItem('darkMode', isDark ? 'true' : 'false')
      if (isDark) {
        document.documentElement.classList.add('dark')
      } else {
        document.documentElement.classList.remove('dark')
      }
    }, linearDarkMode)

    for (const pair of activeViewPairs) {
      const cImg = path.join(outputDir, `${pair.key}__${viewport.name}__circular.png`)
      const lImg = path.join(outputDir, `${pair.key}__${viewport.name}__linear.png`)
      const dImg = path.join(outputDir, `${pair.key}__${viewport.name}__diff.png`)

      try {
        await prepWithRetry(cp, `${circularBase}${pair.circular}`, cImg, { circular: true }, 2)
        await prepWithRetry(lp, `${linearBase}${pair.linear}`, lImg, { linearReadyText: pair.linearReadyText }, 2)

        const diffPercent = await compareImages(cImg, lImg, dImg)
        results.push({
          view: pair.key,
          viewport: viewport.name,
          width: viewport.width,
          height: viewport.height,
          diffPercent,
          error: null,
          circularUrl: cp.url(),
          linearUrl: lp.url(),
        })
      } catch (err) {
        results.push({
          view: pair.key,
          viewport: viewport.name,
          width: viewport.width,
          height: viewport.height,
          diffPercent: null,
          error: String(err),
          circularUrl: cp.url(),
          linearUrl: lp.url(),
        })
      }
    }

    await lc.close()
    await cc.close()
  }
  await browser.close()

  const summary = {
    total: results.length,
    average: Number((results.filter(r => typeof r.diffPercent === 'number').reduce((a, r) => a + r.diffPercent, 0) / Math.max(results.filter(r => typeof r.diffPercent === 'number').length, 1)).toFixed(3)),
    best: results.filter(r => typeof r.diffPercent === 'number').reduce((m, r) => Math.min(m, r.diffPercent), 100),
    worst: results.filter(r => typeof r.diffPercent === 'number').reduce((m, r) => Math.max(m, r.diffPercent), 0),
    passedUnder1: results.filter((r) => typeof r.diffPercent === 'number' && r.diffPercent < 1).length,
    errored: results.filter((r) => r.error).length,
  }

  await fs.writeFile(path.join(outputDir, 'results.json'), JSON.stringify({ summary, results }, null, 2))
  console.log(JSON.stringify({ outputDir, summary, results }, null, 2))
}

main().catch((e) => {
  console.error(e)
  process.exit(1)
})
