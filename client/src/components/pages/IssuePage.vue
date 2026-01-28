<script setup lang="ts">
import { computed, ref, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useIssuesStore } from '@/stores/issues'
import { useAppStore } from '@/stores/app'
import type { Issue, WorkflowState } from '@/types'
import Dropdown from '@/components/ui/Dropdown.vue'
import DropdownItem from '@/components/ui/DropdownItem.vue'
import Avatar from '@/components/ui/Avatar.vue'
import EmojiText from '@/components/ui/EmojiText.vue'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
import { useEmojiStore } from '@/stores/emoji'
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
  MessageSquare,
  ChevronDown,
  Minus,
  AlertCircle,
  SignalHigh,
  SignalMedium,
  SignalLow,
  Search,
  Check,
  CircleDashed
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const issuesStore = useIssuesStore()
const appStore = useAppStore()
const emojiStore = useEmojiStore()

const user = computed(() => authStore.user)
const issueId = computed(() => route.params.issueId as string)

const issue = computed(() => issuesStore.currentIssue)
const loading = computed(() => issuesStore.loading)
const workflowStates = computed(() => issuesStore.workflowStates)
const labels = computed(() => issuesStore.labels)
const users = computed(() => appStore.users)
const projects = computed(() => appStore.projects)

// Local state for date picker
const showDatePicker = ref(false)
const selectedDate = ref<string | null>(null)

// Project search
const projectSearch = ref('')
const filteredProjects = computed(() => {
  if (!projectSearch.value) return projects.value
  const search = projectSearch.value.toLowerCase()
  return projects.value.filter(p => p.name.toLowerCase().includes(search))
})

// Check if icon is emoji
function hasEmoji(icon?: string | null): boolean {
  if (!icon) return false
  if (emojiStore.getEmojiUrl(icon)) return true
  const stripped = icon.replace(/^:|:$/g, '')
  return /^[\p{Emoji}\u200d]+$/u.test(stripped) && stripped.length <= 8
}

const priorities = [
  { value: 0, label: 'No priority', icon: Minus, color: 'text-gray-400' },
  { value: 1, label: 'Urgent', icon: AlertCircle, color: 'text-red-500' },
  { value: 2, label: 'High', icon: SignalHigh, color: 'text-orange-500' },
  { value: 3, label: 'Medium', icon: SignalMedium, color: 'text-yellow-500' },
  { value: 4, label: 'Low', icon: SignalLow, color: 'text-blue-500' },
]

const statusIcons: Record<string, { icon: any; color: string }> = {
  triage: { icon: Circle, color: 'text-gray-400' },
  backlog: { icon: Circle, color: 'text-gray-400' },
  unstarted: { icon: Circle, color: 'text-gray-500' },
  started: { icon: Clock, color: 'text-yellow-500' },
  completed: { icon: CheckCircle2, color: 'text-green-500' },
  canceled: { icon: XCircle, color: 'text-red-400' },
}

function getStatusIcon(stateType?: string) {
  return statusIcons[stateType || 'backlog'] || statusIcons.backlog
}

function getPriority(value: number) {
  return priorities.find(p => p.value === value) || priorities[0]
}

// Update functions
async function updateStatus(state: WorkflowState) {
  if (!issue.value) return
  await issuesStore.updateIssue(issue.value.id, { workflowStateId: state.id })
}

async function updatePriority(priority: number) {
  if (!issue.value) return
  await issuesStore.updateIssue(issue.value.id, { priority })
}

async function updateAssignee(userId: string | null) {
  if (!issue.value) return
  await issuesStore.updateIssue(issue.value.id, { assigneeId: userId })
}

async function updateProject(projectId: string | null) {
  if (!issue.value) return
  await issuesStore.updateIssue(issue.value.id, { projectId })
}

async function updateDueDate(date: string | null) {
  if (!issue.value) return
  await issuesStore.updateIssue(issue.value.id, { dueDate: date })
  showDatePicker.value = false
}

async function toggleLabel(labelId: string) {
  if (!issue.value) return
  const currentLabelIds = issue.value.labels?.map(l => l.id) || []
  const newLabelIds = currentLabelIds.includes(labelId)
    ? currentLabelIds.filter(id => id !== labelId)
    : [...currentLabelIds, labelId]
  await issuesStore.updateIssue(issue.value.id, { labelIds: newLabelIds })
}

