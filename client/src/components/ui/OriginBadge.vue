<script setup lang="ts">
import { computed } from 'vue'
import { Lock } from 'lucide-vue-next'
import { isFromLinear } from '@/composables/useOrigin'

const props = defineProps<{
  linearId?: string
}>()

const fromLinear = computed(() => isFromLinear({ linearId: props.linearId }))
</script>

<template>
  <!-- Circular-native: cyan dot -->
  <span
    v-if="!fromLinear"
    class="inline-flex items-center justify-center w-4 h-4 rounded-full flex-shrink-0"
    style="background: var(--circular-badge-bg)"
    title="Circular — editable"
  >
    <span class="text-[9px] font-bold" style="color: var(--circular-badge-text)">C</span>
  </span>

  <!-- Linear: lock icon, visible on hover of parent -->
  <span
    v-else
    class="inline-flex items-center justify-center w-4 h-4 flex-shrink-0 opacity-0 group-hover:opacity-40 transition-opacity"
    title="Synced from Linear — read-only"
  >
    <Lock class="h-3 w-3 text-[var(--linear-muted)]" />
  </span>
</template>
