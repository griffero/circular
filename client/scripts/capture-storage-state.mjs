import fs from 'node:fs/promises'
import path from 'node:path'
import readline from 'node:readline/promises'
import { stdin as input, stdout as output } from 'node:process'
import { chromium } from 'playwright'

const targets = {
  linear: {
    url: process.env.LINEAR_LOGIN_URL || 'https://linear.app',
    storageState: process.env.LINEAR_STORAGE_STATE || '/tmp/linear-storage-state.json',
  },
  circular: {
    url: process.env.CIRCULAR_LOGIN_URL || 'https://circular-client.onrender.com/login',
    storageState: process.env.CIRCULAR_STORAGE_STATE || '/tmp/circular-prod-storage-state.json',
  },
}

function parseArgs(argv) {
  const options = {
    target: 'linear',
    help: false,
  }

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index]
    if (arg === '--help' || arg === '-h') {
      options.help = true
    } else if (arg === '--target') {
      options.target = argv[index + 1] || options.target
      index += 1
    } else if (arg.startsWith('--target=')) {
      options.target = arg.slice('--target='.length)
    }
  }

  return options
}

function printHelp() {
  console.log([
    'Usage: node scripts/capture-storage-state.mjs --target linear|circular',
    '',
    'Opens a headed Playwright browser, lets you log in manually, and saves storageState.',
    '',
    `Default linear output: ${targets.linear.storageState}`,
    `Default circular output: ${targets.circular.storageState}`,
  ].join('\n'))
}

async function main() {
  const options = parseArgs(process.argv.slice(2))
  if (options.help) {
    printHelp()
    return
  }

  const target = targets[options.target]
  if (!target) {
    throw new Error(`Unknown target: ${options.target}`)
  }

  await fs.mkdir(path.dirname(target.storageState), { recursive: true })

  const browser = await chromium.launch({ channel: 'chrome', headless: false }).catch(() =>
    chromium.launch({ headless: false }),
  )
  const context = await browser.newContext({
    viewport: { width: 1440, height: 960 },
    colorScheme: 'light',
  })
  const page = await context.newPage()
  const rl = readline.createInterface({ input, output })

  try {
    await page.goto(target.url, { waitUntil: 'domcontentloaded', timeout: 45000 })
    console.log(`Opened ${target.url}`)
    console.log(`Complete login in the browser window, then press Enter to save ${target.storageState}`)
    await rl.question('')
    await context.storageState({ path: target.storageState })
    console.log(`Saved storage state to ${target.storageState}`)
  } finally {
    rl.close()
    await context.close()
    await browser.close()
  }
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
