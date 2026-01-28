<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useEmojiStore } from '@/stores/emoji'
import { api } from '@/api/client'
import { cn } from '@/utils/cn'
import Avatar from '@/components/ui/Avatar.vue'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
import UserLink from '@/components/ui/UserLink.vue'
import type { Project, User, Team } from '@/types'
import {
  X,
  Star,
  ChevronDown,
  ChevronRight,
  Plus,
  MoreHorizontal,
  CheckCircle2,
  Circle,
  Clock,
  PauseCircle,
  XCircle,
  AlertCircle,
  Calendar,
  Users,
  Layers,
  Tag,
  Target,
  TrendingUp,
  ExternalLink
} from 'lucide-vue-next'

const props = defineProps<{
  projectId: string | null
}>()

const emit = defineEmits<{
  (e: 'close'): void
}>()

const router = useRouter()
const appStore = useAppStore()
const emojiStore = useEmojiStore()

// State
const project = ref<Project | null>(null)
const loading = ref(false)
const showProperties = ref(true)
const showMilestones = ref(true)
const showProgress = ref(true)

// Detailed project data (including members and teams)
interface DetailedProject extends Project {
  members?: User[]
}

// Check if has emoji
function hasEmoji(icon?: string | null): boolean {
  if (!icon) return false
  if (emojiStore.getEmojiUrl(icon)) return true
  const stripped = icon.replace(/^:|:$/g, '')
  return /^[\p{Emoji}\u200d]+$/u.test(stripped) && stripped.length <= 8
}

// Fetch project details when projectId changes
watch(() => props.projectId, async (newId) => {
  if (!newId) {
    project.value = null
    return
  }
  
  loading.value = true
  try {
    // Find the project in store first for quick display
    const storeProject = appStore.projects.find(p => p.id === newId)
    if (storeProject) {
      project.value = storeProject
    }
    
    // Then fetch detailed data
    const data = await api.get<{ project: DetailedProject }>(`/api/v1/projects/${storeProject?.slug || newId}`)
    project.value = data.project
  } catch (err) {
    console.error('Failed to fetch project:', err)
  } finally {
    loading.value = false
  }
}, { immediate: true })

// Status configuration
const statusConfig: Record<string, { label: string; icon: typeof Circle; color: string; bgColor: string }> = {
  backlog: { label: 'Backlog', icon: Circle, color: 'text-gray-400', bgColor: 'bg-gray-400' },
  planned: { label: 'Planned', icon: Circle, color: 'text-blue-400', bgColor: 'bg-blue-400' },
  started: { label: 'Started', icon: Clock, color: 'text-yellow-500', bgColor: 'bg-yellow-500' },
  paused: { label: 'Paused', icon: PauseCircle, color: 'text-orange-500', bgColor: 'bg-orange-500' },
  completed: { label: 'Completed', icon: CheckCircle2, color: 'text-green-500', bgColor: 'bg-green-500' },
  canceled: { label: 'Canceled', icon: XCircle, color: 'text-red-400', bgColor: 'bg-red-400' }
}

// Health configuration
const healthConfig: Record<string, { label: string; color: string; bgColor: string }> = {
  onTrack: { label: 'On Track', color: 'text-green-400', bgColor: 'bg-green-500' },
  atRisk: { label: 'At Risk', color: 'text-yellow-400', bgColor: 'bg-yellow-500' },
  offTrack: { label: 'Off Track', color: 'text-red-400', bgColor: 'bg-red-500' }
}

// Format date
function formatDate(dateStr?: string): string {
  if (!dateStr) return ''
  const date = new Date(dateStr)
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}

// Navigate to full project page
function goToProject() {
  if (project.value) {
    router.push(`/project/${project.value.slug}`)
  }
}

// Get user initials
function getInitials(name: string): string {
  return name
    .split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
}

// Get user color
function getUserColor(name: string): string {
  const colors = ['#6366f1', '#8b5cf6', '#ec4899', '#f43f5e', '#f97316', '#eab308', '#22c55e', '#14b8a6', '#06b6d4', '#3b82f6']
  let hash = 0
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash)
  }
  return colors[Math.abs(hash) % colors.length]
}

// Computed
const projectStatus = computed(() => {
  const state = project.value?.state || 'backlog'
  return statusConfig[state] || statusConfig.backlog
})

const projectHealth = computed(() => {
  const health = project.value?.health
  if (!health) return null
  return healthConfig[health]
})

const projectMembers = computed(() => {
  return (project.value as DetailedProject)?.members || []
})

const projectTeams = computed(() => {
  return project.value?.teams || []
})
</script>

