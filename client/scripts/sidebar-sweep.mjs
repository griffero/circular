import fs from 'node:fs/promises'
import fsSync from 'node:fs'
import path from 'node:path'
import { chromium } from 'playwright'
import { PNG } from 'pngjs'
import pixelmatch from 'pixelmatch'

const outputDir = '/tmp/circular-linear-sidebar-sweep'
const linearStorage = '/tmp/linear-storage-state.json'
const circularStorage = '/tmp/circular-prod-storage-state.json'
const circularBase = 'http://127.0.0.1:5173'
const linearBase = 'https://linear.app/fintoc'

const viewPairs = [
  { key: 'onb-triage', circular: '/team/ONB/triage', linear: '/team/onboarding/triage' },
  { key: 'onb-issues', circular: '/team/ONB/issues', linear: '/team/onboarding/issues' },
  { key: 'onb-cycles-current', circular: '/team/ONB/cycles/current', linear: '/team/onboarding/cycles/active' },
  { key: 'onb-cycles-upcoming', circular: '/team/ONB/cycles/upcoming', linear: '/team/onboarding/cycles/upcoming' },
  { key: 'onb-projects', circular: '/team/ONB/projects', linear: '/team/onboarding/projects/all' },
  { key: 'onb-views', circular: '/team/ONB/views', linear: '/team/onboarding/views' },
  { key: 'brd-triage', circular: '/team/BRD/triage', linear: '/team/bridge/triage' },
  { key: 'brd-issues', circular: '/team/BRD/issues', linear: '/team/bridge/issues' },
  { key: 'brd-cycles-current', circular: '/team/BRD/cycles/current', linear: '/team/bridge/cycles/active' },
  { key: 'brd-cycles-upcoming', circular: '/team/BRD/cycles/upcoming', linear: '/team/bridge/cycles/upcoming' },
  { key: 'brd-projects', circular: '/team/BRD/projects', linear: '/team/bridge/projects/all' },
  { key: 'brd-views', circular: '/team/BRD/views', linear: '/team/bridge/views' },
]

const viewport = { name: 'desktop', width: 1536, height: 960 }

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

async function prep(page, url, outPath) {
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 45000 })
  await page.addStyleTag({ content: '*,*::before,*::after{animation:none!important;transition:none!important;}' }).catch(() => {})
  await page.waitForTimeout(2200)
  await page.screenshot({ path: outPath, fullPage: false })
}

async function main() {
  await fs.mkdir(outputDir, { recursive: true })
  const browser = await chromium.launch({ headless: true })

  const lc = await browser.newContext({ storageState: linearStorage, viewport: { width: viewport.width, height: viewport.height } })
  const cc = await browser.newContext({ storageState: circularStorage, viewport: { width: viewport.width, height: viewport.height } })
  const lp = await lc.newPage()
  const cp = await cc.newPage()

  const results = []

  for (const pair of viewPairs) {
    const cImg = path.join(outputDir, `${pair.key}__${viewport.name}__circular.png`)
    const lImg = path.join(outputDir, `${pair.key}__${viewport.name}__linear.png`)
    const dImg = path.join(outputDir, `${pair.key}__${viewport.name}__diff.png`)

    await prep(cp, `${circularBase}${pair.circular}`, cImg)
    await prep(lp, `${linearBase}${pair.linear}`, lImg)

    const diffPercent = await compareImages(cImg, lImg, dImg)
    results.push({ view: pair.key, diffPercent, circularUrl: cp.url(), linearUrl: lp.url() })
  }

  await lc.close()
  await cc.close()
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

main().catch((e) => {
  console.error(e)
  process.exit(1)
})
