import fs from 'node:fs/promises'
import fsSync from 'node:fs'
import path from 'node:path'
import readline from 'node:readline/promises'
import { stdin as input, stdout as output } from 'node:process'
import { fileURLToPath } from 'node:url'
import { chromium } from 'playwright'
import { PNG } from 'pngjs'
import pixelmatch from 'pixelmatch'

const scriptRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const parityRoot = path.join(scriptRoot, 'parity', 'color-audit')

const defaults = {
  circularBase: process.env.CIRCULAR_BASE || 'https://circular-client.onrender.com',
  linearBase: process.env.LINEAR_BASE || 'https://linear.app/fintoc',
  circularStorage: process.env.CIRCULAR_STORAGE_STATE || '/tmp/circular-prod-storage-state.json',
  linearStorage: process.env.LINEAR_STORAGE_STATE || '/tmp/linear-storage-state.json',
  mismatchTarget: Number.parseFloat(process.env.PARITY_TARGET_PERCENT || '1'),
  rawThreshold: Number.parseFloat(process.env.PARITY_RAW_THRESHOLD || '0.06'),
  macroGridColumns: Number.parseInt(process.env.PARITY_GRID_COLUMNS || '72', 10),
  macroGridRows: Number.parseInt(process.env.PARITY_GRID_ROWS || '44', 10),
  deltaTolerance: Number.parseFloat(process.env.PARITY_DELTA_TOLERANCE || '3.5'),
  settleMs: Number.parseInt(process.env.PARITY_SETTLE_MS || '1400', 10),
  outputDir: process.env.PARITY_OUTPUT_DIR || path.join(parityRoot, timestampSlug()),
  theme: process.env.PARITY_THEME || 'auto',
}

const viewCatalog = {
  'brd-issues': {
    label: 'Bridge issues',
    circularPath: '/team/BRD/issues',
    linearPath: '/team/BRD/all',
    linearReadyText: 'All issues',
  },
  'brd-triage': {
    label: 'Bridge triage',
    circularPath: '/team/BRD/triage',
    linearPath: '/team/BRD/triage',
    linearReadyText: 'Triage',
  },
  'brd-projects': {
    label: 'Bridge projects',
    circularPath: '/team/BRD/projects',
    linearPath: '/team/BRD/projects/all',
    linearReadyText: 'All projects',
  },
  'my-issues': {
    label: 'My issues',
    circularPath: '/my-issues?view=assigned',
    linearPath: '/my-issues/assigned',
    linearReadyText: 'Assigned to me',
  },
  projects: {
    label: 'Projects',
    circularPath: '/projects',
    linearPath: '/projects/all',
    linearReadyText: 'All projects',
  },
  views: {
    label: 'Views',
    circularPath: '/views',
    linearPath: '/views',
    linearReadyText: 'Views',
  },
}

const viewportCatalog = {
  desktop: { width: 1536, height: 960 },
  laptop: { width: 1366, height: 820 },
}

function timestampSlug() {
  return new Date().toISOString().replace(/[:.]/g, '-').replace('T', '_').replace('Z', '')
}

function parseArgs(argv) {
  const options = {
    views: (process.env.PARITY_VIEWS || 'brd-issues,my-issues,projects,views')
      .split(',')
      .map((value) => value.trim())
      .filter(Boolean),
    viewports: (process.env.PARITY_VIEWPORTS || 'desktop,laptop')
      .split(',')
      .map((value) => value.trim())
      .filter(Boolean),
    interactive: false,
    help: false,
  }

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index]
    if (arg === '--help' || arg === '-h') {
      options.help = true
    } else if (arg === '--interactive') {
      options.interactive = true
    } else if (arg === '--views') {
      options.views = (argv[index + 1] || '')
        .split(',')
        .map((value) => value.trim())
        .filter(Boolean)
      index += 1
    } else if (arg === '--viewports') {
      options.viewports = (argv[index + 1] || '')
        .split(',')
        .map((value) => value.trim())
        .filter(Boolean)
      index += 1
    } else if (arg.startsWith('--views=')) {
      options.views = arg
        .slice('--views='.length)
        .split(',')
        .map((value) => value.trim())
        .filter(Boolean)
    } else if (arg.startsWith('--viewports=')) {
      options.viewports = arg
        .slice('--viewports='.length)
        .split(',')
        .map((value) => value.trim())
        .filter(Boolean)
    }
  }

  return options
}

