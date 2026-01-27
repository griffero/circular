<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '@/api/client'
import { useEmojiStore } from '@/stores/emoji'
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
  AlertTriangle
} from 'lucide-vue-next'

const router = useRouter()
const emojiStore = useEmojiStore()

// Types
interface Project {
  id: string
  name: string
  slug: string
  icon?: string
  color?: string
  state?: string
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
  target_year?: number
  target_quarter?: number
  target_display?: string
  sort_order: number
  owner?: User
  projects: Project[]
  projects_progress: { completed: number; total: number }
}

// State
const initiatives = ref<Initiative[]>([])
const loading = ref(true)
const activeFilter = ref<'all' | 'active' | 'planned' | 'completed'>('all')
const expandedGroups = ref<Set<string>>(new Set())

// Fetch initiatives
async function fetchInitiatives() {
  loading.value = true
  try {
    const data = await api.get<{ initiatives: Initiative[] }>('/api/v1/initiatives')
    initiatives.value = data.initiatives
    
    // Auto-expand groups that have initiatives
    const groups = new Set<string>()
    data.initiatives.forEach(init => {
      // Group by first project's team or by initiative name first letter
      if (init.projects.length > 0) {
        // Use first project as grouping hint (we'll group by parent initiative or category later)
      }
      groups.add(getGroupKey(init))
    })
    expandedGroups.value = groups
  } catch (err) {
    console.error('Failed to fetch initiatives:', err)
  } finally {
    loading.value = false
  }
}

// Filter initiatives
const filteredInitiatives = computed(() => {
  let result = initiatives.value
  
  if (activeFilter.value === 'active') {
    result = result.filter(i => i.status === 'started')
  } else if (activeFilter.value === 'planned') {
    result = result.filter(i => i.status === 'planned')
  } else if (activeFilter.value === 'completed') {
    result = result.filter(i => i.status === 'completed')
  }
  
  return result
})

