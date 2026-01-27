<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '@/api/client'
import { useEmojiStore } from '@/stores/emoji'
import { useUiStore } from '@/stores/ui'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
import Avatar from '@/components/ui/Avatar.vue'
import UserLink from '@/components/ui/UserLink.vue'
import {
  Lightbulb,
  Plus,
  Filter,
  Settings2,
  ChevronDown,
  ChevronRight,
  Circle,
  CheckCircle2,
  Clock,
  Minus,
  TrendingUp,
  TrendingDown,
  AlertTriangle,
  ChevronsUp,
  ChevronsDown,
  X
} from 'lucide-vue-next'
import Dropdown from '@/components/ui/Dropdown.vue'
import DropdownItem from '@/components/ui/DropdownItem.vue'

const router = useRouter()
const emojiStore = useEmojiStore()
const uiStore = useUiStore()

// Types
interface Project {
  id: string
  name: string
  slug: string
  icon?: string
  color?: string
  state?: string
  teams?: { id: string; name: string; key: string }[]
}

interface User {
  id: string
  name: string
  email: string
  avatarUrl?: string
}

interface Initiative {
  id: string
  name: string
  slug: string
  description?: string
  icon?: string
  color?: string
  status: string
  health?: string
  targetYear?: number
  targetQuarter?: number
  targetDisplay?: string
  sortOrder: number
  owner?: User
  projects: Project[]
  projectsProgress: { completed: number; total: number }
}

// State
const initiatives = ref<Initiative[]>([])
const loading = ref(true)
const activeFilter = ref<'active' | 'planned' | 'completed'>('active')
const expandedGroups = ref<Set<string>>(new Set())

// Additional filters
const healthFilter = ref<string | null>(null)
const ownerFilter = ref<string | null>(null)

// Health options
const healthOptions = [
  { value: 'onTrack', label: 'On Track', color: 'text-green-500' },
  { value: 'atRisk', label: 'At Risk', color: 'text-yellow-500' },
  { value: 'offTrack', label: 'Off Track', color: 'text-red-500' },
]

// Get unique owners from initiatives
const uniqueOwners = computed(() => {
  const owners = new Map<string, User>()
  initiatives.value.forEach(init => {
    if (init.owner) {
      owners.set(init.owner.id, init.owner)
    }
  })
  return Array.from(owners.values())
})

// Check if additional filters are active
const hasAdditionalFilters = computed(() => healthFilter.value !== null || ownerFilter.value !== null)
const additionalFiltersCount = computed(() => {
  let count = 0
  if (healthFilter.value) count++
  if (ownerFilter.value) count++
  return count
})

// Clear additional filters
function clearAdditionalFilters() {
  healthFilter.value = null
  ownerFilter.value = null
}

// Fetch initiatives
async function fetchInitiatives() {
  loading.value = true
  try {
    const data = await api.get<{ initiatives: Initiative[] }>('/api/v1/initiatives')
    console.log('Initiatives API response:', data)
    console.log('Initiatives count:', data.initiatives?.length)
    initiatives.value = data.initiatives || []
    
    // Auto-expand all groups
    const groups = new Set<string>()
    initiatives.value.forEach(init => {
      groups.add(getGroupKey(init))
    })
    expandedGroups.value = groups
  } catch (err) {
    console.error('Failed to fetch initiatives:', err)
  } finally {
    loading.value = false
  }
}

// Filter initiatives - "active" includes started AND planned (like Linear)
const filteredInitiatives = computed(() => {
  let result = initiatives.value
  
  // Tab filter
  if (activeFilter.value === 'active') {
    // Active = started or planned (not completed, not canceled)
    result = result.filter(i => i.status === 'started' || i.status === 'planned' || i.status === 'backlog')
  } else if (activeFilter.value === 'planned') {
    result = result.filter(i => i.status === 'planned' || i.status === 'backlog')
  } else if (activeFilter.value === 'completed') {
    result = result.filter(i => i.status === 'completed')
  }
  
  // Health filter
  if (healthFilter.value) {
    result = result.filter(i => i.health === healthFilter.value)
  }
  
  // Owner filter
  if (ownerFilter.value) {
    result = result.filter(i => i.owner?.id === ownerFilter.value)
  }
  
  return result
})

