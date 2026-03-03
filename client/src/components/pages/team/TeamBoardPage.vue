<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUiStore } from '@/stores/ui'
import { useIssuesStore, type IssueFilters } from '@/stores/issues'
import { cn } from '@/utils/cn'
import Avatar from '@/components/ui/Avatar.vue'
import IssueFiltersComponent from '@/components/issues/IssueFilters.vue'
import type { Issue, IssueStatus, WorkflowState, WorkflowStateType } from '@/types'
import { useCurrentTeam } from '@/composables/useCurrentTeam'
import { 
  Plus, 
  Circle,
  CircleDot,
  CircleDashed,
  CheckCircle2,
  XCircle,
  MoreHorizontal,
  ArrowUp,
  ArrowRight,
  ArrowDown,
  Minus,
  SignalHigh,
  SignalMedium,
  SignalLow
} from 'lucide-vue-next'

const router = useRouter()
const route = useRoute()
const uiStore = useUiStore()
const issuesStore = useIssuesStore()
const { currentTeam } = useCurrentTeam()

const validStatuses: IssueStatus[] = ['backlog', 'todo', 'in_progress', 'in_review', 'done', 'canceled']
const validSortOptions: NonNullable<IssueFilters['sort']>[] = ['created_at', 'updated_at', 'priority', 'due_date']
const validDirections: NonNullable<IssueFilters['direction']>[] = ['asc', 'desc']
const sortLabelByValue: Record<NonNullable<IssueFilters['sort']>, string> = {
  created_at: 'Created',
  updated_at: 'Updated',
  priority: 'Priority',
  due_date: 'Due date',
}
const directionLabelByValue: Record<NonNullable<IssueFilters['direction']>, string> = {
  asc: 'Ascending',
  desc: 'Descending',
}

function getQueryValue(value: unknown): string | undefined {
  if (Array.isArray(value)) return value[0]
  return typeof value === 'string' ? value : undefined
}

function parseFiltersFromQuery(query: Record<string, unknown>): IssueFilters {
  const statusesParam = getQueryValue(query.statuses)
  const statusParam = getQueryValue(query.status)
  const priorityParam = getQueryValue(query.priority)
  const assigneeParam = getQueryValue(query.assignee)
  const sortParam = getQueryValue(query.sort)
  const directionParam = getQueryValue(query.direction)
  const qParam = getQueryValue(query.q)

  const statuses = (statusesParam || statusParam || '')
    .split(',')
    .map((status) => status.trim())
    .filter((status): status is IssueStatus => validStatuses.includes(status as IssueStatus))

  const parsedPriority = priorityParam !== undefined ? Number(priorityParam) : undefined
  const priority = Number.isInteger(parsedPriority) && parsedPriority >= 0 && parsedPriority <= 4
    ? parsedPriority
    : undefined

  const sort = validSortOptions.includes(sortParam as NonNullable<IssueFilters['sort']>)
    ? (sortParam as NonNullable<IssueFilters['sort']>)
    : undefined

  const direction = validDirections.includes(directionParam as NonNullable<IssueFilters['direction']>)
    ? (directionParam as NonNullable<IssueFilters['direction']>)
    : undefined

  return {
    statuses: statuses.length > 0 ? statuses : undefined,
    status: statuses.length === 1 ? statuses[0] : undefined,
    priority,
    assigneeId: assigneeParam || undefined,
    sort,
    direction,
    q: qParam && qParam.trim().length > 0 ? qParam.trim() : undefined,
  }
}

function normalizeFilters(filters: IssueFilters): IssueFilters {
  const normalizedStatuses = filters.statuses && filters.statuses.length > 0
    ? Array.from(new Set(filters.statuses))
    : undefined

  return {
    status: normalizedStatuses && normalizedStatuses.length === 1 ? normalizedStatuses[0] : undefined,
    statuses: normalizedStatuses,
    priority: filters.priority,
    assigneeId: filters.assigneeId,
    sort: filters.sort,
    direction: filters.direction,
    q: filters.q && filters.q.trim().length > 0 ? filters.q.trim() : undefined,
  }
}

function serializeFiltersForQuery(filters: IssueFilters): Record<string, string> {
  const serialized: Record<string, string> = {}

  if (filters.statuses && filters.statuses.length > 0) serialized.statuses = filters.statuses.join(',')
  if (filters.priority !== undefined) serialized.priority = String(filters.priority)
  if (filters.assigneeId) serialized.assignee = filters.assigneeId
  if (filters.sort) serialized.sort = filters.sort
  if (filters.direction) serialized.direction = filters.direction
  if (filters.q) serialized.q = filters.q

  return serialized
}