function printHelp() {
  const lines = [
    'Usage: node scripts/color-parity.mjs [options]',
    '',
    'Strong visual/color parity audit between Circular and Linear.',
    '',
    'Options:',
    '  --views brd-issues,my-issues   Comma-separated scenario keys',
    '  --viewports desktop,laptop     Comma-separated viewport keys',
    '  --interactive                  Pause before launch so you can verify config',
    '  --help                         Show this help',
    '',
    'Environment:',
    `  CIRCULAR_BASE                 Default: ${defaults.circularBase}`,
    `  LINEAR_BASE                   Default: ${defaults.linearBase}`,
    `  CIRCULAR_STORAGE_STATE        Default: ${defaults.circularStorage}`,
    `  LINEAR_STORAGE_STATE          Default: ${defaults.linearStorage}`,
    `  PARITY_TARGET_PERCENT         Default: ${defaults.mismatchTarget}`,
    `  PARITY_RAW_THRESHOLD          Default: ${defaults.rawThreshold}`,
    `  PARITY_GRID_COLUMNS           Default: ${defaults.macroGridColumns}`,
    `  PARITY_GRID_ROWS              Default: ${defaults.macroGridRows}`,
    `  PARITY_DELTA_TOLERANCE        Default: ${defaults.deltaTolerance}`,
    `  PARITY_THEME                  Default: ${defaults.theme}`,
    '',
    `Known views: ${Object.keys(viewCatalog).join(', ')}`,
    `Known viewports: ${Object.keys(viewportCatalog).join(', ')}`,
  ]
  console.log(lines.join('\n'))
}