// Group initiatives by first project's team name, or by a category
function getGroupKey(initiative: Initiative): string {
  // Try to get the team from the first project
  if (initiative.projects && initiative.projects.length > 0) {
    const firstProject = initiative.projects[0]
    if (firstProject.teams && firstProject.teams.length > 0) {
      return firstProject.teams[0].name
    }
  }
  // Fallback to a generic group
  return 'Other'
}

// Get group icon/color - try to derive from first initiative in group
function getGroupInfo(groupKey: string, initiatives: Initiative[]) {
  // Find first initiative that has an icon
  const firstWithIcon = initiatives.find(i => i.icon)
  return {
    icon: firstWithIcon?.icon,
    color: firstWithIcon?.color || '#6366f1'
  }
}

const groupedInitiatives = computed(() => {
  const groups: Record<string, Initiative[]> = {}
  
  filteredInitiatives.value.forEach(init => {
    const key = getGroupKey(init)
    if (!groups[key]) {
      groups[key] = []
    }
    groups[key].push(init)
  })
  
  // Sort groups alphabetically, but put "Other" last
  const sortedGroups: Record<string, Initiative[]> = {}
  const keys = Object.keys(groups).sort((a, b) => {
    if (a === 'Other') return 1
    if (b === 'Other') return -1
    return a.localeCompare(b)
  })
  
  keys.forEach(key => {
    sortedGroups[key] = groups[key]
  })
  
  return sortedGroups
})

// Check if emoji
function hasEmoji(icon?: string | null): boolean {
  if (!icon) return false
  if (emojiStore.getEmojiUrl(icon)) return true
  const stripped = icon.replace(/^:|:$/g, '')
  return /^[\p{Emoji}\u200d]+$/u.test(stripped) && stripped.length <= 8
}

// Toggle group expansion
function toggleGroup(key: string) {
  if (expandedGroups.value.has(key)) {
    expandedGroups.value.delete(key)
  } else {
    expandedGroups.value.add(key)
  }
}

// Get health display
function getHealthDisplay(health?: string, hasRecentUpdate?: boolean) {
  switch (health) {
    case 'onTrack':
      return { label: 'On track', class: 'text-green-400', icon: TrendingUp, dotClass: 'bg-green-500' }
    case 'atRisk':
      return { label: 'At risk', class: 'text-yellow-400', icon: AlertTriangle, dotClass: 'bg-yellow-500' }
    case 'offTrack':
      return { label: 'Off track', class: 'text-red-400', icon: TrendingDown, dotClass: 'bg-red-500' }
    default:
      return { label: 'No updates', class: 'text-gray-500', icon: Circle, dotClass: 'bg-gray-600' }
  }
}

// Get status icon
function getStatusIcon(status: string) {
  switch (status) {
    case 'completed':
      return { icon: CheckCircle2, class: 'text-green-500' }
    case 'started':
      return { icon: Circle, class: 'text-yellow-500', filled: true }
    case 'planned':
      return { icon: Circle, class: 'text-blue-400' }
    default:
      return { icon: Circle, class: 'text-gray-500' }
  }
}

// Navigate to initiative detail (future)
function goToInitiative(initiative: Initiative) {
  console.log('Navigate to initiative:', initiative.slug)
}

onMounted(() => {
  fetchInitiatives()
})
</script>