function areFiltersEqual(a: IssueFilters, b: IssueFilters): boolean {
  return JSON.stringify(normalizeFilters(a)) === JSON.stringify(normalizeFilters(b))
}

const filters = ref<IssueFilters>(parseFiltersFromQuery(route.query as Record<string, unknown>))
const draggingIssueId = ref<string | null>(null)
const movingIssueIds = ref<Set<string>>(new Set())
const dropTargetStateId = ref<string | null>(null)

const loading = computed(() => issuesStore.loading)
const boardIssues = computed(() => issuesStore.issues)
const boardWorkflowStates = computed(() => issuesStore.workflowStates)
const teamId = computed(() => currentTeam.value?.id)
const resolvedSort = computed<IssueFilters['sort']>(() => filters.value.sort || 'updated_at')
const resolvedDirection = computed<IssueFilters['direction']>(() => filters.value.direction || 'desc')
const visibleFilters = computed<IssueFilters>(() => ({
  ...filters.value,
  sort: resolvedSort.value,
  direction: resolvedDirection.value,
}))
const statusLabelByValue: Record<IssueStatus, string> = {
  backlog: 'Backlog',
  todo: 'Todo',
  in_progress: 'In Progress',
  in_review: 'In Review',
  done: 'Done',
  canceled: 'Canceled',
}
const effectiveFilters = computed<IssueFilters>(() => ({
  ...filters.value,
  sort: resolvedSort.value,
  direction: resolvedDirection.value,
  teamId: teamId.value,
  perPage: 500,
}))

// Dynamic workflow states ordered by position
const columns = computed(() => {
  return [...boardWorkflowStates.value].sort((a, b) => a.position - b.position)
})

// Group issues by workflow state ID
const issuesByColumn = computed(() => {
  const grouped: Record<string, Issue[]> = {}
  
  // Initialize empty arrays for each workflow state
  for (const state of columns.value) {
    grouped[state.id] = []
  }

  // Group issues by workflowStateId and keep API order inside each column
  const fallbackStateId = columns.value[0]?.id
  const teamIssues = boardIssues.value.filter((issue) => issue.teamId === currentTeam.value?.id)
  for (const issue of teamIssues) {
    const targetStateId = issue.workflowStateId && grouped[issue.workflowStateId]
      ? issue.workflowStateId
      : fallbackStateId
    if (targetStateId && grouped[targetStateId]) {
      grouped[targetStateId].push(issue)
    }
  }

  return grouped
})

async function fetchBoardWorkflowStates(nextTeamId: string) {
  await issuesStore.fetchWorkflowStates(nextTeamId)
}

async function fetchBoardIssues() {
  if (!teamId.value) return
  await issuesStore.fetchIssues(effectiveFilters.value)
}

watch(
  teamId,
  async (nextTeamId) => {
    if (!nextTeamId) return
    await fetchBoardWorkflowStates(nextTeamId)
    await fetchBoardIssues()
  },
  { immediate: true }
)

watch(
  effectiveFilters,
  () => {
    fetchBoardIssues()
  },
  { deep: true }
)

watch(
  () => route.query,
  (query) => {
    const parsed = parseFiltersFromQuery(query as Record<string, unknown>)
    if (!areFiltersEqual(filters.value, parsed)) {
      filters.value = parsed
    }
  }
)

watch(
  filters,
  (nextFilters) => {
    const normalized = normalizeFilters(nextFilters)
    if (!areFiltersEqual(nextFilters, normalized)) {
      filters.value = normalized
      return
    }

    const nextQuery = { ...route.query } as Record<string, string | undefined>
    delete nextQuery.statuses
    delete nextQuery.status
    delete nextQuery.priority
    delete nextQuery.assignee
    delete nextQuery.sort
    delete nextQuery.direction
    delete nextQuery.q

    const serialized = serializeFiltersForQuery(normalized)
    const merged = { ...nextQuery, ...serialized }

    const currentSerialized = JSON.stringify(route.query)
    const nextSerialized = JSON.stringify(merged)
    if (currentSerialized !== nextSerialized) {
      router.replace({ path: route.path, query: merged })
    }
  },
  { deep: true }
)

function handleFilterUpdate(nextFilters: IssueFilters) {
  filters.value = { ...nextFilters }
}

