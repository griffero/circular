<script setup lang="ts">
import { computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useIssuesStore } from '@/stores/issues'
import { useUiStore } from '@/stores/ui'
import { cn } from '@/utils/cn'
import Avatar from '@/components/ui/Avatar.vue'
import type { Issue, IssueStatus } from '@/types'
import { 
  Plus, 
  Circle, 
  Clock, 
  CheckCircle2,
  AlertTriangle,
  ArrowUp,
  ArrowRight,
  ArrowDown
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

// Kanban columns
const columns: { id: IssueStatus; name: string; icon: typeof Circle; color: string }[] = [
  { id: 'backlog', name: 'Backlog', icon: Circle, color: 'text-gray-400' },
  { id: 'todo', name: 'Todo', icon: Circle, color: 'text-gray-500' },
  { id: 'in_progress', name: 'In Progress', icon: Clock, color: 'text-yellow-500' },
  { id: 'in_review', name: 'In Review', icon: Clock, color: 'text-blue-500' },
  { id: 'done', name: 'Done', icon: CheckCircle2, color: 'text-green-500' },
]

const issuesByColumn = computed(() => {
  const teamIssues = issuesStore.issues.filter(i => i.teamId === currentTeam.value?.id)
  const grouped: Record<IssueStatus, Issue[]> = {
    backlog: [],
    todo: [],
    in_progress: [],
    in_review: [],
    done: [],
    canceled: []
  }
  for (const issue of teamIssues) {
    grouped[issue.status].push(issue)
  }
  return grouped
})

// Fetch issues when team changes
watch(
  () => currentTeam.value?.id,
  async (teamId) => {
    if (teamId) {
      await issuesStore.fetchIssues({ teamId })
    }
  },
  { immediate: true }
)

function handleIssueClick(issue: Issue) {
  router.push(`/issue/${issue.id}`)
}

const priorityIcons: Record<number, { icon: typeof Circle; color: string }> = {
  0: { icon: Circle, color: 'text-gray-400' },
  1: { icon: AlertTriangle, color: 'text-red-500' },
  2: { icon: ArrowUp, color: 'text-orange-500' },
  3: { icon: ArrowRight, color: 'text-yellow-500' },
  4: { icon: ArrowDown, color: 'text-blue-500' },
}
</script>

<template>
  <div class="h-full overflow-x-auto">
    <div v-if="loading" class="flex items-center justify-center py-16 h-full">
      <div class="animate-spin rounded-full h-8 w-8 border-2 border-primary-600 border-t-transparent"></div>
    </div>

    <div v-else class="flex gap-4 p-4 h-full min-w-max">
      <div
        v-for="column in columns"
        :key="column.id"
        class="w-72 flex-shrink-0 flex flex-col bg-gray-50 dark:bg-gray-900/50 rounded-lg"
      >
        <!-- Column header -->
        <div class="flex items-center justify-between px-3 py-2 border-b border-gray-200 dark:border-gray-800">
          <div class="flex items-center gap-2">
            <component :is="column.icon" :class="cn('h-4 w-4', column.color)" />
            <span class="font-medium text-sm text-gray-900 dark:text-gray-100">{{ column.name }}</span>
            <span class="text-xs text-gray-500 bg-gray-200 dark:bg-gray-800 px-1.5 py-0.5 rounded">
              {{ issuesByColumn[column.id]?.length || 0 }}
            </span>
          </div>
          <button 
            class="p-1 hover:bg-gray-200 dark:hover:bg-gray-800 rounded"
            @click="uiStore.openCreateIssueModal()"
          >
            <Plus class="h-4 w-4 text-gray-400" />
          </button>
        </div>

        <!-- Column content -->
        <div class="flex-1 overflow-y-auto p-2 space-y-2">
          <div
            v-if="issuesByColumn[column.id]?.length === 0"
            class="py-8 text-center text-sm text-gray-400"
          >
            No issues
          </div>

          <!-- Issue cards -->
          <div
            v-for="issue in issuesByColumn[column.id]"
            :key="issue.id"
            @click="handleIssueClick(issue)"
            :class="cn(
              'p-3 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700',
              'hover:border-gray-300 dark:hover:border-gray-600',
              'cursor-pointer transition-colors shadow-sm'
            )"
          >
            <!-- Issue identifier -->
            <div class="flex items-center justify-between mb-2">
              <span class="text-xs font-mono text-gray-500">{{ issue.identifier }}</span>
              <component 
                v-if="issue.priority > 0"
                :is="priorityIcons[issue.priority]?.icon || Circle" 
                :class="cn('h-3.5 w-3.5', priorityIcons[issue.priority]?.color)" 
              />
            </div>

            <!-- Title -->
            <p class="text-sm text-gray-900 dark:text-gray-100 line-clamp-2 mb-2">
              {{ issue.title }}
            </p>

            <!-- Footer -->
            <div class="flex items-center justify-between">
              <!-- Labels -->
              <div class="flex items-center gap-1">
                <div
                  v-for="label in issue.labels?.slice(0, 2)"
                  :key="label.id"
                  class="w-2 h-2 rounded-full"
                  :style="{ backgroundColor: label.color }"
                />
              </div>

              <!-- Assignee -->
              <Avatar
                v-if="issue.assignee"
                :name="issue.assignee.name"
                size="xs"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
