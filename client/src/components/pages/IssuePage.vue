<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import {
  ArrowLeft,
  Circle,
  CheckCircle2,
  XCircle,
  Clock,
  User,
  Tag,
  FolderKanban,
  Calendar,
  MessageSquare
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const user = computed(() => authStore.user)
const issueId = computed(() => route.params.issueId as string)

// Placeholder issue data
const issue = ref<{
  id: string
  identifier: string
  title: string
  description: string
  status: string
  priority: number
  assignee?: { id: string; name: string }
  createdAt: string
} | null>({
  id: '1',
  identifier: 'ENG-1',
  title: 'Example Issue',
  description: 'This is a placeholder issue. The full issue page will be implemented in F3.',
  status: 'todo',
  priority: 2,
  assignee: { id: '1', name: 'John Doe' },
  createdAt: new Date().toISOString(),
})

const loading = ref(false)

const priorities = [
  { value: 0, label: 'No priority', color: 'text-gray-400' },
  { value: 1, label: 'Urgent', color: 'text-red-500' },
  { value: 2, label: 'High', color: 'text-orange-500' },
  { value: 3, label: 'Medium', color: 'text-yellow-500' },
  { value: 4, label: 'Low', color: 'text-blue-500' },
]

const statuses = [
  { value: 'backlog', label: 'Backlog', icon: Circle, color: 'text-gray-400' },
  { value: 'todo', label: 'Todo', icon: Circle, color: 'text-gray-500' },
  { value: 'in_progress', label: 'In Progress', icon: Clock, color: 'text-yellow-500' },
  { value: 'done', label: 'Done', icon: CheckCircle2, color: 'text-green-500' },
  { value: 'canceled', label: 'Canceled', icon: XCircle, color: 'text-red-400' },
]

function getStatus(value: string) {
  return statuses.find(s => s.value === value) || statuses[0]
}

function getPriority(value: number) {
  return priorities.find(p => p.value === value) || priorities[0]
}
</script>

<template>
  <div class="h-full flex bg-[#0d0d0d]">
    <!-- Main content -->
    <div class="flex-1 flex flex-col overflow-hidden">
      <!-- Header -->
      <div class="flex items-center gap-3 px-4 py-2 border-b border-[#1f1f1f]">
        <button 
          @click="router.back()"
          class="p-1.5 hover:bg-[#1a1a1a] rounded text-gray-500 hover:text-white transition-colors"
        >
          <ArrowLeft class="h-4 w-4" />
        </button>
        <span class="text-sm font-mono text-gray-500">{{ issue?.identifier }}</span>
      </div>

      <!-- Issue content -->
      <div v-if="loading" class="flex items-center justify-center py-16">
        <div class="animate-spin rounded-full h-8 w-8 border-2 border-indigo-500 border-t-transparent"></div>
      </div>

      <div v-else-if="issue" class="flex-1 overflow-auto p-6">
        <h1 class="text-2xl font-semibold text-white mb-4">
          {{ issue.title }}
        </h1>

        <div
          v-if="issue.description"
          class="prose prose-invert max-w-none mb-8 prose-p:my-3 prose-ul:my-3 prose-ol:my-3"
          v-html="issue.description"
        />
        <div v-else class="text-sm text-gray-500 mb-8">
          No description
        </div>

        <!-- Comments section placeholder -->
        <div class="border-t border-[#1f1f1f] pt-6">
          <h2 class="text-sm font-medium text-white mb-4 flex items-center gap-2">
            <MessageSquare class="h-4 w-4" />
            Activity
          </h2>
          <div class="text-sm text-gray-500 text-center py-8">
            No activity yet
          </div>
        </div>
      </div>

      <div v-else class="flex items-center justify-center h-full">
        <div class="text-center">
          <p class="text-gray-500">Issue not found</p>
          <button 
            @click="router.push('/')"
            class="mt-4 px-4 py-2 text-sm text-gray-400 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors"
          >
            Go back home
          </button>
        </div>
      </div>
    </div>

    <!-- Sidebar -->
    <div v-if="issue" class="w-72 border-l border-[#1f1f1f] bg-[#111] p-4 overflow-auto">
      <div class="space-y-4">
        <!-- Status -->
        <div>
          <label class="text-xs font-medium text-gray-500 uppercase tracking-wider mb-2 block">Status</label>
          <button class="w-full flex items-center gap-2 px-3 py-2 bg-[#1a1a1a] border border-[#2a2a2a] rounded hover:bg-[#222] text-sm text-white transition-colors">
            <component :is="getStatus(issue.status).icon" :class="['h-4 w-4', getStatus(issue.status).color]" />
            {{ getStatus(issue.status).label }}
          </button>
        </div>

        <!-- Priority -->
        <div>
          <label class="text-xs font-medium text-gray-500 uppercase tracking-wider mb-2 block">Priority</label>
          <button class="w-full flex items-center gap-2 px-3 py-2 bg-[#1a1a1a] border border-[#2a2a2a] rounded hover:bg-[#222] text-sm text-white transition-colors">
            <span :class="['font-mono font-bold', getPriority(issue.priority).color]">
              {{ issue.priority === 0 ? '—' : 'P' + issue.priority }}
            </span>
            {{ getPriority(issue.priority).label }}
          </button>
        </div>

        <!-- Assignee -->
        <div>
          <label class="text-xs font-medium text-gray-500 uppercase tracking-wider mb-2 block">Assignee</label>
          <button class="w-full flex items-center gap-2 px-3 py-2 bg-[#1a1a1a] border border-[#2a2a2a] rounded hover:bg-[#222] text-sm transition-colors">
            <template v-if="issue.assignee">
              <div class="w-5 h-5 rounded-full bg-indigo-600 flex items-center justify-center text-[10px] text-white">
                {{ issue.assignee.name.charAt(0) }}
              </div>
              <span class="text-white">{{ issue.assignee.name }}</span>
            </template>
            <template v-else>
              <User class="h-4 w-4 text-gray-400" />
              <span class="text-gray-500">Unassigned</span>
            </template>
          </button>
        </div>

        <!-- Labels placeholder -->
        <div>
          <label class="text-xs font-medium text-gray-500 uppercase tracking-wider mb-2 block">Labels</label>
          <button class="w-full flex items-center gap-2 px-3 py-2 bg-[#1a1a1a] border border-[#2a2a2a] rounded hover:bg-[#222] text-sm text-gray-500 transition-colors">
            <Tag class="h-4 w-4" />
            Add labels
          </button>
        </div>

        <!-- Project placeholder -->
        <div>
          <label class="text-xs font-medium text-gray-500 uppercase tracking-wider mb-2 block">Project</label>
          <button class="w-full flex items-center gap-2 px-3 py-2 bg-[#1a1a1a] border border-[#2a2a2a] rounded hover:bg-[#222] text-sm text-gray-500 transition-colors">
            <FolderKanban class="h-4 w-4" />
            Add to project
          </button>
        </div>

        <!-- Due date placeholder -->
        <div>
          <label class="text-xs font-medium text-gray-500 uppercase tracking-wider mb-2 block">Due date</label>
          <button class="w-full flex items-center gap-2 px-3 py-2 bg-[#1a1a1a] border border-[#2a2a2a] rounded hover:bg-[#222] text-sm text-gray-500 transition-colors">
            <Calendar class="h-4 w-4" />
            Set due date
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
