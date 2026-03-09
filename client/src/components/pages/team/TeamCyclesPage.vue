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
  Play,
  Star,
  MoreHorizontal,
  ChevronDown,
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

function findCurrentCycle(cycles: Cycle[]): Cycle | null {
  const n = now.value
  return (
    cycles.find((cycle) => cycle.active) ||
    cycles.find((cycle) => {
      if (!cycle.startsAt || !cycle.endsAt) return false
      const start = new Date(cycle.startsAt)
      const end = new Date(cycle.endsAt)
      return start <= n && n <= end
    }) ||
    null
  )
}

const filteredCycles = computed(() => {
  const n = now.value
  const activeCycle = findCurrentCycle(issuesStore.cycles)
  const activeNumber = activeCycle?.number || 0

  return issuesStore.cycles.filter((cycle) => {
    if (mode.value === 'current') {
      if (cycle.active) return true
      if (!cycle.startsAt || !cycle.endsAt) return false
      const start = new Date(cycle.startsAt)
      const end = new Date(cycle.endsAt)
      return start <= n && n <= end
    }

    if (cycle.startsAt) {
      return new Date(cycle.startsAt) > n
    }

    // Fallback for datasets with missing dates:
    // treat higher-number non-active cycles as upcoming.
    return !cycle.active && cycle.number > activeNumber
  }).sort((a, b) => {
    if (a.startsAt && b.startsAt) return new Date(a.startsAt).getTime() - new Date(b.startsAt).getTime()
    if (a.startsAt && !b.startsAt) return -1
    if (!a.startsAt && b.startsAt) return 1
    return a.number - b.number
  })
})

const syntheticUpcomingCycle = computed<Cycle | null>(() => {
  const current = findCurrentCycle(issuesStore.cycles)
  if (!current?.endsAt) return null
  const start = new Date(current.endsAt)
  if (Number.isNaN(start.getTime())) return null

  const durationMs =
    current.startsAt && current.endsAt
      ? Math.max(
          24 * 60 * 60 * 1000,
          new Date(current.endsAt).getTime() - new Date(current.startsAt).getTime()
        )
      : 14 * 24 * 60 * 60 * 1000

  // Linear displays upcoming cycle ranges as inclusive bounds (e.g. Mar 2 - Mar 15)
  // for a 14-day cadence, so subtract one day from the exclusive end timestamp.
  const end = new Date(start.getTime() + durationMs - 24 * 60 * 60 * 1000)
  const number = (current.number || 0) + 1
  const teamId = currentTeam.value?.id || current.teamId

  return {
    id: `synthetic-upcoming-${teamId}-${number}`,
    teamId,
    number,
    name: null,
    displayName: `Cycle ${number}`,
    startsAt: start.toISOString(),
    endsAt: end.toISOString(),
    progress: 0,
    active: false,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  }
})

const isSyntheticSelectedCycle = computed(() => selectedCycle.value?.id?.startsWith('synthetic-upcoming-') || false)

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

const cycleProgressSummary = computed(() => {
  const scope = cycleIssues.value.length
  let started = 0
  let completed = 0

  for (const issue of cycleIssues.value) {
    const stateType = issue.workflowState?.stateType
    const stateName = String(issue.workflowState?.name || '').toLowerCase()
    const isDone = stateType === 'completed' || issue.status === 'done'
    const isStarted =
      stateType === 'started' ||
      stateName.includes('in progress') ||
      stateName.includes('review') ||
      stateName.includes('staging')
    if (isDone) completed += 1
    if (isStarted) started += 1
  }

  return { scope, started, completed }
})

const progressChartPoints = computed(() => {
  const start = selectedCycle.value?.startsAt ? new Date(selectedCycle.value.startsAt) : null
  const end = selectedCycle.value?.endsAt ? new Date(selectedCycle.value.endsAt) : null
  if (!start || !end || Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) return []

  const totalDays = Math.max(1, Math.ceil((end.getTime() - start.getTime()) / (24 * 60 * 60 * 1000)))
  const points = []
  for (let i = 0; i <= totalDays; i += 1) {
    const date = new Date(start.getTime() + i * 24 * 60 * 60 * 1000)
    const issuesUntilDate = cycleIssues.value.filter((issue) => {
      if (!issue.updatedAt) return false
      return new Date(issue.updatedAt).getTime() <= date.getTime()
    })
    const completed = issuesUntilDate.filter(
      (issue) => issue.workflowState?.stateType === 'completed' || issue.status === 'done'
    ).length
    const started = issuesUntilDate.filter((issue) => {
      const stateType = issue.workflowState?.stateType
      const stateName = String(issue.workflowState?.name || '').toLowerCase()
      return (
        stateType === 'started' ||
        stateName.includes('in progress') ||
        stateName.includes('review') ||
        stateName.includes('staging')
      )
    }).length
    points.push({ completed, started })
  }
  return points
})

