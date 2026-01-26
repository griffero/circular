import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { api } from '@/api/client'

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

  // Get the URL for a specific emoji by name
  // Accepts formats: "emoji-name" or ":emoji-name:"
  function getEmojiUrl(name: string | null | undefined): string | null {
    if (!name) return null

    // Strip colons if present
    const cleanName = name.replace(/^:|:$/g, '')

    return emojis.value[cleanName] || null
  }

  // Check if a given string is a custom Slack emoji
  function isCustomEmoji(name: string | null | undefined): boolean {
    if (!name) return false
    const cleanName = name.replace(/^:|:$/g, '')
    return cleanName in emojis.value
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
    isCustomEmoji,
    isEmojiFormat,
    reset,
  }
})
