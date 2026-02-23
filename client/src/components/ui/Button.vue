<script setup lang="ts">
import { computed } from 'vue'
import { cn } from '@/utils/cn'
import { Loader2 } from 'lucide-vue-next'

interface Props {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger' | 'link'
  size?: 'xs' | 'sm' | 'md' | 'lg'
  loading?: boolean
  disabled?: boolean
  type?: 'button' | 'submit' | 'reset'
  class?: string | Record<string, boolean>
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'primary',
  size: 'md',
  loading: false,
  disabled: false,
  type: 'button'
})

const buttonClass = computed(() => {
  const base = 'inline-flex items-center justify-center font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 rounded-md'
  
  const variants = {
    primary: 'linear-button-primary focus-visible:ring-[var(--linear-accent)]',
    secondary: 'bg-[var(--linear-elevated)] text-[var(--linear-text)] border border-[var(--linear-border)] hover:bg-[var(--linear-surface)] focus-visible:ring-[var(--linear-accent)]',
    ghost: 'text-[var(--linear-muted)] hover:bg-[var(--linear-elevated)] hover:text-[var(--linear-text)] focus-visible:ring-[var(--linear-accent)]',
    danger: 'bg-red-600 text-white hover:bg-red-700 focus-visible:ring-red-500',
    link: 'text-[var(--linear-accent)] hover:underline'
  }
  
  const sizes = {
    xs: 'h-6 px-2 text-xs gap-1',
    sm: 'h-8 px-3 text-sm gap-1.5',
    md: 'h-9 px-4 text-sm gap-2',
    lg: 'h-10 px-6 text-base gap-2'
  }
  
  return cn(base, variants[props.variant], sizes[props.size], props.class)
})
</script>

<template>
  <button
    :type="type"
    :class="buttonClass"
    :disabled="disabled || loading"
  >
    <Loader2 v-if="loading" class="h-4 w-4 animate-spin" />
    <slot />
  </button>
</template>
