<script setup lang="ts">
import { computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useIssuesStore } from '@/stores/issues'
import { useUiStore } from '@/stores/ui'
import { cn } from '@/utils/cn'
import Avatar from '@/components/ui/Avatar.vue'
import type { Issue, WorkflowState } from '@/types'
import { 
  Plus, 
  Circle,
  MoreHorizontal,
  AlertTriangle,
  ArrowUp,
  ArrowRight,
  ArrowDown,
  Minus
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

function getStateIcon(state: WorkflowState) {
  // Return appropriate icon based on state type
  switch (state.stateType) {
    case 'backlog':
    case 'triage':
      return Circle
    case 'unstarted':
      return Circle
    case 'started':
      return Circle
    case 'completed':
      return Circle
    case 'canceled':
      return Circle
    default:
      return Circle
  }
}

const priorityConfig: Record<number, { icon: typeof Circle; color: string }> = {
  0: { icon: Minus, color: 'text-gray-400' },
  1: { icon: AlertTriangle, color: 'text-red-500' },
  2: { icon: ArrowUp, color: 'text-orange-500' },
  3: { icon: ArrowRight, color: 'text-yellow-500' },
  4: { icon: ArrowDown, color: 'text-blue-500' },
}
</script>

<template>
  <div class="h-full overflow-x-auto">
    <div v-if="loading && columns.length === 0" class="flex items-center justify-center py-16 h-full">
      <div class="animate-spin rounded-full h-8 w-8 border-2 border-primary-600 border-t-transparent"></div>
    </div>

    <div v-else-if="columns.length === 0" class="flex items-center justify-center py-16 h-full text-gray-400">
      No workflow states found for this team
    </div>

    <div v-else class="flex gap-2 p-4 h-full min-w-max">
      <div
        v-for="column in columns"
        :key="column.id"
        class="w-72 flex-shrink-0 flex flex-col bg-gray-900/30 rounded-lg"
      >
        <!-- Column header -->
        <div class="flex items-center justify-between px-3 py-2.5">
          <div class="flex items-center gap-2">
            <component 
              :is="getStateIcon(column)" 
              class="h-4 w-4" 
              :style="{ color: column.color }"
            />
            <span class="font-medium text-sm text-gray-100">{{ column.name }}</span>
            <span class="text-xs text-gray-500 ml-1">
              {{ issuesByColumn[column.id]?.length || 0 }}
            </span>
          </div>
          <div class="flex items-center gap-1">
            <button class="p-1 hover:bg-gray-800 rounded opacity-0 group-hover:opacity-100 transition-opacity">
              <MoreHorizontal class="h-4 w-4 text-gray-500" />
            </button>
            <button 
              class="p-1 hover:bg-gray-800 rounded"
              @click="uiStore.openCreateIssueModal()"
            >
              <Plus class="h-4 w-4 text-gray-500" />
            </button>
          </div>
        </div>

        <!-- Column content -->
        <div class="flex-1 overflow-y-auto px-2 pb-2 space-y-2">
          <!-- Issue cards -->
          <div
            v-for="issue in issuesByColumn[column.id]"
            :key="issue.id"
            @click="handleIssueClick(issue)"
            :class="cn(
              'p-3 bg-gray-800/80 rounded-md border border-gray-700/50',
              'hover:border-gray-600 hover:bg-gray-800',
              'cursor-pointer transition-all duration-150'
            )"
          >
            <!-- Issue header: identifier + priority -->
            <div class="flex items-center justify-between mb-1.5">
              <span class="text-xs font-mono text-gray-500">{{ issue.identifier }}</span>
              <component 
                v-if="issue.priority > 0"
                :is="priorityConfig[issue.priority]?.icon || Minus" 
                :class="cn('h-3.5 w-3.5', priorityConfig[issue.priority]?.color)" 
              />
            </div>

            <!-- Title -->
            <p class="text-sm text-gray-200 line-clamp-2 leading-snug">
              {{ issue.title }}
            </p>

            <!-- Footer: labels + assignee -->
            <div class="flex items-center justify-between mt-2">
              <!-- Labels -->
              <div class="flex items-center gap-1.5">
                <template v-if="issue.labels && issue.labels.length > 0">
                  <div
                    v-for="label in issue.labels.slice(0, 3)"
                    :key="label.id"
                    class="flex items-center gap-1 px-1.5 py-0.5 rounded text-xs"
                    :style="{ 
                      backgroundColor: `${label.color}20`,
                      color: label.color
                    }"
                  >
                    <span class="truncate max-w-[80px]">{{ label.name }}</span>
                  </div>
                </template>
              </div>

              <!-- Assignee -->
              <Avatar
                v-if="issue.assignee"
                :name="issue.assignee.name || issue.assignee.displayName || issue.assignee.email"
                :src="issue.assignee.avatarUrl"
                size="xs"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
