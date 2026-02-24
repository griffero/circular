<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useIssuesStore } from '@/stores/issues'
import Button from '@/components/ui/Button.vue'
import { Clock, Plus } from 'lucide-vue-next'

const route = useRoute()
const appStore = useAppStore()
const issuesStore = useIssuesStore()

const teams = computed(() => appStore.teams)
const currentTeam = computed(() => {
  const teamKey = route.params.teamKey as string
  return teams.value.find(t => t.key === teamKey)
})

const loading = ref(false)
const now = computed(() => new Date())
const mode = computed<'current' | 'upcoming'>(() => {
  return route.name === 'team-cycles-upcoming' ? 'upcoming' : 'current'
})

const filteredCycles = computed(() => {
  const n = now.value
  return issuesStore.cycles.filter((cycle) => {
    if (mode.value === 'current') {
      if (cycle.active) return true
      if (!cycle.startsAt || !cycle.endsAt) return false
      const start = new Date(cycle.startsAt)
      const end = new Date(cycle.endsAt)
      return start <= n && n <= end
    }

    if (!cycle.startsAt) return false
    const start = new Date(cycle.startsAt)
    return start > n
  })
})

watch(
  () => currentTeam.value?.id,
  async (teamId) => {
    if (!teamId) return
    loading.value = true
    try {
      await issuesStore.fetchCycles(teamId)
    } finally {
      loading.value = false
    }
  },
  { immediate: true }
)
</script>

<template>
  <div class="p-4 h-full bg-[var(--linear-bg)]">
    <div v-if="loading" class="flex items-center justify-center py-16">
      <div class="animate-spin rounded-full h-8 w-8 border-2 border-[var(--linear-accent)] border-t-transparent"></div>
    </div>

    <div v-else-if="filteredCycles.length === 0" class="flex flex-col items-center justify-center py-16">
      <div class="w-16 h-16 rounded-full bg-[var(--linear-elevated)] border border-[var(--linear-border)] flex items-center justify-center mb-4">
        <Clock class="h-8 w-8 text-[var(--linear-muted)]" />
      </div>
      <h3 class="text-lg font-medium text-[var(--linear-text)] mb-1">
        No {{ mode }} cycles
      </h3>
      <p class="text-sm text-[var(--linear-muted)] text-center max-w-sm mb-4">
        Cycles help organize team work in time-boxed windows.
      </p>
      <Button>
        <Plus class="h-4 w-4" />
        Create cycle
      </Button>
    </div>

    <div v-else class="space-y-2">
      <div v-for="cycle in filteredCycles" :key="cycle.id" class="linear-panel p-3">
        <div class="flex items-center justify-between">
          <p class="text-sm font-medium text-[var(--linear-text)]">{{ cycle.displayName || cycle.name || `Cycle ${cycle.number}` }}</p>
          <p class="text-xs text-[var(--linear-muted)]">{{ Math.round(cycle.progress || 0) }}%</p>
        </div>
        <p v-if="cycle.startsAt && cycle.endsAt" class="text-xs text-[var(--linear-muted)] mt-1">
          {{ new Date(cycle.startsAt).toLocaleDateString() }} - {{ new Date(cycle.endsAt).toLocaleDateString() }}
        </p>
      </div>
    </div>
  </div>
</template>
