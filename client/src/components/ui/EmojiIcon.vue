<script setup lang="ts">
import { computed } from 'vue'
import { useEmojiStore } from '@/stores/emoji'
import { cn } from '@/utils/cn'

interface Props {
  // The emoji name (can be ":emoji:" or "emoji" format)
  name?: string | null
  // Fallback text to show if emoji is not found (usually first letter)
  fallback?: string
  // Size of the emoji
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl'
  // Additional classes
  class?: string
}

const props = withDefaults(defineProps<Props>(), {
  size: 'md',
  fallback: '?'
})

const emojiStore = useEmojiStore()

const sizes = {
  xs: 'w-4 h-4 text-[10px]',
  sm: 'w-5 h-5 text-[10px]',
  md: 'w-6 h-6 text-xs',
  lg: 'w-8 h-8 text-sm',
  xl: 'w-10 h-10 text-base'
}

// Get the emoji URL from the store
const emojiUrl = computed(() => {
  return emojiStore.getEmojiUrl(props.name)
})

// Check if we have a valid custom emoji
const isCustomEmoji = computed(() => {
  return !!emojiUrl.value
})

// Check if the name looks like a standard unicode emoji
const isUnicodeEmoji = computed(() => {
  if (!props.name) return false
  // Simple check: if it's a single character or emoji sequence
  // Unicode emojis are typically 1-2 characters (or more with modifiers)
  const stripped = props.name.replace(/^:|:$/g, '')
  // Check if it contains only emoji characters (not alphanumeric)
  return /^[\p{Emoji}\u200d]+$/u.test(stripped) && stripped.length <= 8
})

// Computed class for the container
const containerClass = computed(() => 
  cn(
    'inline-flex items-center justify-center rounded overflow-hidden flex-shrink-0',
    sizes[props.size],
    props.class
  )
)

// Display value for fallback
const displayFallback = computed(() => {
  return props.fallback?.charAt(0)?.toUpperCase() || '?'
})
</script>

<template>
  <span :class="containerClass">
    <!-- Custom Slack emoji (image) -->
    <img 
      v-if="isCustomEmoji" 
      :src="emojiUrl!" 
      :alt="name || ''"
      class="w-full h-full object-contain"
      loading="lazy"
    />
    <!-- Unicode emoji -->
    <span v-else-if="isUnicodeEmoji" class="leading-none">
      {{ name?.replace(/^:|:$/g, '') }}
    </span>
    <!-- Fallback (first letter) -->
    <span 
      v-else 
      class="font-bold text-white leading-none"
    >
      {{ displayFallback }}
    </span>
  </span>
</template>
