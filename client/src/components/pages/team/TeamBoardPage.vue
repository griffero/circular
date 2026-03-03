<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useUiStore } from '@/stores/ui'
import { useIssuesStore, type IssueFilters } from '@/stores/issues'
import { cn } from '@/utils/cn'
import Avatar from '@/components/ui/Avatar.vue'
import IssueFiltersComponent from '@/components/issues/IssueFilters.vue'
import type { Issue, WorkflowState, WorkflowStateType } from '@/types'
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
const uiStore = useUiStore()
const issuesStore = useIssuesStore()
const { currentTeam } = useCurrentTeam()

const filters = ref<IssueFilters>({
  sort: 'updated_at',
  direction: 'desc',
  perPage: 500,
})
const draggingIssueId = ref<string | null>(null)
const movingIssueIds = ref<Set<string>>(new Set())
const dropTargetStateId = ref<string | null>(null)

const loading = computed(() => issuesStore.loading)
const boardIssues = computed(() => issuesStore.issues)
const boardWorkflowStates = computed(() => issuesStore.workflowStates)
const teamId = computed(() => currentTeam.value?.id)
const effectiveFilters = computed<IssueFilters>(() => ({
  ...filters.value,
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

function handleFilterUpdate(nextFilters: IssueFilters) {
  filters.value = { ...nextFilters, perPage: 500 }
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
        :filters="filters"
        @update:filters="handleFilterUpdate"
      />
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