const activeFilterChips = computed(() => {
  const chips: Array<{ key: string; label: string; clear: () => void }> = []

  if (filters.value.statuses && filters.value.statuses.length > 0) {
    for (const status of filters.value.statuses) {
      const nextStatuses = filters.value.statuses.filter((item) => item !== status)
      chips.push({
        key: `status-${status}`,
        label: `Status: ${statusLabelByValue[status] || status}`,
        clear: () => {
          filters.value = {
            ...filters.value,
            status: nextStatuses.length === 1 ? nextStatuses[0] : undefined,
            statuses: nextStatuses.length > 0 ? nextStatuses : undefined,
          }
        },
      })
    }
  } else if (filters.value.status) {
    chips.push({
      key: `status-${filters.value.status}`,
      label: `Status: ${statusLabelByValue[filters.value.status] || filters.value.status}`,
      clear: () => {
        filters.value = { ...filters.value, status: undefined, statuses: undefined }
      },
    })
  }

  if (filters.value.priority !== undefined) {
    chips.push({
      key: 'priority',
      label: `Priority: P${filters.value.priority}`,
      clear: () => {
        filters.value = { ...filters.value, priority: undefined }
      },
    })
  }

  if (filters.value.assigneeId) {
    chips.push({
      key: 'assignee',
      label: filters.value.assigneeId === 'unassigned' ? 'Assignee: Unassigned' : 'Assignee',
      clear: () => {
        filters.value = { ...filters.value, assigneeId: undefined }
      },
    })
  }

  if (filters.value.q) {
    chips.push({
      key: 'q',
      label: `Search: ${filters.value.q}`,
      clear: () => {
        filters.value = { ...filters.value, q: undefined }
      },
    })
  }

  if (filters.value.sort) {
    chips.push({
      key: 'sort',
      label: `Sort: ${sortLabelByValue[filters.value.sort] || filters.value.sort}`,
      clear: () => {
        filters.value = { ...filters.value, sort: undefined }
      },
    })
  }

  if (filters.value.direction) {
    chips.push({
      key: 'direction',
      label: `Direction: ${directionLabelByValue[filters.value.direction] || filters.value.direction}`,
      clear: () => {
        filters.value = { ...filters.value, direction: undefined }
      },
    })
  }

  return chips
})

function clearAllFilters() {
  filters.value = {
    ...filters.value,
    status: undefined,
    statuses: undefined,
    priority: undefined,
    assigneeId: undefined,
    q: undefined,
    sort: undefined,
    direction: undefined,
  }
}

function handleDragStart(issueId: string) {
  draggingIssueId.value = issueId
}

function handleDragEnd() {
  draggingIssueId.value = null
  dropTargetStateId.value = null
}

function handleDragOver(stateId: string) {
  dropTargetStateId.value = stateId
}

async function handleDrop(stateId: string) {
  dropTargetStateId.value = null
  const issueId = draggingIssueId.value
  if (!issueId) return

  const issue = boardIssues.value.find((candidate) => candidate.id === issueId)
  if (!issue || issue.workflowStateId === stateId || movingIssueIds.value.has(issueId)) return

  movingIssueIds.value.add(issueId)
  try {
    await issuesStore.updateIssue(issueId, { workflowStateId: stateId })
  } finally {
    movingIssueIds.value.delete(issueId)
    draggingIssueId.value = null
  }
}

function handleIssueClick(issue: Issue) {
  router.push(`/issue/${issue.id}`)
}

// State type to icon mapping (matches Linear's icons)
const stateIcons: Record<WorkflowStateType, typeof Circle> = {
  triage: CircleDashed,
  backlog: Circle,
  unstarted: Circle,
  started: CircleDot,
  completed: CheckCircle2,
  canceled: XCircle
}

function getStateIcon(state: WorkflowState) {
  return stateIcons[state.stateType] || Circle
}

const priorityConfig: Record<number, { icon: typeof Circle; color: string; label: string }> = {
  0: { icon: Minus, color: 'text-gray-400', label: 'No priority' },
  1: { icon: SignalHigh, color: 'text-red-500', label: 'Urgent' },
  2: { icon: SignalHigh, color: 'text-orange-500', label: 'High' },
  3: { icon: SignalMedium, color: 'text-yellow-500', label: 'Medium' },
  4: { icon: SignalLow, color: 'text-blue-400', label: 'Low' },
}
</script>

