<script setup lang="ts">
import { computed } from 'vue'
import { cn } from '@/utils/cn'

interface Props {
  modelValue?: string | number
  type?: string
  placeholder?: string
  disabled?: boolean
  error?: boolean
  class?: string
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: '',
  type: 'text',
  disabled: false,
  error: false
})

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void
}>()

const inputClass = computed(() => {
  return cn(
    'w-full px-3 py-2 text-sm rounded-md border transition-colors',
    'bg-[var(--linear-elevated)]',
    'text-[var(--linear-text)]',
    'placeholder:text-[var(--linear-muted)]',
    'focus:outline-none focus:ring-2 focus:ring-offset-0',
    props.error
      ? 'border-red-500 focus:ring-red-500/50'
      : 'border-[var(--linear-border)] focus:border-[var(--linear-accent)] focus:ring-[var(--linear-accent)]/50',
    'disabled:opacity-50 disabled:cursor-not-allowed',
    props.class
  )
})

function handleInput(event: Event) {
  const target = event.target as HTMLInputElement
  emit('update:modelValue', target.value)
}
</script>

<template>
  <input
    :type="type"
    :value="modelValue"
    :placeholder="placeholder"
    :disabled="disabled"
    :class="inputClass"
    @input="handleInput"
  />
</template>