// Group initiatives by some criteria (we'll use a simple grouping for now)
function getGroupKey(initiative: Initiative): string {
  // For simplicity, return a fixed group or first letter
  // In a real implementation, this could be by team or category
  return 'All Initiatives'
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
  
  return groups
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
function getHealthDisplay(health?: string) {
  switch (health) {
    case 'onTrack':
      return { label: 'On track', class: 'text-green-400', icon: TrendingUp }
    case 'atRisk':
      return { label: 'At risk', class: 'text-yellow-400', icon: AlertTriangle }
    case 'offTrack':
      return { label: 'Off track', class: 'text-red-400', icon: TrendingDown }
    default:
      return { label: 'No updates', class: 'text-gray-500', icon: Circle }
  }
}

// Get status icon
function getStatusIcon(status: string) {
  switch (status) {
    case 'completed':
      return { icon: CheckCircle2, class: 'text-green-500' }
    case 'started':
      return { icon: Clock, class: 'text-yellow-500' }
    case 'planned':
      return { icon: Circle, class: 'text-blue-400' }
    default:
      return { icon: Circle, class: 'text-gray-500' }
  }
}

// Navigate to initiative detail (future)
function goToInitiative(initiative: Initiative) {
  // For now, just log - could open a detail panel
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
        <span class="text-[15px] font-medium text-white mr-2">Initiatives</span>
        
        <!-- Filter tabs -->
        <button 
          @click="activeFilter = 'all'"
          :class="[
            'flex items-center gap-1.5 px-2.5 py-1 text-[13px] rounded-md transition-colors',
            activeFilter === 'all' 
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
        <button class="flex items-center gap-1.5 px-2.5 py-1.5 text-[13px] text-white bg-[#5e6ad2] hover:bg-[#6872d9] rounded-md transition-colors">
          <Plus class="w-4 h-4" />
          New initiative
        </button>
      </div>
    </div>
    
    <!-- Secondary toolbar -->
    <div class="flex items-center justify-between px-4 py-1.5 border-b border-[#1f1f1f]">
      <button class="flex items-center gap-1.5 px-2 py-1 text-[13px] text-gray-400 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors">
        <Filter class="w-3.5 h-3.5" />
        Filter
      </button>
      
      <button class="flex items-center gap-1.5 px-2 py-1 text-[13px] text-gray-400 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors">
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
        <button class="flex items-center gap-2 px-4 py-2 bg-[#5e6ad2] hover:bg-[#6872d9] text-white text-sm rounded-lg transition-colors">
          <Plus class="w-4 h-4" />
          Create initiative
        </button>
      </div>
      
      <!-- Initiatives table -->
      <div v-else>
        <!-- Table header -->
        <div class="flex items-center px-4 py-2 border-b border-[#1f1f1f] text-[11px] text-gray-500 uppercase tracking-wider">
          <div class="flex-1 min-w-0">Name</div>
          <div class="w-20 text-center">Owner</div>
          <div class="w-24 text-center">Target</div>
          <div class="w-20 text-center">Projects</div>
          <div class="w-32 text-center">Initiative Health</div>
          <div class="w-20 text-center">Activity</div>
        </div>
        
        <!-- Grouped initiatives -->
        <div v-for="(groupInitiatives, groupKey) in groupedInitiatives" :key="groupKey">
          <!-- Group header (optional, can be removed if only one group) -->
          <!--
          <button
            @click="toggleGroup(groupKey)"
            class="w-full flex items-center gap-2 px-4 py-2 text-[13px] text-gray-400 hover:bg-[#151515] border-b border-[#1f1f1f]"
          >
            <ChevronRight 
              :class="['w-4 h-4 transition-transform', expandedGroups.has(groupKey) && 'rotate-90']" 
            />
            <span>{{ groupKey }}</span>
          </button>
          -->
          
          <!-- Initiative rows -->
          <div v-if="expandedGroups.has(groupKey) || true">
            <div
              v-for="initiative in groupInitiatives"
              :key="initiative.id"
              @click="goToInitiative(initiative)"
              class="flex items-center px-4 py-3 hover:bg-[#151515] cursor-pointer border-b border-[#151515] group"
            >
              <!-- Name column -->
              <div class="flex-1 min-w-0 flex items-start gap-3">
                <!-- Icon -->
                <div 
                  class="w-6 h-6 rounded flex-shrink-0 flex items-center justify-center text-[11px] font-medium mt-0.5"
                  :style="hasEmoji(initiative.icon) ? {} : { backgroundColor: initiative.color || '#5e6ad2' }"
                >
                  <EmojiIcon 
                    :name="initiative.icon" 
                    :fallback="initiative.name.charAt(0).toUpperCase()" 
                    size="sm"
                  />
                </div>
                
                <!-- Name and description -->
                <div class="min-w-0">
                  <div class="flex items-center gap-2">
                    <component 
                      :is="getStatusIcon(initiative.status).icon" 
                      class="w-4 h-4 flex-shrink-0" 
                      :class="getStatusIcon(initiative.status).class"
                    />
                    <span class="text-[13px] text-white truncate">{{ initiative.name }}</span>
                  </div>
                  <p v-if="initiative.description" class="text-[12px] text-gray-500 truncate mt-0.5 ml-6">
                    {{ initiative.description }}
                  </p>
                </div>
              </div>
              
              <!-- Owner column -->
              <div class="w-20 flex justify-center">
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
              <div class="w-24 text-center">
                <span v-if="initiative.target_display" class="text-[13px] text-gray-400">
                  {{ initiative.target_display }}
                </span>
                <span v-else class="text-[13px] text-gray-600">—</span>
              </div>
              
              <!-- Projects column -->
              <div class="w-20 flex items-center justify-center gap-1">
                <CheckCircle2 class="w-3.5 h-3.5 text-green-500" />
                <span class="text-[13px] text-gray-400">
                  {{ initiative.projects_progress.completed }} / {{ initiative.projects_progress.total }}
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
              <div class="w-20 flex justify-center">
                <Minus class="w-4 h-4 text-gray-600" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