<template>
  <div class="w-[380px] h-full flex flex-col bg-[#0d0d0d] border-l border-[#1f1f1f]">
    <!-- Loading state -->
    <div v-if="loading && !project" class="flex-1 flex items-center justify-center">
      <div class="animate-spin rounded-full h-6 w-6 border-2 border-indigo-500 border-t-transparent"></div>
    </div>

    <!-- No project selected -->
    <div v-else-if="!project" class="flex-1 flex items-center justify-center text-gray-500 text-sm">
      Select a project to view details
    </div>

    <!-- Project details -->
    <template v-else>
      <!-- Header -->
      <div class="flex items-start gap-3 p-4 border-b border-[#1f1f1f]">
        <!-- Project icon -->
        <div 
          class="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0"
          :style="hasEmoji(project.icon) ? {} : { backgroundColor: project.color || '#6366f1' }"
        >
          <EmojiIcon 
            :name="project.icon" 
            :fallback="project.name.charAt(0)" 
            size="md"
          />
        </div>

        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-2">
            <h2 class="text-[15px] font-medium text-white truncate">{{ project.name }}</h2>
            <button 
              @click="goToProject"
              class="p-1 hover:bg-[#1a1a1a] rounded transition-colors"
              title="Open project"
            >
              <ExternalLink class="w-3.5 h-3.5 text-gray-500" />
            </button>
          </div>
          <p v-if="project.description" class="text-[13px] text-gray-400 mt-0.5 line-clamp-2">
            {{ project.description }}
          </p>
        </div>

        <!-- Actions -->
        <div class="flex items-center gap-1 flex-shrink-0">
          <button 
            @click="emit('close')"
            class="p-1.5 hover:bg-[#1a1a1a] rounded transition-colors"
          >
            <X class="w-4 h-4 text-gray-500" />
          </button>
        </div>
      </div>

      <!-- Content -->
      <div class="flex-1 overflow-auto">
        <!-- Properties section -->
        <div class="border-b border-[#1f1f1f]">
          <button 
            @click="showProperties = !showProperties"
            class="w-full flex items-center justify-between px-4 py-2.5 hover:bg-[#1a1a1a] transition-colors"
          >
            <span class="text-[13px] font-medium text-gray-400">Properties</span>
            <div class="flex items-center gap-2">
              <Plus class="w-3.5 h-3.5 text-gray-500" />
              <ChevronDown 
                :class="cn(
                  'w-4 h-4 text-gray-500 transition-transform',
                  !showProperties && '-rotate-90'
                )"
              />
            </div>
          </button>

          <div v-if="showProperties" class="px-4 pb-4 space-y-3">
            <!-- Status -->
            <div class="flex items-center justify-between">
              <span class="text-[13px] text-gray-500 w-24">Status</span>
              <div class="flex items-center gap-1.5">
                <component 
                  :is="projectStatus.icon" 
                  :class="cn('w-4 h-4', projectStatus.color)"
                />
                <span class="text-[13px] text-white">{{ projectStatus.label }}</span>
              </div>
            </div>

            <!-- Health -->
            <div v-if="projectHealth" class="flex items-center justify-between">
              <span class="text-[13px] text-gray-500 w-24">Health</span>
              <div class="flex items-center gap-1.5">
                <div 
                  class="w-2 h-2 rounded-full"
                  :class="projectHealth.bgColor"
                />
                <span class="text-[13px] text-white">{{ projectHealth.label }}</span>
              </div>
            </div>

            <!-- Priority -->
            <div class="flex items-center justify-between">
              <span class="text-[13px] text-gray-500 w-24">Priority</span>
              <span class="text-[13px] text-gray-400">--- No priority</span>
            </div>

            <!-- Lead -->
            <div class="flex items-center justify-between">
              <span class="text-[13px] text-gray-500 w-24">Lead</span>
              <UserLink
                v-if="project.lead"
                :userId="project.lead.id"
                :name="project.lead.name"
                :displayName="project.lead.displayName"
                :avatarUrl="project.lead.avatarUrl"
                avatarSize="xs"
                class="text-[13px] text-white"
              />
              <span v-else class="text-[13px] text-gray-400">No lead</span>
            </div>

            <!-- Members -->
            <div class="flex items-center justify-between">
              <span class="text-[13px] text-gray-500 w-24">Members</span>
              <div v-if="projectMembers.length > 0" class="flex items-center gap-1">
                <div class="flex -space-x-1">
                  <UserLink
                    v-for="member in projectMembers.slice(0, 3)" 
                    :key="member.id"
                    :userId="member.id"
                    :name="member.name"
                    :avatarUrl="member.avatarUrl"
                    :showName="false"
                    avatarSize="xs"
                    class="border border-[#0d0d0d] rounded-full"
                  />
                </div>
                <span v-if="projectMembers.length > 3" class="text-[12px] text-gray-400">
                  +{{ projectMembers.length - 3 }}
                </span>
              </div>
              <span v-else class="text-[13px] text-gray-400">No members</span>
            </div>

            <!-- Dates -->
            <div class="flex items-center justify-between">
              <span class="text-[13px] text-gray-500 w-24">Dates</span>
              <div class="text-[13px]">
                <div v-if="project.startDate || project.targetDate" class="flex flex-col items-end gap-0.5">
                  <div v-if="project.startDate" class="flex items-center gap-1.5">
                    <Calendar class="w-3.5 h-3.5 text-gray-500" />
                    <span class="text-white">{{ formatDate(project.startDate) }}</span>
                  </div>
                  <div v-if="project.targetDate" class="flex items-center gap-1.5">
                    <Calendar class="w-3.5 h-3.5 text-gray-500" />
                    <span class="text-white">{{ formatDate(project.targetDate) }}</span>
                  </div>
                </div>
                <span v-else class="text-gray-400">No dates set</span>
              </div>
            </div>

            <!-- Teams -->
            <div class="flex items-center justify-between">
              <span class="text-[13px] text-gray-500 w-24">Teams</span>
              <div v-if="projectTeams.length > 0" class="flex items-center gap-1.5">
                <div 
                  v-for="team in projectTeams.slice(0, 2)"
                  :key="team.id"
                  class="flex items-center gap-1.5 px-2 py-0.5 bg-[#1a1a1a] rounded"
                >
                  <div 
                    class="w-4 h-4 rounded flex items-center justify-center"
                    :style="hasEmoji(team.icon) ? {} : { backgroundColor: team.color || '#6366f1' }"
                  >
                    <EmojiIcon 
                      :name="team.icon" 
                      :fallback="team.key.substring(0, 2)" 
                      size="xs"
                    />
                  </div>
                  <span class="text-[12px] text-white">{{ team.name }}</span>
                </div>
                <span v-if="projectTeams.length > 2" class="text-[12px] text-gray-400">
                  +{{ projectTeams.length - 2 }}
                </span>
              </div>
              <span v-else class="text-[13px] text-gray-400">No teams</span>
            </div>

            <!-- Initiatives -->
            <div class="flex items-center justify-between">
              <span class="text-[13px] text-gray-500 w-24">Initiatives</span>
              <span class="text-[13px] text-gray-400">No initiative</span>
            </div>

            <!-- Labels -->
            <div class="flex items-center justify-between">
              <span class="text-[13px] text-gray-500 w-24">Labels</span>
              <span class="text-[13px] text-gray-400">No labels</span>
            </div>
          </div>
        </div>

        <!-- Milestones section -->
        <div class="border-b border-[#1f1f1f]">
          <button 
            @click="showMilestones = !showMilestones"
            class="w-full flex items-center justify-between px-4 py-2.5 hover:bg-[#1a1a1a] transition-colors"
          >
            <span class="text-[13px] font-medium text-gray-400">Milestones</span>
            <div class="flex items-center gap-2">
              <Plus class="w-3.5 h-3.5 text-gray-500" />
              <ChevronDown 
                :class="cn(
                  'w-4 h-4 text-gray-500 transition-transform',
                  !showMilestones && '-rotate-90'
                )"
              />
            </div>
          </button>

          <div v-if="showMilestones" class="px-4 pb-4">
            <div class="text-[13px] text-gray-500 text-center py-4">
              No milestones yet
            </div>
          </div>
        </div>

        <!-- Progress section -->
        <div>
          <button 
            @click="showProgress = !showProgress"
            class="w-full flex items-center justify-between px-4 py-2.5 hover:bg-[#1a1a1a] transition-colors"
          >
            <span class="text-[13px] font-medium text-gray-400">Progress</span>
            <ChevronDown 
              :class="cn(
                'w-4 h-4 text-gray-500 transition-transform',
                !showProgress && '-rotate-90'
              )"
            />
          </button>

          <div v-if="showProgress" class="px-4 pb-4">
            <div class="space-y-3">
              <!-- Progress stats -->
              <div class="grid grid-cols-3 gap-3">
                <div class="text-center">
                  <div class="text-[11px] text-gray-500 mb-1">Scope</div>
                  <div class="flex items-center justify-center gap-1">
                    <Target class="w-3.5 h-3.5 text-gray-400" />
                    <span class="text-[13px] text-white font-medium">0</span>
                  </div>
                </div>
                <div class="text-center">
                  <div class="text-[11px] text-gray-500 mb-1">Started</div>
                  <div class="flex items-center justify-center gap-1">
                    <div class="w-2 h-2 rounded-full bg-yellow-500" />
                    <span class="text-[13px] text-white font-medium">0</span>
                  </div>
                </div>
                <div class="text-center">
                  <div class="text-[11px] text-gray-500 mb-1">Completed</div>
                  <div class="flex items-center justify-center gap-1">
                    <div class="w-2 h-2 rounded-full bg-green-500" />
                    <span class="text-[13px] text-white font-medium">0</span>
                  </div>
                </div>
              </div>

              <!-- Progress bar -->
              <div>
                <div class="flex items-center justify-between mb-1.5">
                  <span class="text-[12px] text-gray-500">Progress</span>
                  <span class="text-[12px] text-white">{{ Math.round(project.progress || 0) }}%</span>
                </div>
                <div class="h-2 bg-[#1f1f1f] rounded-full overflow-hidden">
                  <div 
                    class="h-full bg-indigo-500 rounded-full transition-all duration-300"
                    :style="{ width: `${project.progress || 0}%` }"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
