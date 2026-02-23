import fs from 'node:fs/promises'
import fsSync from 'node:fs'
import path from 'node:path'
import { chromium } from 'playwright'
import { PNG } from 'pngjs'
import pixelmatch from 'pixelmatch'

const outputDir = '/tmp/circular-linear-visual-focus-1'
const linearStorage = '/tmp/linear-storage-state.json'
const circularStorage = '/tmp/circular-prod-storage-state.json'
const circularBase = 'http://127.0.0.1:5173'
const linearBase = 'https://linear.app/fintoc'

const viewPairs = [
  { key: 'my-issues', circular: '/my-issues', linear: '/my-issues/assigned' },
  { key: 'projects', circular: '/projects', linear: '/projects/all' },
  { key: 'views', circular: '/views', linear: '/views' },
]

const viewports = [
  { name: 'desktop', width: 1536, height: 960 },
  { name: 'laptop', width: 1366, height: 768 },
  { name: 'mobile', width: 390, height: 844 },
]

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
    await page.waitForSelector('[data-testid="app-shell-ready"]', { timeout: 45000 }).catch(() => {})
    if (opts.readySelector) {
      await page.waitForSelector(opts.readySelector, { timeout: 30000 }).catch(() => {})
    }
    if (opts.waitNoSpinnerIn) {
      await page
        .waitForSelector(`${opts.waitNoSpinnerIn} .animate-spin`, { state: 'detached', timeout: 30000 })
        .catch(() => {})
    }
  }
  await page.waitForTimeout(1200)
  await page.screenshot({ path: outPath, fullPage: false })
}

async function main() {
  await fs.mkdir(outputDir, { recursive: true })
  const browser = await chromium.launch({ headless: true })
  const results = []

  for (const vp of viewports) {
    const lc = await browser.newContext({ storageState: linearStorage, viewport: { width: vp.width, height: vp.height } })
    const cc = await browser.newContext({ storageState: circularStorage, viewport: { width: vp.width, height: vp.height } })
    const lp = await lc.newPage()
    const cp = await cc.newPage()
    await cp.addInitScript(() => {
      localStorage.setItem('darkMode', 'false')
      document.documentElement.classList.remove('dark')
    })

    for (const pair of viewPairs) {
      const cImg = path.join(outputDir, `${pair.key}__${vp.name}__circular.png`)
      const lImg = path.join(outputDir, `${pair.key}__${vp.name}__linear.png`)
      const dImg = path.join(outputDir, `${pair.key}__${vp.name}__diff.png`)
      const circularReadySelector = {
        'my-issues': '[data-testid="my-issues-ready"]',
        projects: '[data-testid="projects-ready"]',
        views: '[data-testid="views-ready"]',
      }[pair.key]
      const circularNoSpinnerSelector = {
        'my-issues': '[data-testid="my-issues-ready"]',
        views: '[data-testid="views-ready"]',
      }[pair.key]
      await prep(cp, `${circularBase}${pair.circular}`, cImg, {
        circular: true,
        readySelector: circularReadySelector,
        waitNoSpinnerIn: circularNoSpinnerSelector,
      })
      await prep(lp, `${linearBase}${pair.linear}`, lImg)
      const diffPercent = await compareImages(cImg, lImg, dImg)
      results.push({ view: pair.key, viewport: vp.name, diffPercent, circularUrl: cp.url(), linearUrl: lp.url() })
    }

    await lc.close()
    await cc.close()
  }

  await browser.close()
  const summary = {
    total: results.length,
    average: Number((results.reduce((a, r) => a + r.diffPercent, 0) / results.length).toFixed(3)),
    best: results.reduce((m, r) => Math.min(m, r.diffPercent), 100),
    worst: results.reduce((m, r) => Math.max(m, r.diffPercent), 0),
  }
  await fs.writeFile(path.join(outputDir, 'results.json'), JSON.stringify({ summary, results }, null, 2))
  console.log(JSON.stringify({ outputDir, summary, results }, null, 2))
}

main().catch((e) => { console.error(e); process.exit(1) })
