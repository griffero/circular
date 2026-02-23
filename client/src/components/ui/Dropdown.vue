<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { cn } from '@/utils/cn'

interface Props {
  align?: 'left' | 'right' | 'left-side'
  width?: string
  class?: string
}

const props = withDefaults(defineProps<Props>(), {
  align: 'left',
  width: 'w-48'
})

const open = ref(false)
const dropdownRef = ref<HTMLElement | null>(null)
const triggerRef = ref<HTMLElement | null>(null)
const menuStyle = ref<Record<string, string>>({})

const menuClass = computed(() => {
  if (props.align === 'left-side') {
    return cn(
      'fixed z-[9999] rounded-lg shadow-xl',
      'bg-[var(--linear-elevated)] border border-[var(--linear-border)]',
      'py-1',
      props.width,
      props.class
    )
  }
  
  const positionClass = props.align === 'right' ? 'right-0 mt-1' : 'left-0 mt-1'
  
  return cn(
    'absolute z-50 rounded-lg shadow-xl',
    'bg-[var(--linear-elevated)] border border-[var(--linear-border)]',
    'py-1',
    props.width,
    positionClass,
    props.class
  )
})

function updateMenuPosition() {
  if (props.align === 'left-side' && triggerRef.value) {
    const rect = triggerRef.value.getBoundingClientRect()
    // Position to the left of the trigger
    menuStyle.value = {
      top: `${rect.top}px`,
      right: `${window.innerWidth - rect.left + 8}px`
    }
  }
}

function handleClickOutside(event: MouseEvent) {
  if (dropdownRef.value && !dropdownRef.value.contains(event.target as Node)) {
    open.value = false
  }
}

async function toggle() {
  open.value = !open.value
  if (open.value && props.align === 'left-side') {
    await nextTick()
    updateMenuPosition()
  }
}

function close() {
  open.value = false
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})

defineExpose({ open, toggle, close })
</script>

<template>
  <div ref="dropdownRef" class="relative inline-block">
    <div ref="triggerRef" @click="toggle">
      <slot name="trigger" />
    </div>

    <Transition
      enter-active-class="transition duration-100 ease-out"
      enter-from-class="transform scale-95 opacity-0"
      enter-to-class="transform scale-100 opacity-100"
      leave-active-class="transition duration-75 ease-in"
      leave-from-class="transform scale-100 opacity-100"
      leave-to-class="transform scale-95 opacity-0"
    >
      <div v-if="open" :class="menuClass" :style="props.align === 'left-side' ? menuStyle : {}">
        <slot :close="close" />
      </div>
    </Transition>
  </div>
</template>
