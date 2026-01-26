<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { cn } from '@/utils/cn'

interface Props {
  align?: 'left' | 'right'
  width?: string
  class?: string
}

const props = withDefaults(defineProps<Props>(), {
  align: 'left',
  width: 'w-48'
})

const open = ref(false)
const dropdownRef = ref<HTMLElement | null>(null)

const menuClass = computed(() =>
  cn(
    'absolute z-50 mt-1 rounded-lg shadow-xl',
    'bg-[#1a1a1a] border border-[#2a2a2a]',
    'py-1',
    props.width,
    props.align === 'right' ? 'right-0' : 'left-0',
    props.class
  )
)

function handleClickOutside(event: MouseEvent) {
  if (dropdownRef.value && !dropdownRef.value.contains(event.target as Node)) {
    open.value = false
  }
}

function toggle() {
  open.value = !open.value
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
    <div @click="toggle">
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
      <div v-if="open" :class="menuClass">
        <slot :close="close" />
      </div>
    </Transition>
  </div>
</template>
