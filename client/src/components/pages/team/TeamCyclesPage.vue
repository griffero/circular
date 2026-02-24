<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useIssuesStore } from '@/stores/issues'
import { useCurrentTeam } from '@/composables/useCurrentTeam'
import Avatar from '@/components/ui/Avatar.vue'
import {
  Circle,
  Clock3,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  Plus,
  Filter,
  SlidersHorizontal,
  CircleEllipsis,
} from 'lucide-vue-next'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
import { useEmojiStore } from '@/stores/emoji'
import type { Cycle, Issue } from '@/types'

const route = useRoute()
const issuesStore = useIssuesStore()
const { currentTeam } = useCurrentTeam()
const emojiStore = useEmojiStore()

const loading = ref(false)
const selectedCycle = ref<Cycle | null>(null)
const cycleIssues = ref<Issue[]>([])

const mode = computed<'current' | 'upcoming'>(() => {
  return route.name === 'team-cycles-upcoming' ? 'upcoming' : 'current'
})

const now = computed(() => new Date())

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
    return new Date(cycle.startsAt) > n
  })
})

const fallbackSectionsOrder = ['in_review', 'in_progress', 'todo', 'backlog', 'done', 'canceled'] as const
const fallbackSectionLabel = {
  in_review: 'In Review',
  in_progress: 'In Progress',
  todo: 'Todo',
  backlog: 'Backlog',
  done: 'Done',
  canceled: 'Canceled',
} as const

const groupedSections = computed(() => {
  const map = new Map(
    fallbackSectionsOrder.map((status) => [
      status,
      {
        key: status,
        label: fallbackSectionLabel[status],
        color: undefined,
        icon: status === 'in_progress' ? Clock3 : status === 'done' ? CheckCircle2 : status === 'canceled' ? XCircle : Circle,
        issues: [] as Issue[],
      },
    ])
  )

  for (const issue of cycleIssues.value) {
    const stateType = issue.workflowState?.stateType
    const stateName = String(issue.workflowState?.name || '').toLowerCase()
    const status =
      stateType === 'completed'
        ? 'done'
        : stateType === 'canceled'
          ? 'canceled'
          : stateType === 'triage' || stateType === 'backlog'
            ? 'backlog'
            : stateName.includes('review') || stateName.includes('staging')
              ? 'in_review'
              : stateName.includes('todo') || stateName.includes('unstarted') || stateName.includes('backlog')
                ? 'todo'
                : stateType === 'started'
                  ? 'in_progress'
                  : (issue.status || 'backlog')
    if (map.has(status)) {
      map.get(status)!.issues.push(issue)
    }
  }

  return Array.from(map.values()).filter((s) => s.issues.length > 0)
})

const assigneeStats = computed(() => {
  const byAssignee = new Map<string, { key: string; name: string; done: number; total: number }>()
  for (const issue of cycleIssues.value) {
    const name = issue.assignee?.name || issue.assignee?.displayName || issue.assignee?.email || 'No assignee'
    const key = issue.assignee?.id || '__none__'
    if (!byAssignee.has(key)) byAssignee.set(key, { key, name, done: 0, total: 0 })
    const row = byAssignee.get(key)!
    row.total += 1
    const stateType = issue.workflowState?.stateType
    const doneByWorkflow = stateType === 'completed' || stateType === 'canceled'
    const doneByStatus = issue.status === 'done' || issue.status === 'canceled'
    if (doneByWorkflow || doneByStatus) row.done += 1
  }
  return Array.from(byAssignee.values()).sort((a, b) => b.total - a.total)
})

const cycleName = computed(() => selectedCycle.value?.displayName || selectedCycle.value?.name || `Cycle ${selectedCycle.value?.number || ''}`)

watch(
  () => [currentTeam.value?.id, mode.value],
  async ([teamId]) => {
    if (!teamId) {
      selectedCycle.value = null
      cycleIssues.value = []
      return
    }

    loading.value = true
    try {
      await Promise.all([
        issuesStore.fetchCycles(teamId),
        issuesStore.fetchWorkflowStates(teamId),
      ])

      selectedCycle.value = filteredCycles.value[0] || null
      if (!selectedCycle.value) {
        cycleIssues.value = []
        return
      }

      await issuesStore.fetchIssues({ teamId, cycleId: selectedCycle.value.id, perPage: 500, sort: 'updated_at', direction: 'desc' })
      cycleIssues.value = issuesStore.issues
    } finally {
      loading.value = false
    }
  },
  { immediate: true }
)

function formatShortDate(dateString?: string | null) {
  if (!dateString) return '-'
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}

function hasEmoji(icon?: string | null): boolean {
  return emojiStore.isRenderableEmoji(icon)
}
</script>

