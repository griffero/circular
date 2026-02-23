<script setup lang="ts">
import { computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useIssuesStore } from '@/stores/issues'
import { useUiStore } from '@/stores/ui'
import { cn } from '@/utils/cn'
import Avatar from '@/components/ui/Avatar.vue'
import type { Issue, WorkflowState, WorkflowStateType } from '@/types'
import { 
  Plus, 
  Circle,
  CircleDot,
  CircleDashed,
  CheckCircle2,
  XCircle,
  MoreHorizontal,
  AlertTriangle,
  ArrowUp,
  ArrowRight,
  ArrowDown,
  Minus,
  SignalHigh,
  SignalMedium,
  SignalLow
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const appStore = useAppStore()
const issuesStore = useIssuesStore()
const uiStore = useUiStore()

const teams = computed(() => appStore.teams)
const currentTeam = computed(() => {
  const teamKey = route.params.teamKey as string
  return teams.value.find(t => t.key === teamKey)
})

const loading = computed(() => issuesStore.loading)

// Dynamic workflow states ordered by position
const columns = computed(() => {
  return [...issuesStore.workflowStates].sort((a, b) => a.position - b.position)
})

// Group issues by workflow state ID
const issuesByColumn = computed(() => {
  const grouped: Record<string, Issue[]> = {}
  
  // Initialize empty arrays for each workflow state
  for (const state of columns.value) {
    grouped[state.id] = []
  }
  
  // Group issues by workflowStateId
  const teamIssues = issuesStore.issues.filter(i => i.teamId === currentTeam.value?.id)
  for (const issue of teamIssues) {
    if (issue.workflowStateId && grouped[issue.workflowStateId]) {
      grouped[issue.workflowStateId].push(issue)
    }
  }
  
  return grouped
})

// Fetch workflow states and issues when team changes
watch(
  () => currentTeam.value?.id,
  async (teamId) => {
    if (teamId) {
      // Fetch workflow states first, then issues
      await issuesStore.fetchWorkflowStates(teamId)
      await issuesStore.fetchIssues({ teamId })
    }
  },
  { immediate: true }
)

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
  <div class="h-full overflow-x-auto bg-[var(--linear-bg)]">
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
        <div class="flex-1 overflow-y-auto px-1.5 pb-2 space-y-1">
          <!-- Issue cards -->
          <div
            v-for="issue in issuesByColumn[column.id]"
            :key="issue.id"
            @click="handleIssueClick(issue)"
            :class="cn(
              'px-3 py-2.5 bg-[var(--linear-elevated)] rounded border border-[var(--linear-border)]',
              'hover:border-[#343a46] hover:bg-[var(--linear-surface)]',
              'cursor-pointer transition-colors'
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
</template>
