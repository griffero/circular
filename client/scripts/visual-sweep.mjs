import fs from 'node:fs/promises'
import fsSync from 'node:fs'
import path from 'node:path'
import { chromium } from 'playwright'
import { PNG } from 'pngjs'
import pixelmatch from 'pixelmatch'

const outputDir = '/tmp/circular-linear-visual-sweep-3'
const linearStorage = '/tmp/linear-storage-state.json'
const circularStorage = '/tmp/circular-prod-storage-state.json'

const circularBase = 'http://127.0.0.1:5173'
const linearBase = 'https://linear.app/fintoc'

const viewPairs = [
  { key: 'home', circular: '/', linear: '/pulse/following' },
  { key: 'inbox', circular: '/inbox', linear: '/inbox' },
  { key: 'my-issues', circular: '/my-issues', linear: '/my-issues/assigned' },
  { key: 'initiatives', circular: '/initiatives', linear: '/initiatives' },
  { key: 'projects', circular: '/projects', linear: '/projects/all' },
  { key: 'views', circular: '/views', linear: '/views' },
  { key: 'team-active-onb', circular: '/team/ONB/active', linear: '/team/ONB/active' },
  { key: 'team-backlog-onb', circular: '/team/ONB/backlog', linear: '/team/ONB/backlog' },
  { key: 'team-board-onb', circular: '/team/ONB/board', linear: '/team/ONB/all' },
  { key: 'team-cycles-onb', circular: '/team/ONB/cycles', linear: '/team/ONB/cycles' },
]

const viewports = [
  { name: 'desktop', width: 1536, height: 960 },
  { name: 'laptop', width: 1366, height: 768 },
  { name: 'mobile', width: 390, height: 844 },
]

async function exists(filePath) {
  try {
    await fs.access(filePath)
    return true
  } catch {
    return false
  }
}

function readPng(filePath) {
  const buffer = fsSync.readFileSync(filePath)
  return PNG.sync.read(buffer)
}

async function compareImages(circularPath, linearPath, diffPath) {
  const circularPng = await readPng(circularPath)
  const linearPng = await readPng(linearPath)

  const width = Math.min(circularPng.width, linearPng.width)
  const height = Math.min(circularPng.height, linearPng.height)

  const a = new PNG({ width, height })
  const b = new PNG({ width, height })
  PNG.bitblt(circularPng, a, 0, 0, width, height, 0, 0)
  PNG.bitblt(linearPng, b, 0, 0, width, height, 0, 0)

  const diff = new PNG({ width, height })
  const diffPixels = pixelmatch(a.data, b.data, diff.data, width, height, {
    threshold: 0.1,
    includeAA: false,
  })

  await fs.writeFile(diffPath, PNG.sync.write(diff))

  const total = width * height
  return {
    diffPixels,
    totalPixels: total,
    diffPercent: Number(((diffPixels / total) * 100).toFixed(3)),
  }
}

async function disableMotion(page) {
  await page.addStyleTag({
    content: `
      *, *::before, *::after {
        animation: none !important;
        transition: none !important;
        caret-color: transparent !important;
      }
    `,
  }).catch(() => {})
}

async function captureStable(page, url, outPath) {
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 })
  await disableMotion(page)
  await page.waitForTimeout(2200)
  await page.screenshot({ path: outPath, fullPage: false })
}

async function main() {
  if (!(await exists(linearStorage))) {
    throw new Error(`Missing Linear storageState at ${linearStorage}`)
  }
  if (!(await exists(circularStorage))) {
    throw new Error(`Missing Circular storageState at ${circularStorage}`)
  }

  await fs.mkdir(outputDir, { recursive: true })

  const browser = await chromium.launch({ headless: true })
  const results = []

  for (const vp of viewports) {
    const linearContext = await browser.newContext({ storageState: linearStorage, viewport: { width: vp.width, height: vp.height } })
    const circularContext = await browser.newContext({ storageState: circularStorage, viewport: { width: vp.width, height: vp.height } })

    const linearPage = await linearContext.newPage()
    const circularPage = await circularContext.newPage()

    for (const pair of viewPairs) {
      const circularImg = path.join(outputDir, `${pair.key}__${vp.name}__circular.png`)
      const linearImg = path.join(outputDir, `${pair.key}__${vp.name}__linear.png`)
      const diffImg = path.join(outputDir, `${pair.key}__${vp.name}__diff.png`)

      let best = { diffPercent: Infinity, diffPixels: 0, totalPixels: 0 }
      let ok = true
      let error = null
      let circularFinalUrl = null
      let linearFinalUrl = null

      try {
        for (let attempt = 1; attempt <= 1; attempt++) {
          await captureStable(circularPage, `${circularBase}${pair.circular}`, circularImg)
          await captureStable(linearPage, `${linearBase}${pair.linear}`, linearImg)

          circularFinalUrl = circularPage.url()
          linearFinalUrl = linearPage.url()

          const cmp = await compareImages(circularImg, linearImg, diffImg)
          if (cmp.diffPercent < best.diffPercent) {
            best = cmp
          }
        }
      } catch (err) {
        ok = false
        error = String(err)
      }

      results.push({
        view: pair.key,
        viewport: vp.name,
        width: vp.width,
        height: vp.height,
        ok,
        error,
        circularUrl: circularFinalUrl,
        linearUrl: linearFinalUrl,
        diffPercent: ok ? best.diffPercent : null,
        targetMet: ok ? best.diffPercent < 2 : false,
        files: {
          circular: circularImg,
          linear: linearImg,
          diff: diffImg,
        },
      })
    }

    await linearContext.close()
    await circularContext.close()
  }

  await browser.close()

  const summary = {
    generatedAt: new Date().toISOString(),
    total: results.length,
    passed: results.filter(r => r.targetMet).length,
    failed: results.filter(r => r.ok && !r.targetMet).length,
    errored: results.filter(r => !r.ok).length,
    averageDiffPercent: Number((results.filter(r => r.ok).reduce((a, r) => a + r.diffPercent, 0) / Math.max(results.filter(r => r.ok).length, 1)).toFixed(3)),
    maxDiffPercent: results.filter(r => r.ok).reduce((m, r) => Math.max(m, r.diffPercent), 0),
  }

  await fs.writeFile(path.join(outputDir, 'results.json'), JSON.stringify({ summary, results }, null, 2))

  const lines = []
  lines.push(`# Visual Sweep Report`)
  lines.push(``)
  lines.push(`Generated: ${summary.generatedAt}`)
  lines.push(`Total comparisons: ${summary.total}`)
  lines.push(`Passed (<2%): ${summary.passed}`)
  lines.push(`Failed (>=2%): ${summary.failed}`)
  lines.push(`Errored: ${summary.errored}`)
  lines.push(`Average diff: ${summary.averageDiffPercent}%`)
  lines.push(`Max diff: ${summary.maxDiffPercent}%`)
  lines.push(``)
  lines.push(`| View | Viewport | Diff % | Target <2% | Circular URL | Linear URL |`)
  lines.push(`|---|---|---:|:---:|---|---|`)

  for (const r of results) {
    lines.push(`| ${r.view} | ${r.viewport} (${r.width}x${r.height}) | ${r.ok ? r.diffPercent.toFixed(3) : 'ERR'} | ${r.targetMet ? 'YES' : 'NO'} | ${r.circularUrl || '-'} | ${r.linearUrl || '-'} |`)
  }

  await fs.writeFile(path.join(outputDir, 'report.md'), lines.join('\n'))
  console.log(JSON.stringify({ outputDir, summary }, null, 2))
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