function ensureKnownValues(selectedValues, catalog, label) {
  const unknown = selectedValues.filter((value) => !catalog[value])
  if (unknown.length > 0) {
    throw new Error(`Unknown ${label}: ${unknown.join(', ')}`)
  }
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

function readPng(filePath) {
  return PNG.sync.read(fsSync.readFileSync(filePath))
}

function rgbaToHex(red, green, blue, alpha = 255) {
  const normalize = (value) => value.toString(16).padStart(2, '0')
  return `#${normalize(red)}${normalize(green)}${normalize(blue)}${alpha < 255 ? normalize(alpha) : ''}`
}

function rgbToLab(red, green, blue) {
  let r = red / 255
  let g = green / 255
  let b = blue / 255

  const normalizeRgb = (value) => (value > 0.04045 ? ((value + 0.055) / 1.055) ** 2.4 : value / 12.92)
  r = normalizeRgb(r)
  g = normalizeRgb(g)
  b = normalizeRgb(b)

  let x = (r * 0.4124 + g * 0.3576 + b * 0.1805) / 0.95047
  let y = (r * 0.2126 + g * 0.7152 + b * 0.0722) / 1.0
  let z = (r * 0.0193 + g * 0.1192 + b * 0.9505) / 1.08883

  const normalizeXyz = (value) => (value > 0.008856 ? value ** (1 / 3) : (7.787 * value) + (16 / 116))
  x = normalizeXyz(x)
  y = normalizeXyz(y)
  z = normalizeXyz(z)

  return {
    l: (116 * y) - 16,
    a: 500 * (x - y),
    b: 200 * (y - z),
  }
}

function deltaE(left, right) {
  return Math.sqrt(
    ((left.l - right.l) ** 2)
      + ((left.a - right.a) ** 2)
      + ((left.b - right.b) ** 2),
  )
}

function percentile(values, ratio) {
  if (!values.length) return null
  const sorted = [...values].sort((left, right) => left - right)
  const index = Math.max(Math.ceil(sorted.length * ratio) - 1, 0)
  return Number(sorted[index].toFixed(3))
}

function cropToSharedSize(leftImage, rightImage) {
  const width = Math.min(leftImage.width, rightImage.width)
  const height = Math.min(leftImage.height, rightImage.height)
  const left = new PNG({ width, height })
  const right = new PNG({ width, height })
  PNG.bitblt(leftImage, left, 0, 0, width, height, 0, 0)
  PNG.bitblt(rightImage, right, 0, 0, width, height, 0, 0)
  return { width, height, left, right }
}

async function compareRawPixels(actualPath, baselinePath, diffPath) {
  const actual = readPng(actualPath)
  const baseline = readPng(baselinePath)
  const { width, height, left, right } = cropToSharedSize(actual, baseline)
  const diff = new PNG({ width, height })
  const diffPixels = pixelmatch(left.data, right.data, diff.data, width, height, {
    threshold: defaults.rawThreshold,
    includeAA: false,
  })

  await fs.writeFile(diffPath, PNG.sync.write(diff))

  return {
    width,
    height,
    diffPixels,
    totalPixels: width * height,
    diffPercent: Number(((diffPixels / (width * height)) * 100).toFixed(3)),
  }
}

function buildMacroGrid(image, columns, rows) {
  const cells = []
  const cellWidth = image.width / columns
  const cellHeight = image.height / rows

  for (let row = 0; row < rows; row += 1) {
    for (let column = 0; column < columns; column += 1) {
      const startX = Math.floor(column * cellWidth)
      const endX = Math.max(startX + 1, Math.floor((column + 1) * cellWidth))
      const startY = Math.floor(row * cellHeight)
      const endY = Math.max(startY + 1, Math.floor((row + 1) * cellHeight))

      let red = 0
      let green = 0
      let blue = 0
      let alpha = 0
      let pixels = 0

      for (let y = startY; y < endY; y += 1) {
        for (let x = startX; x < endX; x += 1) {
          const index = ((y * image.width) + x) * 4
          red += image.data[index]
          green += image.data[index + 1]
          blue += image.data[index + 2]
          alpha += image.data[index + 3]
          pixels += 1
        }
      }

      cells.push({
        row,
        column,
        red: Math.round(red / pixels),
        green: Math.round(green / pixels),
        blue: Math.round(blue / pixels),
        alpha: Math.round(alpha / pixels),
      })
    }
  }

  return { columns, rows, cells }
}

async function compareMacroColors(actualPath, baselinePath, heatmapPath) {
  const actual = readPng(actualPath)
  const baseline = readPng(baselinePath)
  const { left, right } = cropToSharedSize(actual, baseline)
  const leftGrid = buildMacroGrid(left, defaults.macroGridColumns, defaults.macroGridRows)
  const rightGrid = buildMacroGrid(right, defaults.macroGridColumns, defaults.macroGridRows)
  const heatmap = new PNG({ width: leftGrid.columns, height: leftGrid.rows })

  let mismatchCells = 0
  let totalDelta = 0
  let maxDelta = 0
  const deltas = []

  for (let index = 0; index < leftGrid.cells.length; index += 1) {
    const current = leftGrid.cells[index]
    const reference = rightGrid.cells[index]
    const currentLab = rgbToLab(current.red, current.green, current.blue)
    const referenceLab = rgbToLab(reference.red, reference.green, reference.blue)
    const delta = deltaE(currentLab, referenceLab)
    deltas.push(delta)
    totalDelta += delta
    maxDelta = Math.max(maxDelta, delta)
    if (delta > defaults.deltaTolerance) mismatchCells += 1

    const normalized = Math.max(0, Math.min(255, Math.round((delta / 25) * 255)))
    const heatmapIndex = index * 4
    heatmap.data[heatmapIndex] = normalized
    heatmap.data[heatmapIndex + 1] = Math.max(0, 255 - normalized)
    heatmap.data[heatmapIndex + 2] = 48
    heatmap.data[heatmapIndex + 3] = 255
  }

  await fs.writeFile(heatmapPath, PNG.sync.write(heatmap))

  return {
    gridColumns: leftGrid.columns,
    gridRows: leftGrid.rows,
    totalCells: leftGrid.cells.length,
    mismatchCells,
    mismatchPercent: Number(((mismatchCells / leftGrid.cells.length) * 100).toFixed(3)),
    meanDeltaE: Number((totalDelta / leftGrid.cells.length).toFixed(3)),
    p95DeltaE: percentile(deltas, 0.95),
    maxDeltaE: Number(maxDelta.toFixed(3)),
  }
}

function buildColorHistogram(image, binsPerChannel = 8) {
  const histogram = new Map()
  const binSize = 256 / binsPerChannel
  let visiblePixels = 0

  for (let index = 0; index < image.data.length; index += 4) {
    const alpha = image.data[index + 3]
    if (alpha === 0) continue
    const redBin = Math.min(binsPerChannel - 1, Math.floor(image.data[index] / binSize))
    const greenBin = Math.min(binsPerChannel - 1, Math.floor(image.data[index + 1] / binSize))
    const blueBin = Math.min(binsPerChannel - 1, Math.floor(image.data[index + 2] / binSize))
    const key = `${redBin}-${greenBin}-${blueBin}`
    histogram.set(key, (histogram.get(key) || 0) + 1)
    visiblePixels += 1
  }

  return { histogram, visiblePixels }
}

function compareHistogram(actualPath, baselinePath) {
  const actual = readPng(actualPath)
  const baseline = readPng(baselinePath)
  const { left, right } = cropToSharedSize(actual, baseline)
  const leftHistogram = buildColorHistogram(left)
  const rightHistogram = buildColorHistogram(right)
  const keys = new Set([...leftHistogram.histogram.keys(), ...rightHistogram.histogram.keys()])

  let intersection = 0

  for (const key of keys) {
    const leftWeight = (leftHistogram.histogram.get(key) || 0) / leftHistogram.visiblePixels
    const rightWeight = (rightHistogram.histogram.get(key) || 0) / rightHistogram.visiblePixels
    intersection += Math.min(leftWeight, rightWeight)
  }

  return {
    similarityPercent: Number((intersection * 100).toFixed(3)),
    distancePercent: Number(((1 - intersection) * 100).toFixed(3)),
  }
}

function buildPalette(image, limit = 12) {
  const bucket = new Map()

  for (let index = 0; index < image.data.length; index += 4) {
    const alpha = image.data[index + 3]
    if (alpha < 32) continue
    const red = Math.round(image.data[index] / 16) * 16
    const green = Math.round(image.data[index + 1] / 16) * 16
    const blue = Math.round(image.data[index + 2] / 16) * 16
    const key = rgbaToHex(red, green, blue)
    bucket.set(key, (bucket.get(key) || 0) + 1)
  }

  const total = [...bucket.values()].reduce((sum, value) => sum + value, 0)
  return [...bucket.entries()]
    .sort((left, right) => right[1] - left[1])
    .slice(0, limit)
    .map(([hex, count]) => ({
      hex,
      sharePercent: Number(((count / total) * 100).toFixed(3)),
    }))
}

function summarizePalette(actualPath, baselinePath) {
  const actual = readPng(actualPath)
  const baseline = readPng(baselinePath)
  return {
    circularTop: buildPalette(actual),
    linearTop: buildPalette(baseline),
  }
}

async function disableMotion(page) {
  await page.addStyleTag({
    content: `
      *, *::before, *::after {
        animation: none !important;
        transition: none !important;
        caret-color: transparent !important;
        scroll-behavior: auto !important;
      }
      ::-webkit-scrollbar {
        display: none !important;
      }
    `,
  }).catch(() => {})
}

async function waitForCircularSettled(page) {
  await page.waitForSelector('[data-testid="app-shell-ready"]', { timeout: 45000 })
  await page.waitForLoadState('networkidle', { timeout: 12000 }).catch(() => {})

  for (let attempt = 0; attempt < 8; attempt += 1) {
    const activeSpinners = await page.evaluate(() => document.querySelectorAll('.animate-spin').length)
    if (activeSpinners === 0) break
    await page.waitForTimeout(250)
  }

  await page.waitForTimeout(defaults.settleMs)
}

async function waitForLinearSettled(page, readyText) {
  await page.waitForLoadState('networkidle', { timeout: 12000 }).catch(() => {})
  if (readyText) {
    await page.waitForFunction((text) => document.body?.innerText?.includes(text), readyText, { timeout: 25000 })
  }
  await page.waitForTimeout(defaults.settleMs)
}

async function collectDomColors(page) {
  return page.evaluate(() => {
    const normalize = (value) => {
      if (!value || value === 'rgba(0, 0, 0, 0)' || value === 'transparent') return null
      return value.trim()
    }

    const entries = new Map()
    const visibleElements = [...document.querySelectorAll('*')].slice(0, 3000)

    for (const element of visibleElements) {
      const rect = element.getBoundingClientRect()
      if (rect.width < 1 || rect.height < 1) continue
      const style = window.getComputedStyle(element)
      const colors = [
        normalize(style.color),
        normalize(style.backgroundColor),
        normalize(style.borderTopColor),
        normalize(style.borderRightColor),
        normalize(style.borderBottomColor),
        normalize(style.borderLeftColor),
        normalize(style.fill),
        normalize(style.stroke),
      ].filter(Boolean)

      for (const color of colors) {
        entries.set(color, (entries.get(color) || 0) + 1)
      }
    }

    return [...entries.entries()]
      .sort((left, right) => right[1] - left[1])
      .slice(0, 16)
      .map(([value, count]) => ({ value, count }))
  })
}

async function capturePage(page, targetUrl, outPath, options = {}) {
  await page.goto(targetUrl, { waitUntil: 'domcontentloaded', timeout: 45000 })
  await disableMotion(page)

  if (options.circular) {
    await waitForCircularSettled(page)
  } else {
    await waitForLinearSettled(page, options.linearReadyText)
  }

  await page.screenshot({ path: outPath, fullPage: false })
  return {
    finalUrl: page.url(),
    domColors: await collectDomColors(page).catch(() => []),
  }
}

async function launchBrowser() {
  try {
    return await chromium.launch({ channel: 'chrome', headless: true })
  } catch {
    return chromium.launch({ headless: true })
  }
}

async function createContext(browser, storageStatePath, viewport) {
  return browser.newContext({
    storageState: storageStatePath,
    viewport,
    deviceScaleFactor: 1,
    colorScheme: 'light',
  })
}

async function detectLinearDarkMode(browser, viewport) {
  if (defaults.theme === 'dark') return true
  if (defaults.theme === 'light') return false

  const context = await createContext(browser, defaults.linearStorage, viewport)
  const page = await context.newPage()

  try {
    await page.goto(`${defaults.linearBase}/team/BRD/all`, {
      waitUntil: 'domcontentloaded',
      timeout: 45000,
    })
    await waitForLinearSettled(page, 'All issues')

    return page.evaluate(() => {
      const background = getComputedStyle(document.documentElement).backgroundColor
      const darkClass = document.documentElement.classList.contains('dark')
      if (darkClass) return true
      return background === 'rgb(0, 0, 0)' || background === 'rgb(15, 17, 21)'
    })
  } finally {
    await context.close()
  }
}

async function maybePause(options) {
  if (!options.interactive) return
  const rl = readline.createInterface({ input, output })
  try {
    await rl.question('Press Enter to start the parity audit...')
  } finally {
    rl.close()
  }
}

function evaluatePass(metrics) {
  return metrics.macro.mismatchPercent <= defaults.mismatchTarget
    && metrics.histogram.distancePercent <= defaults.mismatchTarget
}

function buildMarkdownReport(summary, results) {
  const lines = []
  lines.push('# Color Parity Audit')
  lines.push('')
  lines.push(`Generated: ${summary.generatedAt}`)
  lines.push(`Circular base: ${summary.circularBase}`)
  lines.push(`Linear base: ${summary.linearBase}`)
  lines.push(`Target: macro mismatch <= ${defaults.mismatchTarget}% and histogram distance <= ${defaults.mismatchTarget}%`)
  lines.push('')
  lines.push(`Total comparisons: ${summary.total}`)
  lines.push(`Passed: ${summary.passed}`)
  lines.push(`Failed: ${summary.failed}`)
  lines.push(`Errored: ${summary.errored}`)
  lines.push(`Average macro mismatch: ${summary.averageMacroMismatchPercent}%`)
  lines.push(`Average histogram distance: ${summary.averageHistogramDistancePercent}%`)
  lines.push(`Worst macro mismatch: ${summary.worstMacroMismatchPercent}%`)
  lines.push('')
  lines.push('| View | Viewport | Raw diff % | Macro mismatch % | Mean DeltaE | Histogram distance % | Pass | |')
  lines.push('|---|---|---:|---:|---:|---:|:---:|---|')

  for (const result of results) {
    if (result.error) {
      lines.push(`| ${result.view} | ${result.viewport} | ERR | ERR | ERR | ERR | NO | ${result.error.replace(/\|/g, '\\|')} |`)
      continue
    }

    lines.push(
      `| ${result.view} | ${result.viewport} | ${result.raw.diffPercent.toFixed(3)} | ${result.macro.mismatchPercent.toFixed(3)} | ${result.macro.meanDeltaE.toFixed(3)} | ${result.histogram.distancePercent.toFixed(3)} | ${result.pass ? 'YES' : 'NO'} | ${result.circularFinalUrl} |`,
    )
  }

  return lines.join('\n')
}

async function main() {
  const options = parseArgs(process.argv.slice(2))
  if (options.help) {
    printHelp()
    return
  }

  ensureKnownValues(options.views, viewCatalog, 'views')
  ensureKnownValues(options.viewports, viewportCatalog, 'viewports')

  const requiredFiles = [defaults.circularStorage, defaults.linearStorage]
  for (const filePath of requiredFiles) {
    if (!(await exists(filePath))) {
      throw new Error(
        `Missing storage state: ${filePath}. Capture it first with node scripts/capture-storage-state.mjs --target ${filePath.includes('linear') ? 'linear' : 'circular'}`,
      )
    }
  }

  await maybePause(options)
  await ensureDir(defaults.outputDir)

  const browser = await launchBrowser()
  const results = []
  const linearDarkMode = await detectLinearDarkMode(browser, viewportCatalog[options.viewports[0]])

  try {
    for (const viewportName of options.viewports) {
      const viewport = viewportCatalog[viewportName]
      const linearContext = await createContext(browser, defaults.linearStorage, viewport)
      const circularContext = await createContext(browser, defaults.circularStorage, viewport)

      await circularContext.addInitScript((isDarkMode) => {
        localStorage.setItem('darkMode', isDarkMode ? 'true' : 'false')
        localStorage.setItem('themeVersion', '2')
        if (isDarkMode) {
          document.documentElement.classList.add('dark')
        } else {
          document.documentElement.classList.remove('dark')
        }
      }, linearDarkMode)

      const linearPage = await linearContext.newPage()
      const circularPage = await circularContext.newPage()

      for (const viewName of options.views) {
        const scenario = viewCatalog[viewName]
        const screenshotRoot = path.join(defaults.outputDir, `${viewName}__${viewportName}`)
        const circularPng = `${screenshotRoot}__circular.png`
        const linearPng = `${screenshotRoot}__linear.png`
        const rawDiffPng = `${screenshotRoot}__raw-diff.png`
        const macroDiffPng = `${screenshotRoot}__macro-heatmap.png`
        const paletteJson = `${screenshotRoot}__palette.json`

        try {
          const circularCapture = await capturePage(
            circularPage,
            `${defaults.circularBase}${scenario.circularPath}`,
            circularPng,
            { circular: true },
          )

          const linearCapture = await capturePage(
            linearPage,
            `${defaults.linearBase}${scenario.linearPath}`,
            linearPng,
            { linearReadyText: scenario.linearReadyText },
          )

          const raw = await compareRawPixels(circularPng, linearPng, rawDiffPng)
          const macro = await compareMacroColors(circularPng, linearPng, macroDiffPng)
          const histogram = compareHistogram(circularPng, linearPng)
          const palette = summarizePalette(circularPng, linearPng)
          await fs.writeFile(
            paletteJson,
            JSON.stringify(
              {
                circularDomColors: circularCapture.domColors,
                linearDomColors: linearCapture.domColors,
                screenshotPalette: palette,
              },
              null,
              2,
            ),
          )

          results.push({
            view: viewName,
            label: scenario.label,
            viewport: viewportName,
            width: viewport.width,
            height: viewport.height,
            circularFinalUrl: circularCapture.finalUrl,
            linearFinalUrl: linearCapture.finalUrl,
            raw,
            macro,
            histogram,
            pass: evaluatePass({ raw, macro, histogram }),
            paletteFile: paletteJson,
            files: {
              circular: circularPng,
              linear: linearPng,
              rawDiff: rawDiffPng,
              macroHeatmap: macroDiffPng,
            },
            error: null,
          })
        } catch (error) {
          results.push({
            view: viewName,
            label: scenario.label,
            viewport: viewportName,
            width: viewport.width,
            height: viewport.height,
            error: String(error),
            pass: false,
          })
        }
      }

      await linearContext.close()
      await circularContext.close()
    }
  } finally {
    await browser.close()
  }

  const successful = results.filter((result) => !result.error)
  const summary = {
    generatedAt: new Date().toISOString(),
    circularBase: defaults.circularBase,
    linearBase: defaults.linearBase,
    total: results.length,
    passed: results.filter((result) => result.pass).length,
    failed: results.filter((result) => !result.pass && !result.error).length,
    errored: results.filter((result) => result.error).length,
    averageMacroMismatchPercent: Number(
      (
        successful.reduce((sum, result) => sum + result.macro.mismatchPercent, 0)
        / Math.max(successful.length, 1)
      ).toFixed(3),
    ),
    averageHistogramDistancePercent: Number(
      (
        successful.reduce((sum, result) => sum + result.histogram.distancePercent, 0)
        / Math.max(successful.length, 1)
      ).toFixed(3),
    ),
    worstMacroMismatchPercent: Number(
      successful.reduce((max, result) => Math.max(max, result.macro.mismatchPercent), 0).toFixed(3),
    ),
  }

  await fs.writeFile(
    path.join(defaults.outputDir, 'results.json'),
    JSON.stringify({ summary, results }, null, 2),
  )
  await fs.writeFile(path.join(defaults.outputDir, 'report.md'), buildMarkdownReport(summary, results))

  console.log(JSON.stringify({ outputDir: defaults.outputDir, summary }, null, 2))
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