const progressChartPath = computed(() => {
  const points = progressChartPoints.value
  if (points.length < 2) return { completed: '', started: '', bars: [] as { x: number; y: number; h: number }[] }

  const width = 290
  const height = 104
  const max = Math.max(
    cycleProgressSummary.value.scope || 1,
    ...points.map((p) => Math.max(p.completed, p.started, 1))
  )
  const stepX = width / (points.length - 1)

  const mapY = (v: number) => height - (v / max) * (height - 10)
  const completedPath = points
    .map((p, i) => `${i === 0 ? 'M' : 'L'} ${Math.round(i * stepX)} ${Math.round(mapY(p.completed))}`)
    .join(' ')
  const startedPath = points
    .map((p, i) => `${i === 0 ? 'M' : 'L'} ${Math.round(i * stepX)} ${Math.round(mapY(p.started))}`)
    .join(' ')

  const bars = points
    .filter((_, i) => i % Math.max(1, Math.floor(points.length / 10)) === 0)
    .map((p, i) => {
      const x = Math.round((i * width) / Math.max(1, 9))
      const y = Math.round(mapY(p.completed))
      return { x, y, h: Math.max(5, height - y) }
    })

  return { completed: completedPath, started: startedPath, bars }
})

const cycleName = computed(() => selectedCycle.value?.displayName || selectedCycle.value?.name || `Cycle ${selectedCycle.value?.number || ''}`)
const showUpcomingHero = computed(() => mode.value === 'upcoming' && !!selectedCycle.value && groupedSections.value.length === 0)
const cycleDateRangeArrow = computed(() => `${formatShortDate(selectedCycle.value?.startsAt)} → ${formatShortDate(selectedCycle.value?.endsAt)}`)
const daysToStart = computed(() => {
  const startsAt = selectedCycle.value?.startsAt
  if (!startsAt) return 0
  const diff = new Date(startsAt).getTime() - now.value.getTime()
  return Math.max(0, Math.ceil(diff / (24 * 60 * 60 * 1000)))
})

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

      const filtered = filteredCycles.value
      selectedCycle.value = filtered[0] || null
      if (!selectedCycle.value && mode.value === 'upcoming') {
        selectedCycle.value = syntheticUpcomingCycle.value
      }
      if (!selectedCycle.value) {
        cycleIssues.value = []
        return
      }

      if (isSyntheticSelectedCycle.value) {
        cycleIssues.value = []
      } else {
        await issuesStore.fetchIssues({ teamId, cycleId: selectedCycle.value.id, perPage: 500 })
        cycleIssues.value = issuesStore.issues
      }
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
  <div class="h-full bg-[var(--linear-bg)] flex flex-col relative">
    <div v-if="!selectedCycle" class="flex-1 flex overflow-hidden relative">
      <div class="absolute top-0 left-0 right-0 h-8 px-4 border-b border-[var(--linear-border-subtle)] flex items-center justify-between bg-[var(--linear-bg)] z-10">
        <div class="flex items-center gap-2 min-w-0 text-[13px]">
          <div class="w-4 h-4 rounded flex items-center justify-center flex-shrink-0" :style="hasEmoji(currentTeam?.icon) ? {} : { backgroundColor: currentTeam?.color || '#6b7280' }">
            <EmojiIcon :name="currentTeam?.icon" :fallback="currentTeam?.key?.substring(0, 1) || ''" size="xs" />
          </div>
          <span class="font-medium text-[var(--linear-text)] truncate">{{ currentTeam?.name }}</span>
          <span class="text-[var(--linear-muted)]">›</span>
          <span class="text-[var(--linear-text)] truncate">Cycle</span>
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

      <div class="flex-1 mt-8 border-r border-[var(--linear-border-subtle)] flex items-center justify-center">
        <div class="max-w-[360px]">
          <div class="w-16 h-16 rounded-full border border-[var(--linear-border)] flex items-center justify-center mx-auto mb-4 text-[var(--linear-muted)]">
            <Clock3 class="w-8 h-8" />
          </div>
          <p class="text-[28px] font-semibold text-[var(--linear-text)] mb-2">Cycle</p>
          <p class="text-[14px] leading-6 text-[var(--linear-muted)] mb-2">
            Cycles are time-based intervals to help your team
          </p>
          <p class="text-[14px] leading-6 text-[var(--linear-muted)] mb-4">
            track capacity, scope, and progress.
          </p>
          <div class="flex items-center gap-2">
            <button class="h-8 px-4 rounded bg-indigo-600 hover:bg-indigo-700 text-white text-[13px]">Create new issue</button>
            <button class="h-8 px-4 rounded border border-[var(--linear-border)] text-[13px] text-[var(--linear-text)]">Documentation</button>
          </div>
        </div>
      </div>

      <aside class="w-[350px] flex-shrink-0 bg-[var(--linear-bg)]">
        <div class="h-8 px-3 border-b border-[var(--linear-border-subtle)] flex items-center gap-1.5 text-[12px]">
          <span class="px-2 py-0.5 rounded bg-[var(--linear-elevated)] text-[var(--linear-text)]">Upcoming</span>
        </div>
        <div class="p-4 border-b border-[var(--linear-border-subtle)]">
          <p class="text-[13px] font-semibold text-[var(--linear-text)] mb-2">Cycle</p>
          <p class="text-[12px] text-[var(--linear-muted)]">Add document or link...</p>
        </div>
      </aside>
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
          <button class="text-[var(--linear-muted)] hover:text-[var(--linear-text)]">
            <Star class="w-3.5 h-3.5" />
          </button>
          <button class="text-[var(--linear-muted)] hover:text-[var(--linear-text)]">
            <MoreHorizontal class="w-3.5 h-3.5" />
          </button>
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

        <div v-if="showUpcomingHero" class="flex-1 flex items-center justify-center">
          <div class="max-w-[360px]">
            <div class="w-20 h-20 rounded-full border border-[var(--linear-border)]/70 flex items-center justify-center mx-auto mb-4 text-[var(--linear-muted)] relative">
              <div class="absolute inset-1 rounded-full border border-dotted border-[var(--linear-border)]" />
              <Play class="w-8 h-8 relative z-10" />
            </div>
            <p class="text-[28px] font-semibold text-[var(--linear-text)] mb-2">{{ cycleName }}</p>
            <p class="text-[14px] leading-6 text-[var(--linear-muted)] mb-2">
              Cycles are time-based intervals to help your team
              focus on a predefined set of work.
            </p>
            <p class="text-[14px] leading-6 text-[var(--linear-muted)] mb-4">
              Track capacity, scope, and progress as issues are
              added, and as the cycle progresses.
            </p>
            <div class="flex items-center gap-2">
              <button class="h-8 px-4 rounded bg-indigo-600 hover:bg-indigo-700 text-white text-[13px] inline-flex items-center gap-1.5">
                Create new issue
                <span class="px-1 rounded bg-indigo-500/70 text-[10px]">C</span>
              </button>
              <button class="h-8 px-4 rounded border border-[var(--linear-border)] text-[13px] text-[var(--linear-text)]">Documentation</button>
            </div>
          </div>
        </div>
        <div v-else class="flex-1 overflow-auto">
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
          <span class="px-2 py-0.5 rounded bg-[var(--linear-elevated)] text-[var(--linear-text)]">
            {{ mode === 'upcoming' ? 'Upcoming' : 'Current' }}
          </span>
          <span class="text-[var(--linear-muted)]">{{ cycleDateRangeArrow }}</span>
        </div>

        <div class="p-4 border-b border-[var(--linear-border-subtle)]">
          <div class="flex items-center justify-between mb-2">
            <p class="text-[13px] font-semibold text-[var(--linear-text)]">{{ selectedCycle.displayName || selectedCycle.name || `Cycle ${selectedCycle.number}` }}</p>
            <div class="flex items-center gap-1.5">
              <button class="text-[var(--linear-muted)] hover:text-[var(--linear-text)]">
                <Star class="w-3.5 h-3.5" />
              </button>
              <button class="text-[var(--linear-muted)] hover:text-[var(--linear-text)]">
                <MoreHorizontal class="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
          <p class="text-[12px] text-[var(--linear-muted)]">Add document or link...</p>
        </div>

        <div v-if="mode !== 'upcoming'" class="p-4 border-b border-[var(--linear-border-subtle)]">
          <div class="flex items-center justify-between text-[12px] mb-2">
            <span class="text-[var(--linear-text)] font-medium">Progress</span>
            <AlertTriangle class="w-3.5 h-3.5 text-[var(--linear-muted)]" />
          </div>
          <div class="rounded border border-[var(--linear-border)] bg-[var(--linear-elevated)] px-2 py-2">
            <div class="grid grid-cols-3 gap-3 mb-2 text-[11px]">
              <div>
                <div class="text-[var(--linear-muted)]">Scope</div>
                <div class="text-[var(--linear-text)] font-semibold">{{ cycleProgressSummary.scope }}</div>
              </div>
              <div>
                <div class="text-[var(--linear-muted)]">Started</div>
                <div class="text-[var(--linear-text)] font-semibold">{{ cycleProgressSummary.started }}</div>
              </div>
              <div>
                <div class="text-[var(--linear-muted)]">Completed</div>
                <div class="text-[var(--linear-text)] font-semibold">{{ cycleProgressSummary.completed }}</div>
              </div>
            </div>
            <svg viewBox="0 0 300 110" class="w-full h-[112px]">
              <rect x="0" y="0" width="300" height="110" fill="transparent" />
              <path :d="progressChartPath.started" stroke="#e5b909" stroke-width="2" fill="none" />
              <path :d="progressChartPath.completed" stroke="#7386ff" stroke-width="2" fill="none" stroke-dasharray="3 3" />
              <rect
                v-for="bar in progressChartPath.bars"
                :key="`bar-${bar.x}-${bar.y}`"
                :x="bar.x"
                :y="bar.y"
                width="3"
                :height="bar.h"
                fill="#5f74ff"
                rx="1"
              />
            </svg>
          </div>
        </div>
        <div v-else class="p-4 border-b border-[var(--linear-border-subtle)]">
          <div class="flex items-center justify-between text-[12px] mb-3">
            <span class="text-[var(--linear-text)] font-medium inline-flex items-center gap-1">Planning <ChevronDown class="w-3 h-3" /></span>
          </div>
          <div class="grid grid-cols-3 gap-4 text-[12px]">
            <div>
              <div class="text-[var(--linear-muted)] inline-flex items-center gap-1">
                <span class="w-1.5 h-1.5 rounded-sm bg-indigo-500" />
                % of capacity
              </div>
              <div class="text-[var(--linear-text)] font-semibold">0%</div>
            </div>
            <div>
              <div class="text-[var(--linear-muted)] inline-flex items-center gap-1">
                <Clock3 class="w-3 h-3" />
                Days to start
              </div>
              <div class="text-[var(--linear-text)] font-semibold">{{ daysToStart }}</div>
            </div>
            <div>
              <div class="text-[var(--linear-muted)] inline-flex items-center gap-1">
                <span class="w-1.5 h-1.5 rounded-sm bg-[var(--linear-muted)]" />
                Scope
              </div>
              <div class="text-[var(--linear-text)] font-semibold">0</div>
            </div>
          </div>
        </div>

        <div v-if="mode !== 'upcoming'" class="p-4">
          <div class="flex items-center gap-2 mb-2 text-[11px]">
            <span class="px-2 py-1 rounded border border-[var(--linear-border)] text-[var(--linear-text)] bg-[var(--linear-elevated)]">Assignees</span>
            <span class="px-2 py-1 rounded text-[var(--linear-muted)]">Labels</span>
            <span class="px-2 py-1 rounded text-[var(--linear-muted)]">Priority</span>
            <span class="px-2 py-1 rounded text-[var(--linear-muted)]">Projects</span>
            <span class="px-2 py-1 rounded text-[var(--linear-muted)]">Teams</span>
          </div>
          <div class="space-y-2.5 max-h-[320px] overflow-auto">
            <div v-for="row in assigneeStats" :key="row.key" class="grid grid-cols-[1fr_auto] gap-3 items-center">
              <span class="text-[12px] text-[var(--linear-text)] truncate">{{ row.name }}</span>
              <span class="text-[12px] text-[var(--linear-muted)] inline-flex items-center gap-1">
                <span class="w-2.5 h-2.5 rounded-full border border-indigo-400 inline-block" />
                {{ row.total === 0 ? 0 : Math.round((row.done / row.total) * 100) }}%
                <span class="text-[10px]">△ {{ row.total }}</span>
              </span>
            </div>
          </div>
        </div>
      </aside>
    </div>

    <div
      v-if="loading"
      class="absolute top-3 right-3 w-4 h-4 rounded-full border-2 border-[var(--linear-accent)] border-t-transparent animate-spin pointer-events-none"
      aria-hidden="true"
    />
  </div>
</template>
