<script setup lang="ts">
import { computed } from 'vue'
import { useEmojiStore } from '@/stores/emoji'

const props = defineProps<{
  text: string
}>()

const emojiStore = useEmojiStore()

interface TextPart {
  type: 'text' | 'emoji'
  content: string
  url?: string
}

// Parse text and split into parts (text and emojis)
// Uses ONLY the emojis synced from Slack/Linear via the emoji store
const parsedParts = computed((): TextPart[] => {
  const parts: TextPart[] = []
  const emojiRegex = /:([a-zA-Z0-9_+-]+):/g
  
  let lastIndex = 0
  let match: RegExpExecArray | null
  
  while ((match = emojiRegex.exec(props.text)) !== null) {
    // Add text before the emoji
    if (match.index > lastIndex) {
      parts.push({
        type: 'text',
        content: props.text.slice(lastIndex, match.index)
      })
    }
    
    // Check if this is a known emoji from the synced Slack/Linear emojis
    const emojiName = match[1]
    const emojiUrl = emojiStore.getEmojiUrl(emojiName)
    
    if (emojiUrl) {
      // It's a synced emoji - show as image
      parts.push({
        type: 'emoji',
        content: emojiName,
        url: emojiUrl
      })
    } else {
      // Fall back to standard unicode emoji if this is a known shortcode.
      const unicode = emojiStore.getUnicodeEmoji(emojiName)
      parts.push({
        type: 'text',
        content: unicode || match[0]
      })
    }
    
    lastIndex = match.index + match[0].length
  }
  
  // Add remaining text
  if (lastIndex < props.text.length) {
    parts.push({
      type: 'text',
      content: props.text.slice(lastIndex)
    })
  }
  
  return parts
})
</script>

<template>
  <span class="emoji-text">
    <template v-for="(part, index) in parsedParts" :key="index">
      <span v-if="part.type === 'text'" class="whitespace-pre-wrap">{{ part.content }}</span>
      <img 
        v-else
        :src="part.url" 
        :alt="`:${part.content}:`"
        :title="`:${part.content}:`"
        class="inline-block h-[1.2em] w-[1.2em] align-text-bottom mx-0.5"
      />
    </template>
  </span>
</template>

<style scoped>
.emoji-text {
  word-break: break-word;
}
</style>