<template>
  <div class="h-full flex flex-col bg-[#0d0d0d]">
    <!-- Header -->
    <div class="flex items-center justify-between px-4 py-2 border-b border-[#1f1f1f]">
      <div class="flex items-center gap-1">
        <span class="text-[15px] font-medium text-white mr-3">Initiatives</span>
        
        <!-- Filter tabs -->
        <button 
          @click="activeFilter = 'active'"
          :class="[
            'flex items-center gap-1.5 px-2.5 py-1 text-[13px] rounded-md transition-colors',
            activeFilter === 'active' 
              ? 'bg-[#2a2a2a] text-white' 
              : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
          ]"
        >
          <Lightbulb class="w-4 h-4" />
          Active
        </button>
        <button 
          @click="activeFilter = 'planned'"
          :class="[
            'flex items-center gap-1.5 px-2.5 py-1 text-[13px] rounded-md transition-colors',
            activeFilter === 'planned' 
              ? 'bg-[#2a2a2a] text-white' 
              : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
          ]"
        >
          <Circle class="w-4 h-4" />
          Planned
        </button>
        <button 
          @click="activeFilter = 'completed'"
          :class="[
            'flex items-center gap-1.5 px-2.5 py-1 text-[13px] rounded-md transition-colors',
            activeFilter === 'completed' 
              ? 'bg-[#2a2a2a] text-white' 
              : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
          ]"
        >
          <CheckCircle2 class="w-4 h-4" />
          Completed
        </button>
      </div>
      
      <div class="flex items-center gap-2">
        <button 
          @click="uiStore.openCreateInitiativeModal()"
          class="flex items-center gap-1.5 px-2.5 py-1.5 text-[13px] text-white bg-[#5e6ad2] hover:bg-[#6872d9] rounded-md transition-colors"
        >
          <Plus class="w-4 h-4" />
          New initiative
        </button>
      </div>
    </div>
    
    <!-- Secondary toolbar -->
    <div class="flex items-center justify-between px-4 py-1.5 border-b border-[#1f1f1f]">
      <div class="flex items-center gap-2">
        <!-- Filter dropdown -->
        <Dropdown align="left">
          <template #trigger>
            <button 
              :class="[
                'flex items-center gap-1.5 px-2 py-1 text-[13px] rounded transition-colors',
                hasAdditionalFilters
                  ? 'bg-indigo-500/20 text-indigo-400 border border-indigo-500/30'
                  : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
              ]"
            >
              <Filter class="w-3.5 h-3.5" />
              Filter
              <span v-if="hasAdditionalFilters" class="text-[11px] bg-indigo-500/30 px-1.5 rounded">
                {{ additionalFiltersCount }}
              </span>
            </button>
          </template>
          
          <div class="p-2 min-w-[180px]">
            <div class="text-[11px] font-medium text-gray-500 uppercase tracking-wider px-2 mb-1">Health</div>
            <DropdownItem 
              v-for="health in healthOptions" 
              :key="health.value"
              @click="healthFilter = healthFilter === health.value ? null : health.value"
            >
              <div class="flex items-center justify-between w-full">
                <span :class="health.color">{{ health.label }}</span>
                <CheckCircle2 v-if="healthFilter === health.value" class="w-4 h-4 text-indigo-400" />
              </div>
            </DropdownItem>
            
            <template v-if="uniqueOwners.length > 0">
              <div class="border-t border-[#2a2a2a] my-2"></div>
              <div class="text-[11px] font-medium text-gray-500 uppercase tracking-wider px-2 mb-1">Owner</div>
              <DropdownItem 
                v-for="owner in uniqueOwners" 
                :key="owner.id"
                @click="ownerFilter = ownerFilter === owner.id ? null : owner.id"
              >
                <div class="flex items-center justify-between w-full">
                  <div class="flex items-center gap-2">
                    <Avatar :src="owner.avatarUrl" :name="owner.name" size="xs" />
                    <span>{{ owner.name }}</span>
                  </div>
                  <CheckCircle2 v-if="ownerFilter === owner.id" class="w-4 h-4 text-indigo-400" />
                </div>
              </DropdownItem>
            </template>
            
            <template v-if="hasAdditionalFilters">
              <div class="border-t border-[#2a2a2a] my-2"></div>
              <DropdownItem @click="clearAdditionalFilters" class="text-red-400">
                <X class="w-4 h-4" />
                Clear filters
              </DropdownItem>
            </template>
          </div>
        </Dropdown>
        
        <!-- Active filter pills -->
        <button
          v-if="healthFilter"
          @click="healthFilter = null"
          class="flex items-center gap-1.5 px-2 py-0.5 bg-[#1a1a1a] hover:bg-[#252525] rounded text-[12px] text-gray-300 transition-colors"
        >
          Health: {{ healthOptions.find(h => h.value === healthFilter)?.label }}
          <X class="w-3 h-3" />
        </button>
        <button
          v-if="ownerFilter"
          @click="ownerFilter = null"
          class="flex items-center gap-1.5 px-2 py-0.5 bg-[#1a1a1a] hover:bg-[#252525] rounded text-[12px] text-gray-300 transition-colors"
        >
          Owner: {{ uniqueOwners.find(o => o.id === ownerFilter)?.name }}
          <X class="w-3 h-3" />
        </button>
      </div>
      
      <button 
        title="Display options (coming soon)"
        class="flex items-center gap-1.5 px-2 py-1 text-[13px] text-gray-400 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors opacity-60 cursor-not-allowed"
      >
        <Settings2 class="w-3.5 h-3.5" />
        Display
      </button>
    </div>
    
    <!-- Content -->
    <div class="flex-1 overflow-auto">
      <!-- Loading state -->
      <div v-if="loading" class="flex items-center justify-center py-12">
        <div class="animate-spin rounded-full h-8 w-8 border-2 border-indigo-600 border-t-transparent"></div>
      </div>
      
      <!-- Empty state -->
      <div 
        v-else-if="filteredInitiatives.length === 0" 
        class="flex-1 flex flex-col items-center justify-center py-20"
      >
        <div class="w-16 h-16 rounded-full bg-[#1a1a1a] flex items-center justify-center mb-4">
          <Lightbulb class="w-8 h-8 text-gray-500" />
        </div>
        <h2 class="text-lg font-medium text-white mb-2">No initiatives yet</h2>
        <p class="text-sm text-gray-500 text-center max-w-sm mb-4">
          Initiatives help you track larger goals across multiple projects and teams.
        </p>
        <button 
          @click="uiStore.openCreateInitiativeModal()"
          class="flex items-center gap-2 px-4 py-2 bg-[#5e6ad2] hover:bg-[#6872d9] text-white text-sm rounded-lg transition-colors"
        >
          <Plus class="w-4 h-4" />
          Create initiative
        </button>
      </div>
      
      <!-- Initiatives table -->
      <div v-else>
        <!-- Table header -->
        <div class="sticky top-0 bg-[#0d0d0d] z-10 flex items-center px-4 py-2 border-b border-[#1f1f1f] text-[11px] text-gray-500 uppercase tracking-wider">
          <div class="flex-1 min-w-0 pl-7">Name</div>
          <div class="w-16 text-center">Owner</div>
          <div class="w-20 text-center">Target</div>
          <div class="w-20 text-center">Projects</div>
          <div class="w-32 text-center">Initiative Health</div>
          <div class="w-16 text-center">Activity</div>
        </div>
        
        <!-- Grouped initiatives -->
        <div v-for="(groupInits, groupKey) in groupedInitiatives" :key="groupKey">
          <!-- Group header -->
          <button
            @click="toggleGroup(groupKey)"
            class="w-full flex items-center gap-2 px-4 py-2 text-[13px] hover:bg-[#151515] border-b border-[#1a1a1a] transition-colors"
          >
            <ChevronRight 
              :class="['w-4 h-4 text-gray-500 transition-transform', expandedGroups.has(groupKey) && 'rotate-90']" 
            />
            <!-- Group icon -->
            <div 
              class="w-5 h-5 rounded flex items-center justify-center text-[10px] font-medium"
              :style="{ backgroundColor: getGroupInfo(groupKey, groupInits).color }"
            >
              <EmojiIcon 
                v-if="getGroupInfo(groupKey, groupInits).icon"
                :name="getGroupInfo(groupKey, groupInits).icon" 
                :fallback="groupKey.charAt(0).toUpperCase()" 
                size="xs"
              />
              <span v-else class="text-white">{{ groupKey.charAt(0).toUpperCase() }}</span>
            </div>
            <span class="text-white font-medium">{{ groupKey }}</span>
          </button>
          
          <!-- Initiative rows -->
          <div v-if="expandedGroups.has(groupKey)">
            <div
              v-for="initiative in groupInits"
              :key="initiative.id"
              @click="goToInitiative(initiative)"
              class="flex items-center px-4 py-2.5 hover:bg-[#151515] cursor-pointer border-b border-[#151515]/50 group"
            >
              <!-- Name column -->
              <div class="flex-1 min-w-0 flex items-start gap-2 pl-7">
                <!-- Status icon -->
                <div class="w-5 h-5 flex-shrink-0 flex items-center justify-center mt-0.5">
                  <div 
                    v-if="initiative.status === 'started'"
                    class="w-4 h-4 rounded-full border-2 border-yellow-500"
                    style="background: radial-gradient(circle at center, #eab308 50%, transparent 50%);"
                  />
                  <component 
                    v-else
                    :is="getStatusIcon(initiative.status).icon" 
                    class="w-4 h-4" 
                    :class="getStatusIcon(initiative.status).class"
                  />
                </div>
                
                <!-- Name and description -->
                <div class="min-w-0 flex-1">
                  <span class="text-[13px] text-white block truncate">{{ initiative.name }}</span>
                  <p v-if="initiative.description" class="text-[12px] text-gray-500 truncate mt-0.5">
                    {{ initiative.description }}
                  </p>
                </div>
              </div>
              
              <!-- Owner column -->
              <div class="w-16 flex justify-center">
                <UserLink
                  v-if="initiative.owner"
                  :userId="initiative.owner.id"
                  :name="initiative.owner.name"
                  :avatarUrl="initiative.owner.avatarUrl"
                  :showName="false"
                  avatarSize="sm"
                />
                <div v-else class="w-6 h-6 rounded-full bg-[#2a2a2a]" />
              </div>
              
              <!-- Target column -->
              <div class="w-20 text-center">
                <span v-if="initiative.targetDisplay" class="text-[13px] text-gray-400">
                  {{ initiative.targetDisplay }}
                </span>
                <span v-else class="text-[13px] text-gray-600">—</span>
              </div>
              
              <!-- Projects column -->
              <div class="w-20 flex items-center justify-center gap-1">
                <CheckCircle2 class="w-3.5 h-3.5 text-blue-400" />
                <span class="text-[13px] text-gray-400">
                  {{ initiative.projectsProgress.completed }} / {{ initiative.projectsProgress.total }}
                </span>
              </div>
              
              <!-- Health column -->
              <div class="w-32 flex items-center justify-center gap-1.5">
                <component 
                  :is="getHealthDisplay(initiative.health).icon" 
                  class="w-3.5 h-3.5" 
                  :class="getHealthDisplay(initiative.health).class"
                />
                <span class="text-[12px]" :class="getHealthDisplay(initiative.health).class">
                  {{ getHealthDisplay(initiative.health).label }}
                </span>
              </div>
              
              <!-- Activity column -->
              <div class="w-16 flex justify-center">
                <ChevronsUp v-if="initiative.health === 'onTrack'" class="w-4 h-4 text-green-500" />
                <Minus v-else class="w-4 h-4 text-gray-600" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