<template>
  <div class="h-full bg-[var(--linear-bg)] flex flex-col">
    <div v-if="loading" class="flex-1 flex items-center justify-center">
      <div class="animate-spin rounded-full h-8 w-8 border-2 border-[var(--linear-accent)] border-t-transparent"></div>
    </div>

    <div v-else-if="!selectedCycle" class="flex-1 flex items-center justify-center text-[var(--linear-muted)] text-sm">
      No {{ mode }} cycles
    </div>

    <div v-else class="flex-1 flex overflow-hidden relative">
      <div class="absolute top-0 left-0 right-0 h-8 px-4 border-b border-[var(--linear-border-subtle)] flex items-center justify-between bg-[var(--linear-bg)] z-10">
        <div class="flex items-center gap-2 min-w-0 text-[13px]">
          <div class="w-4 h-4 rounded flex items-center justify-center flex-shrink-0" :style="hasEmoji(currentTeam?.icon) ? {} : { backgroundColor: currentTeam?.color || '#6b7280' }">
            <EmojiIcon :name="currentTeam?.icon" :fallback="currentTeam?.key?.substring(0, 1) || ''" size="xs" />
          </div>
          <span class="font-medium text-[var(--linear-text)] truncate">{{ currentTeam?.name }}</span>
          <span class="text-[var(--linear-muted)]">›</span>
          <span class="text-[var(--linear-text)] truncate">{{ cycleName }}</span>
        </div>
        <div class="flex items-center gap-3 text-[12px] text-[var(--linear-muted)]">
          <button class="inline-flex items-center gap-1 hover:text-[var(--linear-text)]">
            <Filter class="w-3.5 h-3.5" />
            Filter
          </button>
          <button class="inline-flex items-center gap-1 hover:text-[var(--linear-text)]">
            <SlidersHorizontal class="w-3.5 h-3.5" />
            Display
          </button>
          <CircleEllipsis class="w-4 h-4" />
        </div>
      </div>

      <div class="flex-1 flex flex-col min-w-0 border-r border-[var(--linear-border-subtle)]">
        <div class="mt-8 px-3 py-2 border-b border-[var(--linear-border-subtle)] bg-[var(--linear-elevated)] flex items-start justify-between">
          <div>
            <p class="text-[13px] font-semibold text-[var(--linear-text)]">{{ cycleName }}</p>
            <p class="text-[12px] text-[var(--linear-muted)]">{{ formatShortDate(selectedCycle.startsAt) }} - {{ formatShortDate(selectedCycle.endsAt) }}</p>
          </div>
          <span class="text-[12px] text-[var(--linear-muted)]">{{ Math.round(selectedCycle.progress || 0) }}%</span>
        </div>

        <div class="flex-1 overflow-auto">
          <div v-for="section in groupedSections" :key="section.key">
            <div class="h-8 px-3 border-b border-[var(--linear-border-subtle)] bg-[var(--linear-elevated)] flex items-center gap-2 text-[12px] text-[var(--linear-text)] font-medium">
              <component :is="section.icon" class="w-3.5 h-3.5" :style="section.color ? { color: section.color } : undefined" />
              <span>{{ section.label }}</span>
              <span class="text-[var(--linear-muted)]">{{ section.issues.length }}</span>
              <button class="ml-auto text-[var(--linear-muted)] hover:text-[var(--linear-text)]">
                <Plus class="w-3.5 h-3.5" />
              </button>
            </div>

            <div
              v-for="issue in section.issues"
              :key="issue.id"
              class="h-9 px-3 border-b border-[var(--linear-border-subtle)] grid grid-cols-[84px_1fr_auto_74px_20px] items-center gap-2 text-[13px]"
            >
              <span class="text-[var(--linear-muted)] font-mono text-[12px] truncate">{{ issue.identifier }}</span>
              <span class="text-[var(--linear-text)] truncate">{{ issue.title }}</span>
              <div class="flex items-center gap-1 min-w-0">
                <span
                  v-for="label in issue.labels?.slice(0, 2)"
                  :key="label.id"
                  class="px-1.5 py-0.5 rounded-full border border-[var(--linear-border)] text-[11px] text-[var(--linear-muted)] truncate max-w-[140px]"
                >
                  {{ label.name }}
                </span>
              </div>
              <span class="text-[12px] text-[var(--linear-muted)] text-right">{{ formatShortDate(issue.updatedAt) }}</span>
              <Avatar
                v-if="issue.assignee"
                :name="issue.assignee.name || issue.assignee.displayName || issue.assignee.email"
                size="xs"
              />
              <div v-else class="w-5 h-5 rounded-full border border-dashed border-[var(--linear-border)]" />
            </div>
          </div>
        </div>
      </div>

      <aside class="w-[350px] flex-shrink-0 bg-[var(--linear-bg)]">
        <div class="h-8 px-3 border-b border-[var(--linear-border-subtle)] flex items-center gap-1.5 text-[12px]">
          <span class="px-2 py-0.5 rounded bg-[var(--linear-elevated)] text-[var(--linear-text)]">Current</span>
          <span class="text-[var(--linear-muted)]">{{ formatShortDate(selectedCycle.startsAt) }} - {{ formatShortDate(selectedCycle.endsAt) }}</span>
        </div>

        <div class="p-4 border-b border-[var(--linear-border-subtle)]">
          <p class="text-[13px] font-semibold text-[var(--linear-text)] mb-2">{{ selectedCycle.displayName || selectedCycle.name || `Cycle ${selectedCycle.number}` }}</p>
          <p class="text-[12px] text-[var(--linear-muted)]">Add document or link...</p>
        </div>

        <div class="p-4 border-b border-[var(--linear-border-subtle)]">
          <div class="flex items-center justify-between text-[12px] mb-2">
            <span class="text-[var(--linear-text)] font-medium">Progress</span>
            <AlertTriangle class="w-3.5 h-3.5 text-[var(--linear-muted)]" />
          </div>
          <div class="h-24 rounded border border-[var(--linear-border)] bg-[var(--linear-elevated)] flex items-center justify-center text-[11px] text-[var(--linear-muted)]">
            Scope / Started / Completed
          </div>
        </div>

        <div class="p-4">
          <div class="text-[12px] text-[var(--linear-muted)] mb-2">Assignees</div>
          <div class="space-y-2.5 max-h-[320px] overflow-auto">
            <div v-for="row in assigneeStats" :key="row.key" class="grid grid-cols-[1fr_auto] gap-3 items-center">
              <span class="text-[12px] text-[var(--linear-text)] truncate">{{ row.name }}</span>
              <span class="text-[12px] text-[var(--linear-muted)]">{{ row.total === 0 ? 0 : Math.round((row.done / row.total) * 100) }}%</span>
            </div>
          </div>
        </div>
      </aside>
    </div>
  </div>
</template>