<template>
  <div class="h-full flex flex-col bg-[var(--linear-bg)]">
    <div
      v-if="uiStore.filtersOpen"
      class="px-4 py-3 border-b border-[var(--linear-border)] bg-[var(--linear-bg)]"
    >
      <IssueFiltersComponent
        :filters="visibleFilters"
        @update:filters="handleFilterUpdate"
      />
      <div v-if="activeFilterChips.length > 0" class="mt-2 flex flex-wrap items-center gap-2">
        <button
          v-for="chip in activeFilterChips"
          :key="chip.key"
          class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] border border-[var(--linear-border)] bg-[var(--linear-surface)] text-[var(--linear-text)]"
          @click="chip.clear"
        >
          <span>{{ chip.label }}</span>
          <span class="text-[var(--linear-muted)]">x</span>
        </button>
        <button
          class="text-[11px] text-[var(--linear-muted)] hover:text-[var(--linear-text)] underline underline-offset-2"
          @click="clearAllFilters"
        >
          Clear all
        </button>
      </div>
    </div>

    <div class="flex-1 overflow-x-auto">
    <div v-if="loading && columns.length === 0" class="flex items-center justify-center py-16 h-full">
      <div class="animate-spin rounded-full h-8 w-8 border-2 border-[var(--linear-accent)] border-t-transparent"></div>
    </div>

    <div v-else-if="columns.length === 0" class="flex items-center justify-center py-16 h-full text-[var(--linear-muted)]">
      No workflow states found for this team
    </div>

    <div v-else class="flex gap-0.5 p-2 h-full min-w-max">
        <div
          v-for="column in columns"
          :key="column.id"
          class="w-[280px] flex-shrink-0 flex flex-col group"
          @dragover.prevent="handleDragOver(column.id)"
          @drop.prevent="handleDrop(column.id)"
        >
          <!-- Column header -->
          <div class="flex items-center justify-between px-3 py-2 sticky top-0 bg-[var(--linear-bg)] z-10">
          <div class="flex items-center gap-2">
            <component 
              :is="getStateIcon(column)" 
              class="h-4 w-4 flex-shrink-0" 
              :style="{ color: column.color }"
            />
            <span class="font-medium text-sm text-[var(--linear-text)]">{{ column.name }}</span>
            <span class="text-xs text-[var(--linear-muted)]">
              {{ issuesByColumn[column.id]?.length || 0 }}
            </span>
          </div>
          <div class="flex items-center">
            <button class="p-1 hover:bg-[var(--linear-surface)] rounded opacity-0 group-hover:opacity-100 transition-opacity">
              <MoreHorizontal class="h-4 w-4 text-[var(--linear-muted)]" />
            </button>
            <button 
              class="p-1 hover:bg-[var(--linear-surface)] rounded"
              @click="uiStore.openCreateIssueModal()"
            >
              <Plus class="h-4 w-4 text-[var(--linear-muted)]" />
            </button>
          </div>
        </div>

        <!-- Column content -->
        <div
          :class="cn(
            'flex-1 overflow-y-auto px-1.5 pb-2 space-y-1 rounded',
            dropTargetStateId === column.id && 'bg-[var(--linear-elevated)]'
          )"
        >
          <!-- Issue cards -->
          <div
            v-for="issue in issuesByColumn[column.id]"
            :key="issue.id"
            @click="handleIssueClick(issue)"
            draggable="true"
            @dragstart="handleDragStart(issue.id)"
            @dragend="handleDragEnd"
            :class="cn(
              'px-3 py-2.5 bg-[var(--linear-elevated)] rounded border border-[var(--linear-border)]',
              'hover:border-[#343a46] hover:bg-[var(--linear-surface)]',
              'cursor-pointer transition-colors',
              movingIssueIds.has(issue.id) && 'opacity-60'
            )"
          >
            <!-- Issue header: identifier + priority -->
            <div class="flex items-center justify-between mb-1">
              <span class="text-xs font-mono text-[var(--linear-muted)]">{{ issue.identifier }}</span>
              <component 
                v-if="issue.priority > 0"
                :is="priorityConfig[issue.priority]?.icon || Minus" 
                :class="cn('h-3.5 w-3.5', priorityConfig[issue.priority]?.color)" 
              />
            </div>

            <!-- Title -->
            <p class="text-sm text-[var(--linear-text)] line-clamp-2 leading-snug mb-2">
              {{ issue.title }}
            </p>

            <!-- Footer: labels + assignee -->
            <div class="flex items-center justify-between gap-2">
              <!-- Labels -->
              <div class="flex items-center gap-1 flex-wrap flex-1 min-w-0">
                <template v-if="issue.labels && issue.labels.length > 0">
                  <div
                    v-for="label in issue.labels.slice(0, 2)"
                    :key="label.id"
                    class="flex items-center gap-1 px-1.5 py-0.5 rounded text-[11px] font-medium"
                    :style="{ 
                      backgroundColor: `${label.color}18`,
                      color: label.color
                    }"
                  >
                    <span class="truncate max-w-[100px]">{{ label.name }}</span>
                  </div>
                  <span 
                    v-if="issue.labels.length > 2" 
                    class="text-[11px] text-[var(--linear-muted)]"
                  >
                    +{{ issue.labels.length - 2 }}
                  </span>
                </template>
              </div>

              <!-- Assignee -->
              <Avatar
                v-if="issue.assignee"
                :name="issue.assignee.name || issue.assignee.displayName || issue.assignee.email"
                :src="issue.assignee.avatarUrl"
                size="xs"
                class="flex-shrink-0"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
    </div>
  </div>
</template>
