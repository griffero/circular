/**
 * Node 26 exposes an experimental `localStorage` global that only works when the
 * process is started with `--localstorage-file`. Because the name already exists
 * on the Node global, vitest's jsdom environment skips copying jsdom's own
 * working implementation over it, and every store that reads localStorage during
 * setup throws. Install a plain in-memory Storage so tests see the browser
 * behaviour the app is written against.
 */
class MemoryStorage implements Storage {
  #data = new Map<string, string>()

  get length(): number {
    return this.#data.size
  }

  key(index: number): string | null {
    return [...this.#data.keys()][index] ?? null
  }

  getItem(key: string): string | null {
    return this.#data.get(String(key)) ?? null
  }

  setItem(key: string, value: string): void {
    this.#data.set(String(key), String(value))
  }

  removeItem(key: string): void {
    this.#data.delete(String(key))
  }

  clear(): void {
    this.#data.clear()
  }
}

function ensureStorage(name: 'localStorage' | 'sessionStorage') {
  // Read the descriptor rather than the value: touching Node's experimental
  // getter is what emits the --localstorage-file warning.
  const descriptor = Object.getOwnPropertyDescriptor(globalThis, name)
  const isJsdomStorage = descriptor?.value instanceof Object && 'getItem' in descriptor.value
  if (isJsdomStorage) return

  const storage = new MemoryStorage()
  Object.defineProperty(globalThis, name, { value: storage, writable: true, configurable: true })
  if (typeof window !== 'undefined') {
    Object.defineProperty(window, name, { value: storage, writable: true, configurable: true })
  }
}

ensureStorage('localStorage')
ensureStorage('sessionStorage')

// Each test file gets a clean slate.
beforeEach(() => {
  localStorage.clear()
  sessionStorage.clear()
})
