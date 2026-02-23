<script setup lang="ts">
import { computed, watch, onMounted, onUnmounted } from 'vue'
import { cn } from '@/utils/cn'
import { X } from 'lucide-vue-next'

interface Props {
  open: boolean
  title?: string
  description?: string
  size?: 'sm' | 'md' | 'lg' | 'xl' | 'full'
  closable?: boolean
  class?: string
}

const props = withDefaults(defineProps<Props>(), {
  size: 'md',
  closable: true
})

const emit = defineEmits<{
  (e: 'close'): void
}>()

const sizeClasses = {
  sm: 'max-w-sm',
  md: 'max-w-md',
  lg: 'max-w-lg',
  xl: 'max-w-xl',
  full: 'max-w-4xl'
}

const panelClass = computed(() => 
  cn(
    'relative w-full rounded-lg shadow-xl',
    'bg-[var(--linear-elevated)]',
    'border border-[var(--linear-border)]',
    sizeClasses[props.size],
    props.class
  )
)

function handleEscape(event: KeyboardEvent) {
  if (event.key === 'Escape' && props.closable) {
    emit('close')
  }
}

watch(() => props.open, (open) => {
  if (open) {
    document.body.style.overflow = 'hidden'
    document.addEventListener('keydown', handleEscape)
  } else {
    document.body.style.overflow = ''
    document.removeEventListener('keydown', handleEscape)
  }
})

onMounted(() => {
  if (props.open) {
    document.body.style.overflow = 'hidden'
    document.addEventListener('keydown', handleEscape)
  }
})

onUnmounted(() => {
  document.body.style.overflow = ''
  document.removeEventListener('keydown', handleEscape)
})
</script>

<template>
  <Teleport to="body">
    <Transition
      enter-active-class="duration-200 ease-out"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="duration-150 ease-in"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="open"
        class="fixed inset-0 z-50 flex items-center justify-center p-4"
      >
        <!-- Backdrop -->
        <div
          class="absolute inset-0 bg-black/70"
          @click="closable && emit('close')"
        />

        <!-- Panel -->
        <Transition
          enter-active-class="duration-200 ease-out"
          enter-from-class="opacity-0 scale-95"
          enter-to-class="opacity-100 scale-100"
          leave-active-class="duration-150 ease-in"
          leave-from-class="opacity-100 scale-100"
          leave-to-class="opacity-0 scale-95"
        >
          <div v-if="open" :class="panelClass">
            <!-- Header -->
            <div v-if="title || closable" class="flex items-center justify-between px-6 py-4 border-b border-[var(--linear-border)]">
              <div>
                <h2 v-if="title" class="text-lg font-semibold text-[var(--linear-text)]">
                  {{ title }}
                </h2>
                <p v-if="description" class="mt-1 text-sm text-[var(--linear-muted)]">
                  {{ description }}
                </p>
              </div>
              <button
                v-if="closable"
                @click="emit('close')"
                class="p-1 rounded-md text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-surface)] transition-colors"
              >
                <X class="h-5 w-5" />
              </button>
            </div>

            <!-- Content -->
            <div class="px-6 py-4">
              <slot />
            </div>

            <!-- Footer -->
            <div v-if="$slots.footer" class="px-6 py-4 border-t border-[var(--linear-border)] flex justify-end gap-3">
              <slot name="footer" />
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>