// Load issue when route changes
async function loadIssue() {
  if (issueId.value) {
    await issuesStore.fetchIssue(issueId.value)
    // Load workflow states for the team if we have the issue
    if (issue.value?.teamId) {
      await issuesStore.fetchWorkflowStates(issue.value.teamId)
      await issuesStore.fetchLabels(issue.value.teamId)
    }
  }
}

// Load users and projects
onMounted(async () => {
  await loadIssue()
  if (users.value.length === 0) {
    await appStore.fetchUsers()
  }
  if (projects.value.length === 0) {
    await appStore.fetchProjects()
  }
})

watch(issueId, loadIssue)

// Format date for display
function formatDate(dateString?: string | null) {
  if (!dateString) return null
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
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
        >
          <EmojiText :text="issue.description" />
        </div>
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
          <Dropdown align="left" :full-width="true">
            <template #trigger>
              <button class="w-full flex items-center justify-between gap-2 px-3 py-2 bg-[#1a1a1a] border border-[#2a2a2a] rounded hover:bg-[#222] text-sm text-white transition-colors">
                <div class="flex items-center gap-2">
                  <component 
                    :is="getStatusIcon(issue.workflowState?.stateType).icon" 
                    :class="['h-4 w-4', getStatusIcon(issue.workflowState?.stateType).color]" 
                  />
                  {{ issue.workflowState?.name || 'Backlog' }}
                </div>
                <ChevronDown class="h-4 w-4 text-gray-500" />
              </button>
            </template>
            <div class="py-1 min-w-[200px]">
              <DropdownItem 
                v-for="state in workflowStates" 
                :key="state.id"
                @click="updateStatus(state)"
              >
                <div class="flex items-center gap-2">
                  <component 
                    :is="getStatusIcon(state.stateType).icon" 
                    :class="['h-4 w-4', getStatusIcon(state.stateType).color]" 
                  />
                  {{ state.name }}
                </div>
              </DropdownItem>
            </div>
          </Dropdown>
        </div>

        <!-- Priority -->
        <div>
          <label class="text-xs font-medium text-gray-500 uppercase tracking-wider mb-2 block">Priority</label>
          <Dropdown align="left" :full-width="true">
            <template #trigger>
              <button class="w-full flex items-center justify-between gap-2 px-3 py-2 bg-[#1a1a1a] border border-[#2a2a2a] rounded hover:bg-[#222] text-sm text-white transition-colors">
                <div class="flex items-center gap-2">
                  <component 
                    :is="getPriority(issue.priority || 0).icon" 
                    :class="['h-4 w-4', getPriority(issue.priority || 0).color]" 
                  />
                  {{ getPriority(issue.priority || 0).label }}
                </div>
                <ChevronDown class="h-4 w-4 text-gray-500" />
              </button>
            </template>
            <div class="py-1 min-w-[180px]">
              <DropdownItem 
                v-for="p in priorities" 
                :key="p.value"
                @click="updatePriority(p.value)"
              >
                <div class="flex items-center gap-2">
                  <component :is="p.icon" :class="['h-4 w-4', p.color]" />
                  {{ p.label }}
                </div>
              </DropdownItem>
            </div>
          </Dropdown>
        </div>

        <!-- Assignee -->
        <div>
          <label class="text-xs font-medium text-gray-500 uppercase tracking-wider mb-2 block">Assignee</label>
          <Dropdown align="left" :full-width="true">
            <template #trigger>
              <button class="w-full flex items-center justify-between gap-2 px-3 py-2 bg-[#1a1a1a] border border-[#2a2a2a] rounded hover:bg-[#222] text-sm transition-colors">
                <div class="flex items-center gap-2">
                  <template v-if="issue.assignee">
                    <Avatar :src="issue.assignee.avatarUrl" :name="issue.assignee.name" size="xs" />
                    <span class="text-white">{{ issue.assignee.displayName || issue.assignee.name }}</span>
                  </template>
                  <template v-else>
                    <User class="h-4 w-4 text-gray-400" />
                    <span class="text-gray-500">Unassigned</span>
                  </template>
                </div>
                <ChevronDown class="h-4 w-4 text-gray-500" />
              </button>
            </template>
            <div class="py-1 min-w-[200px] max-h-[300px] overflow-auto">
              <DropdownItem @click="updateAssignee(null)">
                <div class="flex items-center gap-2">
                  <User class="h-4 w-4 text-gray-400" />
                  <span class="text-gray-400">Unassigned</span>
                </div>
              </DropdownItem>
              <div class="border-t border-[#2a2a2a] my-1"></div>
              <DropdownItem 
                v-for="u in users" 
                :key="u.id"
                @click="updateAssignee(u.id)"
              >
                <div class="flex items-center gap-2">
                  <Avatar :src="u.avatarUrl" :name="u.name" size="xs" />
                  <span>{{ u.name }}</span>
                </div>
              </DropdownItem>
            </div>
          </Dropdown>
        </div>

        <!-- Labels -->
        <div>
          <label class="text-xs font-medium text-gray-500 uppercase tracking-wider mb-2 block">Labels</label>
          <Dropdown align="left" :full-width="true">
            <template #trigger>
              <button class="w-full flex items-center justify-between gap-2 px-3 py-2 bg-[#1a1a1a] border border-[#2a2a2a] rounded hover:bg-[#222] text-sm transition-colors">
                <div class="flex items-center gap-2 flex-wrap">
                  <template v-if="issue.labels && issue.labels.length > 0">
                    <span 
                      v-for="label in issue.labels" 
                      :key="label.id"
                      class="px-2 py-0.5 rounded text-xs"
                      :style="{ backgroundColor: label.color + '20', color: label.color }"
                    >
                      {{ label.name }}
                    </span>
                  </template>
                  <template v-else>
                    <Tag class="h-4 w-4 text-gray-400" />
                    <span class="text-gray-500">Add labels</span>
                  </template>
                </div>
                <ChevronDown class="h-4 w-4 text-gray-500 flex-shrink-0" />
              </button>
            </template>
            <div class="py-1 min-w-[200px] max-h-[300px] overflow-auto">
              <template v-if="labels.length > 0">
                <DropdownItem 
                  v-for="label in labels" 
                  :key="label.id"
                  @click="toggleLabel(label.id)"
                >
                  <div class="flex items-center justify-between w-full">
                    <div class="flex items-center gap-2">
                      <div 
                        class="w-3 h-3 rounded-full" 
                        :style="{ backgroundColor: label.color }"
                      ></div>
                      <span>{{ label.name }}</span>
                    </div>
                    <CheckCircle2 
                      v-if="issue.labels?.some(l => l.id === label.id)" 
                      class="h-4 w-4 text-indigo-400" 
                    />
                  </div>
                </DropdownItem>
              </template>
              <div v-else class="px-3 py-2 text-sm text-gray-500">
                No labels available
              </div>
            </div>
          </Dropdown>
        </div>

        <!-- Project -->
        <div>
          <label class="text-xs font-medium text-gray-500 uppercase tracking-wider mb-2 block">Project</label>
          <Dropdown align="left-side" width="w-80">
            <template #trigger>
              <button class="w-full flex items-center justify-between gap-2 px-3 py-2 bg-[#1a1a1a] border border-[#2a2a2a] rounded hover:bg-[#222] text-sm transition-colors">
                <div class="flex items-center gap-2">
                  <template v-if="issue.project">
                    <EmojiIcon 
                      v-if="hasEmoji(issue.project.icon)"
                      :name="issue.project.icon" 
                      :fallback="issue.project.name?.charAt(0) || 'P'" 
                      size="sm"
                    />
                    <div 
                      v-else
                      class="w-5 h-5 rounded flex items-center justify-center text-[10px] font-bold text-white"
                      :style="{ backgroundColor: issue.project.color || '#6366f1' }"
                    >
                      {{ issue.project.name?.charAt(0)?.toUpperCase() || 'P' }}
                    </div>
                    <span class="text-white">{{ issue.project.name }}</span>
                  </template>
                  <template v-else>
                    <FolderKanban class="h-4 w-4 text-gray-400" />
                    <span class="text-gray-500">Add to project</span>
                  </template>
                </div>
                <ChevronDown class="h-4 w-4 text-gray-500" />
              </button>
            </template>
            <div class="min-w-[280px]">
              <!-- Search input -->
              <div class="p-2 border-b border-[#2a2a2a]">
                <div class="flex items-center gap-2 px-2 py-1.5 bg-[#0d0d0d] rounded border border-[#333]">
                  <input 
                    v-model="projectSearch"
                    type="text"
                    placeholder="Move to project..."
                    class="flex-1 bg-transparent text-sm text-white placeholder-gray-500 outline-none"
                    @click.stop
                  />
                  <div class="flex items-center gap-1 text-[10px] text-gray-500">
                    <span class="px-1 py-0.5 bg-[#2a2a2a] rounded">⇧</span>
                    <span class="px-1 py-0.5 bg-[#2a2a2a] rounded">P</span>
                  </div>
                </div>
              </div>
              
              <!-- Project list -->
              <div class="max-h-[350px] overflow-auto py-1">
                <!-- No project option -->
                <button 
                  @click="updateProject(null); projectSearch = ''"
                  class="w-full flex items-center justify-between px-3 py-2 hover:bg-[#1f1f1f] transition-colors"
                >
                  <div class="flex items-center gap-3">
                    <CircleDashed class="w-5 h-5 text-gray-500" />
                    <span class="text-[13px] text-gray-300">No project</span>
                  </div>
                  <Check v-if="!issue.project" class="w-4 h-4 text-white" />
                </button>
                
                <!-- Projects -->
                <button 
                  v-for="p in filteredProjects" 
                  :key="p.id"
                  @click="updateProject(p.id); projectSearch = ''"
                  class="w-full flex items-center justify-between px-3 py-2 hover:bg-[#1f1f1f] transition-colors"
                >
                  <div class="flex items-center gap-3">
                    <EmojiIcon 
                      v-if="hasEmoji(p.icon)"
                      :name="p.icon" 
                      :fallback="p.name?.charAt(0) || 'P'" 
                      size="sm"
                    />
                    <div 
                      v-else
                      class="w-5 h-5 rounded flex items-center justify-center text-[10px] font-bold text-white"
                      :style="{ backgroundColor: p.color || '#6366f1' }"
                    >
                      {{ p.name?.charAt(0)?.toUpperCase() || 'P' }}
                    </div>
                    <span class="text-[13px] text-gray-200">{{ p.name }}</span>
                  </div>
                  <Check v-if="issue.project?.id === p.id" class="w-4 h-4 text-white" />
                </button>
                
                <!-- Empty state -->
                <div v-if="filteredProjects.length === 0 && projectSearch" class="px-3 py-4 text-center text-sm text-gray-500">
                  No projects found
                </div>
              </div>
            </div>
          </Dropdown>
        </div>

        <!-- Due date -->
        <div>
          <label class="text-xs font-medium text-gray-500 uppercase tracking-wider mb-2 block">Due date</label>
          <Dropdown align="left" :full-width="true">
            <template #trigger>
              <button class="w-full flex items-center justify-between gap-2 px-3 py-2 bg-[#1a1a1a] border border-[#2a2a2a] rounded hover:bg-[#222] text-sm transition-colors">
                <div class="flex items-center gap-2">
                  <Calendar class="h-4 w-4" :class="issue.dueDate ? 'text-indigo-400' : 'text-gray-400'" />
                  <span :class="issue.dueDate ? 'text-white' : 'text-gray-500'">
                    {{ formatDate(issue.dueDate) || 'Set due date' }}
                  </span>
                </div>
                <ChevronDown class="h-4 w-4 text-gray-500" />
              </button>
            </template>
            <div class="p-3 min-w-[200px]">
              <input 
                type="date" 
                :value="issue.dueDate?.split('T')[0]"
                @change="(e) => updateDueDate((e.target as HTMLInputElement).value)"
                class="w-full px-3 py-2 bg-[#1a1a1a] border border-[#2a2a2a] rounded text-sm text-white focus:outline-none focus:border-indigo-500"
              />
              <button 
                v-if="issue.dueDate"
                @click="updateDueDate(null)"
                class="w-full mt-2 px-3 py-1.5 text-sm text-red-400 hover:bg-[#1a1a1a] rounded transition-colors"
              >
                Remove due date
              </button>
            </div>
          </Dropdown>
        </div>
      </div>
    </div>
  </div>
</template>
