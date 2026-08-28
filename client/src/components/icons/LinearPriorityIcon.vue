<script setup lang="ts">
/**
 * Priority icon, using Linear's own artwork.
 *
 * Paths lifted verbatim from the running app: three bars on a 16x16 grid at
 * x=1.5/6.5/11.5, dimmed to 0.4 opacity as the level drops; "no priority" is
 * the same three slots collapsed to 1.5px dashes; "urgent" is a filled square
 * with a punched-out exclamation mark.
 */
import { computed } from 'vue'
import type { IssuePriority } from '@/types'

const props = withDefaults(defineProps<{ priority: IssuePriority; size?: number }>(), { size: 16 })

const isUrgent = computed(() => props.priority === 1)
const isNone = computed(() => props.priority === 0)
/** High keeps all three bars lit, medium dims the tallest, low dims two. */
const midOpacity = computed(() => (props.priority >= 4 ? 0.4 : 1))
const topOpacity = computed(() => (props.priority >= 3 ? 0.4 : 1))
</script>

<template>
  <svg :width="size" :height="size" viewBox="0 0 16 16" fill="currentColor" aria-hidden="true" focusable="false">
    <template v-if="isUrgent">
      <path
        style="color: #f2994a"
        fill="#f2994a"
        d="M3 1C1.91067 1 1 1.91067 1 3V13C1 14.0893 1.91067 15 3 15H13C14.0893 15 15 14.0893 15 13V3C15 1.91067 14.0893 1 13 1H3ZM7 4L9 4L8.75391 8.99836H7.25L7 4ZM9 11C9 11.5523 8.55228 12 8 12C7.44772 12 7 11.5523 7 11C7 10.4477 7.44772 10 8 10C8.55228 10 9 10.4477 9 11Z"
      />
    </template>
    <template v-else-if="isNone">
      <rect x="1.5" y="7.25" width="3" height="1.5" rx="0.5" opacity="0.9" />
      <rect x="6.5" y="7.25" width="3" height="1.5" rx="0.5" opacity="0.9" />
      <rect x="11.5" y="7.25" width="3" height="1.5" rx="0.5" opacity="0.9" />
    </template>
    <template v-else>
      <rect x="1.5" y="8" width="3" height="6" rx="1" />
      <rect x="6.5" y="5" width="3" height="9" rx="1" :fill-opacity="midOpacity" />
      <rect x="11.5" y="2" width="3" height="12" rx="1" :fill-opacity="topOpacity" />
    </template>
  </svg>
</template>
