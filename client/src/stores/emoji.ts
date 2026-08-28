import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { api } from '@/api/client'
import emojiDictionary from 'emoji-dictionary'

export const useEmojiStore = defineStore('emoji', () => {
  // Map of emoji name to URL
  const emojis = ref<Record<string, string>>({})
  const loading = ref(false)
  const error = ref<string | null>(null)
  const initialized = ref(false)

  // Check if emojis are loaded
  const hasEmojis = computed(() => Object.keys(emojis.value).length > 0)

  // Fetch all emojis from the API
  async function fetchEmojis() {
    if (loading.value) return // Prevent duplicate calls

    try {
      loading.value = true
      error.value = null
      const data = await api.get<{ emojis: Record<string, string> }>('/api/v1/emojis')
      emojis.value = data.emojis
      initialized.value = true
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch emojis'
      console.error('Failed to fetch emojis:', err)
    } finally {
      loading.value = false
    }
  }

  const SYSTEM_ICON_ALIASES: Record<string, string> = {
    shield: '🛡️',
    codeblock: '💻',
    mobilephone: '📱',
    pointer: '🖱️',
    lock: '🔒',
    robot_face: '🤖',
    robotface: '🤖',
    gcp: '☁️',
    vibe_coding: '🤖',
    'vibe-coding': '🤖',
    spongebob_fire: '🔥',
    'spongebob-fire': '🔥',
    pepe_monster: '👾',
    'pepe-monster': '👾',
    tank: '🪖',
  }

  function normalizeEmojiKey(value: string): string {
    return value.trim().replace(/^:|:$/g, '')
  }

  function normalizeForUnicodeLookup(value: string): string[] {
    const base = normalizeEmojiKey(value)
    const lower = base.toLowerCase()
    const snake = lower.replace(/[\s-]+/g, '_')
    const compact = lower.replace(/[\s_-]+/g, '')
    return Array.from(new Set([base, lower, snake, compact]))
  }

  // Get the URL for a specific emoji by name
  // Accepts formats: "emoji-name" or ":emoji-name:"
  function getEmojiUrl(name: string | null | undefined): string | null {
    if (!name) return null

    const candidates = normalizeForUnicodeLookup(name)
    for (const candidate of candidates) {
      const url = emojis.value[candidate]
      if (url) return url
    }
    return null
  }

  // Check if a given string is a custom Slack emoji
  function isCustomEmoji(name: string | null | undefined): boolean {
    if (!name) return false
    return !!getEmojiUrl(name)
  }

  // Resolve a value to a unicode emoji if possible.
  // Supports native unicode input and shortcodes like ":rocket:" / "rocket".
  const EMOJI_CODE_POINT = /[\p{Extended_Pictographic}\p{Emoji}]/u
  const EMOJI_JOINERS = new Set(['\u200d', '\ufe0f'])

  /**
   * True when every code point is emoji-ish. Deliberately per-code-point: a ZWJ
   * sequence like \u{1f9d1}\u200d\u{1f4bb} is several code points and each one
   * has to pass.
   */
  function isAllEmojiCodePoints(value: string): boolean {
    if (!value) return false
    return [...value].every((cp) => EMOJI_JOINERS.has(cp) || EMOJI_CODE_POINT.test(cp))
  }

  function getUnicodeEmoji(value: string | null | undefined): string | null {
    if (!value) return null

    const cleanValue = normalizeEmojiKey(value)
    if (!cleanValue) return null

    if (isAllEmojiCodePoints(cleanValue) && cleanValue.length <= 10) {
      return cleanValue
    }

    const candidates = normalizeForUnicodeLookup(cleanValue)
    for (const candidate of candidates) {
      if (SYSTEM_ICON_ALIASES[candidate]) {
        return SYSTEM_ICON_ALIASES[candidate]
      }
      const unicode = emojiDictionary.getUnicode(candidate)
      if (unicode) return unicode
    }

    return null
  }

  function isRenderableEmoji(value: string | null | undefined): boolean {
    return !!getEmojiUrl(value) || !!getUnicodeEmoji(value)
  }

  // Check if a string looks like an emoji name (has colons or is a known emoji)
  function isEmojiFormat(value: string | null | undefined): boolean {
    if (!value) return false
    // Check if it's in :emoji: format or is a known emoji
    return value.startsWith(':') && value.endsWith(':') || isCustomEmoji(value)
  }

  function reset() {
    emojis.value = {}
    error.value = null
    initialized.value = false
  }

  return {
    // State
    emojis,
    loading,
    error,
    initialized,

    // Computed
    hasEmojis,

    // Actions
    fetchEmojis,
    getEmojiUrl,
    getUnicodeEmoji,
    isRenderableEmoji,
    isCustomEmoji,
    isEmojiFormat,
    reset,
  }
})
