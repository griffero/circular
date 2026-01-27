<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { useAppStore } from '@/stores/app'
import { useEmojiStore } from '@/stores/emoji'
import { useUiStore } from '@/stores/ui'
import type { Project } from '@/types'
import { 
  ChevronLeft, 
  ChevronRight, 
  ZoomIn, 
  ZoomOut,
  Circle,
  CheckCircle2,
  XCircle,
  Minus,
  ArrowLeft,
  ArrowRight,
  Settings2,
  Filter,
  Link2,
  Plus,
  Check
} from 'lucide-vue-next'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
import Avatar from '@/components/ui/Avatar.vue'
import UserLink from '@/components/ui/UserLink.vue'
import Dropdown from '@/components/ui/Dropdown.vue'
import DropdownItem from '@/components/ui/DropdownItem.vue'

const emit = defineEmits<{
  (e: 'select-project', project: Project): void
}>()

const appStore = useAppStore()
const emojiStore = useEmojiStore()
const uiStore = useUiStore()

// Filter state
const activeFilter = ref<'all' | 'current' | 'mine'>('all')
const timeScale = ref<'year' | 'quarter' | 'month'>('year')

// Display options
const showHealth = ref(true)
const showLead = ref(true)
const showDates = ref(true)

// Advanced filters
const stateFilter = ref<string | null>(null)
const healthFilter = ref<string | null>(null)

// Check if a project has a valid emoji
function hasEmoji(icon?: string | null): boolean {
  if (!icon) return false
  if (emojiStore.getEmojiUrl(icon)) return true
  const stripped = icon.replace(/^:|:$/g, '')
  return /^[\p{Emoji}\u200d]+$/u.test(stripped) && stripped.length <= 8
}

// Refs
const timelineContainer = ref<HTMLElement | null>(null)
const timelineHeader = ref<HTMLElement | null>(null)
const timelineArea = ref<HTMLElement | null>(null)
const projectListRef = ref<HTMLElement | null>(null)

// Timeline configuration
const today = new Date()
const timelineStart = new Date(today.getFullYear() - 2, 0, 1)
const timelineEnd = new Date(today.getFullYear() + 2, 11, 31)

// Column width (pixels per day when scale is month, per week when quarter, per month when year)
const colWidth = ref(40)
const MIN_COL_WIDTH = 15
const MAX_COL_WIDTH = 100
const ZOOM_STEP = 5

// Zoom percentage display
const zoomPercent = computed(() => Math.round((colWidth.value / 40) * 100))

// Generate timeline columns based on scale
const timelineColumns = computed(() => {
  const columns: { date: Date; label: string; subLabel?: string; isYearStart?: boolean; isMonthStart?: boolean }[] = []
  const current = new Date(timelineStart)
  
  if (timeScale.value === 'year') {
    // Monthly columns
    while (current <= timelineEnd) {
      columns.push({
        date: new Date(current),
        label: current.toLocaleDateString('en-US', { month: 'short' }).toUpperCase(),
        subLabel: current.getDate().toString(),
        isYearStart: current.getMonth() === 0,
        isMonthStart: true
      })
      current.setMonth(current.getMonth() + 1)
    }
  } else if (timeScale.value === 'quarter') {
    // Weekly columns
    while (current <= timelineEnd) {
      const weekStart = new Date(current)
      columns.push({
        date: weekStart,
        label: weekStart.toLocaleDateString('en-US', { month: 'short' }).toUpperCase(),
        subLabel: weekStart.getDate().toString(),
        isYearStart: weekStart.getMonth() === 0 && weekStart.getDate() <= 7,
        isMonthStart: weekStart.getDate() <= 7
      })
      current.setDate(current.getDate() + 7)
    }
  } else {
    // Daily columns for month view
    while (current <= timelineEnd) {
      columns.push({
        date: new Date(current),
        label: current.getDate().toString(),
        subLabel: current.toLocaleDateString('en-US', { weekday: 'short' }).substring(0, 1),
        isYearStart: current.getMonth() === 0 && current.getDate() === 1,
        isMonthStart: current.getDate() === 1
      })
      current.setDate(current.getDate() + 1)
    }
  }
  
  return columns
})

// Group columns by year for header
const yearGroups = computed(() => {
  const groups: { year: number; startIdx: number; count: number }[] = []
  let currentYear = -1
  
  timelineColumns.value.forEach((col, idx) => {
    const year = col.date.getFullYear()
    if (year !== currentYear) {
      groups.push({ year, startIdx: idx, count: 1 })
      currentYear = year
    } else {
      groups[groups.length - 1].count++
    }
  })
  
  return groups
})

// Timeline width
const timelineWidth = computed(() => timelineColumns.value.length * colWidth.value)

// State priority for sorting
const statePriority: Record<string, number> = {
  started: 1,
  planned: 2,
  paused: 3,
  backlog: 4,
  completed: 5,
  canceled: 6
}

// Filtered and sorted projects
const filteredProjects = computed(() => {
  let projects = [...appStore.projects]
  
  if (activeFilter.value === 'current') {
    projects = projects.filter(p => p.state === 'started' || p.state === 'planned')
  } else if (activeFilter.value === 'mine') {
    const userId = appStore.currentUser?.id
    projects = projects.filter(p => p.leadId === userId)
  }
  
  // Apply advanced filters
  if (stateFilter.value) {
    projects = projects.filter(p => (p.state || 'backlog') === stateFilter.value)
  }
  if (healthFilter.value) {
    projects = projects.filter(p => p.health === healthFilter.value)
  }
  
  return projects.sort((a, b) => {
    const stateA = statePriority[a.state || 'backlog'] || 7
    const stateB = statePriority[b.state || 'backlog'] || 7
    if (stateA !== stateB) return stateA - stateB
    
    if (a.startDate && b.startDate) {
      return new Date(a.startDate).getTime() - new Date(b.startDate).getTime()
    } else if (a.startDate) return -1
    else if (b.startDate) return 1
    
    return a.name.localeCompare(b.name)
  })
})

// Clear all filters
function clearFilters() {
  stateFilter.value = null
  healthFilter.value = null
}

// Check if any filter is active
const hasActiveFilters = computed(() => stateFilter.value !== null || healthFilter.value !== null)

// Get date position as percentage
function getDatePosition(dateStr: string | undefined): number | null {
  if (!dateStr) return null
  const date = new Date(dateStr)
  if (isNaN(date.getTime())) return null
  
  const totalMs = timelineEnd.getTime() - timelineStart.getTime()
  const dateMs = date.getTime() - timelineStart.getTime()
  
  return (dateMs / totalMs) * 100
}

// Get bar position in pixels
function getBarPixelPosition(project: Project): { left: number; width: number } | null {
  if (!project.startDate && !project.targetDate) return null
  
  const startDate = project.startDate ? new Date(project.startDate) : null
  const endDate = project.targetDate ? new Date(project.targetDate) : null
  
  const totalMs = timelineEnd.getTime() - timelineStart.getTime()
  
  let leftPx: number
  let rightPx: number
  
  if (startDate && endDate) {
    leftPx = ((startDate.getTime() - timelineStart.getTime()) / totalMs) * timelineWidth.value
    rightPx = ((endDate.getTime() - timelineStart.getTime()) / totalMs) * timelineWidth.value
  } else if (startDate) {
    leftPx = ((startDate.getTime() - timelineStart.getTime()) / totalMs) * timelineWidth.value
    rightPx = leftPx + 100 // Default width
  } else if (endDate) {
    rightPx = ((endDate.getTime() - timelineStart.getTime()) / totalMs) * timelineWidth.value
    leftPx = rightPx - 100
  } else {
    return null
  }
  
  return {
    left: leftPx,
    width: Math.max(rightPx - leftPx, 20)
  }
}

// Check if project is before visible timeline
function isBeforeTimeline(project: Project): string | null {
  if (!project.startDate) return null
  const startDate = new Date(project.startDate)
  if (startDate < timelineStart) {
    return startDate.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })
  }
  return null
}

// Check if project is after visible timeline
function isAfterTimeline(project: Project): string | null {
  if (!project.targetDate) return null
  const endDate = new Date(project.targetDate)
  if (endDate > timelineEnd) {
    return endDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
  }
  return null
}

// Today indicator position
const todayPosition = computed(() => {
  const totalMs = timelineEnd.getTime() - timelineStart.getTime()
  const todayMs = today.getTime() - timelineStart.getTime()
  return (todayMs / totalMs) * 100
})

// Get state icon
function getStateIcon(state?: string) {
  switch (state) {
    case 'completed': return CheckCircle2
    case 'canceled': return XCircle
    default: return Circle
  }
}

function getStateIconColor(state?: string) {
  switch (state) {
    case 'completed': return 'text-green-500'
    case 'canceled': return 'text-red-500'
    case 'started': return 'text-yellow-500'
    case 'planned': return 'text-blue-400'
    default: return 'text-gray-600'
  }
}

// Get health color
function getHealthColor(health?: string) {
  switch (health) {
    case 'onTrack': return 'bg-green-500'
    case 'atRisk': return 'bg-yellow-500'
    case 'offTrack': return 'bg-red-500'
    default: return ''
  }
}

// Project click handler
function goToProject(project: Project) {
  emit('select-project', project)
}

// Scroll sync between project list and timeline
function onTimelineScroll(e: Event) {
  const target = e.target as HTMLElement
  if (timelineHeader.value) {
    timelineHeader.value.scrollLeft = target.scrollLeft
  }
}

function onProjectListScroll(e: Event) {
  const target = e.target as HTMLElement
  if (timelineContainer.value) {
    timelineContainer.value.scrollTop = target.scrollTop
  }
}

function onTimelineBodyScroll(e: Event) {
  const target = e.target as HTMLElement
  if (projectListRef.value) {
    projectListRef.value.scrollTop = target.scrollTop
  }
  if (timelineHeader.value) {
    timelineHeader.value.scrollLeft = target.scrollLeft
  }
}

// Wheel zoom handler
function handleWheel(e: WheelEvent) {
  if (!e.ctrlKey) return
  e.preventDefault()
  
  const zoomDelta = e.deltaY > 0 ? -ZOOM_STEP : ZOOM_STEP
  colWidth.value = Math.min(MAX_COL_WIDTH, Math.max(MIN_COL_WIDTH, colWidth.value + zoomDelta))
}

// Zoom controls
function zoomIn() {
  colWidth.value = Math.min(MAX_COL_WIDTH, colWidth.value + ZOOM_STEP)
}

function zoomOut() {
  colWidth.value = Math.max(MIN_COL_WIDTH, colWidth.value - ZOOM_STEP)
}

// Scroll to today
function scrollToToday() {
  if (!timelineContainer.value) return
  const containerWidth = timelineContainer.value.clientWidth
  const todayPx = (todayPosition.value / 100) * timelineWidth.value
  timelineContainer.value.scrollLeft = Math.max(0, todayPx - containerWidth / 3)
}

// Navigation
function navigateTimeline(direction: 'prev' | 'next') {
  if (!timelineContainer.value) return
  const amount = colWidth.value * 6
  timelineContainer.value.scrollBy({
    left: direction === 'next' ? amount : -amount,
    behavior: 'smooth'
  })
}

// Current visible date range for header
const currentDateLabel = computed(() => {
  return `${today.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })}`
})

// Mount
onMounted(async () => {
  await nextTick()
  scrollToToday()
  
  if (timelineArea.value) {
    timelineArea.value.addEventListener('wheel', handleWheel, { passive: false })
  }
})

onUnmounted(() => {
  if (timelineArea.value) {
    timelineArea.value.removeEventListener('wheel', handleWheel)
  }
})
</script>

<template>
  <div class="h-full flex flex-col bg-[#0d0d0d]">
    <!-- Header bar -->
    <div class="flex items-center justify-between px-4 py-2 border-b border-[#1f1f1f]">
      <div class="flex items-center gap-1">
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
          <FolderKanban class="w-4 h-4" />
          All projects
        </button>
        <button 
          @click="activeFilter = 'current'"
          :class="[
            'flex items-center gap-1.5 px-2.5 py-1 text-[13px] rounded-md transition-colors',
            activeFilter === 'current' 
              ? 'bg-[#2a2a2a] text-white' 
              : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
          ]"
        >
          <Circle class="w-4 h-4" />
          Current projects
        </button>
        <button 
          @click="activeFilter = 'mine'"
          :class="[
            'flex items-center gap-1.5 px-2.5 py-1 text-[13px] rounded-md transition-colors',
            activeFilter === 'mine' 
              ? 'bg-[#2a2a2a] text-white' 
              : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
          ]"
        >
          <User class="w-4 h-4" />
          My projects
        </button>
        <!-- Display options dropdown -->
        <Dropdown placement="bottom-start">
          <template #trigger>
            <button class="p-1.5 text-gray-500 hover:text-white hover:bg-[#1a1a1a] rounded-md transition-colors">
              <Settings2 class="w-4 h-4" />
            </button>
          </template>
          <template #content>
            <div class="py-1 min-w-[160px]">
              <div class="px-3 py-1.5 text-[11px] text-gray-500 uppercase tracking-wider">Show columns</div>
              <DropdownItem @click="showHealth = !showHealth">
                <div class="flex items-center justify-between w-full">
                  <span>Health</span>
                  <Check v-if="showHealth" class="w-4 h-4 text-indigo-400" />
                </div>
              </DropdownItem>
              <DropdownItem @click="showLead = !showLead">
                <div class="flex items-center justify-between w-full">
                  <span>Lead</span>
                  <Check v-if="showLead" class="w-4 h-4 text-indigo-400" />
                </div>
              </DropdownItem>
              <DropdownItem @click="showDates = !showDates">
                <div class="flex items-center justify-between w-full">
                  <span>Dates on bars</span>
                  <Check v-if="showDates" class="w-4 h-4 text-indigo-400" />
                </div>
              </DropdownItem>
            </div>
          </template>
        </Dropdown>
      </div>
      
      <div class="flex items-center gap-2">
        <button 
          @click="navigator.clipboard.writeText(window.location.href)"
          title="Copy link"
          class="p-1.5 text-gray-500 hover:text-white hover:bg-[#1a1a1a] rounded-md transition-colors"
        >
          <Link2 class="w-4 h-4" />
        </button>
        <button 
          @click="uiStore.openCreateProjectModal()"
          class="flex items-center gap-1.5 px-2.5 py-1.5 text-[13px] text-white bg-[#5e6ad2] hover:bg-[#6872d9] rounded-md transition-colors"
        >
          <Plus class="w-4 h-4" />
          Add project
        </button>
      </div>
    </div>
    
    <!-- Secondary toolbar -->
    <div class="flex items-center justify-between px-4 py-1.5 border-b border-[#1f1f1f]">
      <div class="flex items-center gap-2">
        <Dropdown placement="bottom-start">
          <template #trigger>
            <button 
              :class="[
                'flex items-center gap-1.5 px-2 py-1 text-[13px] rounded transition-colors',
                hasActiveFilters 
                  ? 'bg-indigo-600/20 text-indigo-400' 
                  : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
              ]"
            >
              <Filter class="w-3.5 h-3.5" />
              Filter
            </button>
          </template>
          <template #content>
            <div class="py-1 min-w-[180px]">
              <div class="px-3 py-1.5 text-[11px] text-gray-500 uppercase tracking-wider">Status</div>
              <DropdownItem @click="stateFilter = stateFilter === 'started' ? null : 'started'">
                <div class="flex items-center justify-between w-full">
                  <div class="flex items-center gap-2">
                    <div class="w-2 h-2 rounded-full bg-yellow-500"></div>
                    <span>Started</span>
                  </div>
                  <Check v-if="stateFilter === 'started'" class="w-4 h-4 text-indigo-400" />
                </div>
              </DropdownItem>
              <DropdownItem @click="stateFilter = stateFilter === 'planned' ? null : 'planned'">
                <div class="flex items-center justify-between w-full">
                  <div class="flex items-center gap-2">
                    <div class="w-2 h-2 rounded-full bg-blue-500"></div>
                    <span>Planned</span>
                  </div>
                  <Check v-if="stateFilter === 'planned'" class="w-4 h-4 text-indigo-400" />
                </div>
              </DropdownItem>
              <DropdownItem @click="stateFilter = stateFilter === 'completed' ? null : 'completed'">
                <div class="flex items-center justify-between w-full">
                  <div class="flex items-center gap-2">
                    <div class="w-2 h-2 rounded-full bg-green-500"></div>
                    <span>Completed</span>
                  </div>
                  <Check v-if="stateFilter === 'completed'" class="w-4 h-4 text-indigo-400" />
                </div>
              </DropdownItem>
              
              <div class="border-t border-[#2a2a2a] my-1"></div>
              <div class="px-3 py-1.5 text-[11px] text-gray-500 uppercase tracking-wider">Health</div>
              <DropdownItem @click="healthFilter = healthFilter === 'onTrack' ? null : 'onTrack'">
                <div class="flex items-center justify-between w-full">
                  <div class="flex items-center gap-2">
                    <div class="w-2 h-2 rounded-full bg-green-500"></div>
                    <span>On track</span>
                  </div>
                  <Check v-if="healthFilter === 'onTrack'" class="w-4 h-4 text-indigo-400" />
                </div>
              </DropdownItem>
              <DropdownItem @click="healthFilter = healthFilter === 'atRisk' ? null : 'atRisk'">
                <div class="flex items-center justify-between w-full">
                  <div class="flex items-center gap-2">
                    <div class="w-2 h-2 rounded-full bg-yellow-500"></div>
                    <span>At risk</span>
                  </div>
                  <Check v-if="healthFilter === 'atRisk'" class="w-4 h-4 text-indigo-400" />
                </div>
              </DropdownItem>
              <DropdownItem @click="healthFilter = healthFilter === 'offTrack' ? null : 'offTrack'">
                <div class="flex items-center justify-between w-full">
                  <div class="flex items-center gap-2">
                    <div class="w-2 h-2 rounded-full bg-red-500"></div>
                    <span>Off track</span>
                  </div>
                  <Check v-if="healthFilter === 'offTrack'" class="w-4 h-4 text-indigo-400" />
                </div>
              </DropdownItem>
              
              <template v-if="hasActiveFilters">
                <div class="border-t border-[#2a2a2a] my-1"></div>
                <DropdownItem @click="clearFilters" class="text-red-400">
                  Clear filters
                </DropdownItem>
              </template>
            </div>
          </template>
        </Dropdown>
        
        <!-- Active filter badges -->
        <div v-if="stateFilter" class="flex items-center gap-1 px-2 py-0.5 bg-[#1f1f1f] rounded text-[12px] text-gray-300">
          Status: {{ stateFilter }}
          <button @click="stateFilter = null" class="ml-1 text-gray-500 hover:text-white">&times;</button>
        </div>
        <div v-if="healthFilter" class="flex items-center gap-1 px-2 py-0.5 bg-[#1f1f1f] rounded text-[12px] text-gray-300">
          Health: {{ healthFilter }}
          <button @click="healthFilter = null" class="ml-1 text-gray-500 hover:text-white">&times;</button>
        </div>
      </div>
      
      <div class="flex items-center gap-2">
        <button 
          @click="scrollToToday"
          class="px-2.5 py-1 text-[13px] text-gray-300 bg-[#1f1f1f] hover:bg-[#2a2a2a] rounded transition-colors"
        >
          Today
        </button>
        
        <div class="flex items-center bg-[#1f1f1f] rounded">
          <button 
            @click="timeScale = 'year'"
            :class="[
              'px-2.5 py-1 text-[13px] rounded-l transition-colors',
              timeScale === 'year' ? 'bg-[#2a2a2a] text-white' : 'text-gray-400 hover:text-white'
            ]"
          >
            Year
          </button>
          <button 
            @click="timeScale = 'quarter'"
            :class="[
              'px-2.5 py-1 text-[13px] transition-colors',
              timeScale === 'quarter' ? 'bg-[#2a2a2a] text-white' : 'text-gray-400 hover:text-white'
            ]"
          >
            Quarter
          </button>
          <button 
            @click="timeScale = 'month'"
            :class="[
              'px-2.5 py-1 text-[13px] rounded-r transition-colors',
              timeScale === 'month' ? 'bg-[#2a2a2a] text-white' : 'text-gray-400 hover:text-white'
            ]"
          >
            Month
          </button>
        </div>
        
        <Dropdown placement="bottom-end">
          <template #trigger>
            <button class="flex items-center gap-1.5 px-2 py-1 text-[13px] text-gray-400 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors">
              <Settings2 class="w-3.5 h-3.5" />
              Display
            </button>
          </template>
          <template #content>
            <div class="py-1 min-w-[160px]">
              <div class="px-3 py-1.5 text-[11px] text-gray-500 uppercase tracking-wider">Options</div>
              <DropdownItem @click="showHealth = !showHealth">
                <div class="flex items-center justify-between w-full">
                  <span>Show health</span>
                  <Check v-if="showHealth" class="w-4 h-4 text-indigo-400" />
                </div>
              </DropdownItem>
              <DropdownItem @click="showLead = !showLead">
                <div class="flex items-center justify-between w-full">
                  <span>Show lead</span>
                  <Check v-if="showLead" class="w-4 h-4 text-indigo-400" />
                </div>
              </DropdownItem>
              <DropdownItem @click="showDates = !showDates">
                <div class="flex items-center justify-between w-full">
                  <span>Show dates</span>
                  <Check v-if="showDates" class="w-4 h-4 text-indigo-400" />
                </div>
              </DropdownItem>
            </div>
          </template>
        </Dropdown>
      </div>
    </div>
    
    <!-- Main content -->
    <div class="flex-1 flex overflow-hidden">
      <!-- Project list sidebar -->
      <div class="w-[280px] flex-shrink-0 border-r border-[#1f1f1f] flex flex-col">
        <!-- List header -->
        <div class="h-[52px] border-b border-[#1f1f1f] flex items-end px-3 pb-2">
          <span class="text-[11px] text-gray-500 uppercase tracking-wider font-medium">Project</span>
        </div>
        
        <!-- Projects list -->
        <div 
          ref="projectListRef"
          class="flex-1 overflow-y-auto overflow-x-hidden"
          @scroll="onProjectListScroll"
        >
          <div 
            v-for="project in filteredProjects" 
            :key="project.id"
            @click="goToProject(project)"
            class="h-[44px] flex items-center px-3 hover:bg-[#151515] cursor-pointer border-b border-[#151515] group"
          >
            <!-- Project icon - fixed width -->
            <div 
              class="w-6 h-6 rounded flex-shrink-0 flex items-center justify-center text-[11px] font-medium"
              :style="hasEmoji(project.icon) ? {} : { backgroundColor: project.color || '#6366f1' }"
            >
              <EmojiIcon 
                :name="project.icon" 
                :fallback="project.name.charAt(0).toUpperCase()" 
                size="sm"
              />
            </div>
            
            <!-- Project name - flexible with min width for truncation -->
            <div class="flex-1 min-w-0 ml-2 mr-3">
              <span class="text-[13px] text-gray-200 truncate block">
                {{ project.name }}
              </span>
            </div>
            
            <!-- State icon - fixed width -->
            <div class="w-5 flex-shrink-0 flex items-center justify-center">
              <component 
                :is="getStateIcon(project.state)" 
                class="w-4 h-4" 
                :class="getStateIconColor(project.state)"
              />
            </div>
            
            <!-- Health indicator - fixed width -->
            <div v-if="showHealth" class="w-5 flex-shrink-0 flex items-center justify-center">
              <div 
                v-if="project.health"
                class="w-2 h-2 rounded-full"
                :class="getHealthColor(project.health)"
              />
              <span v-else class="text-gray-600 text-[10px]">---</span>
            </div>
            
            <!-- Lead avatar - fixed width -->
            <div v-if="showLead" class="w-7 flex-shrink-0 flex items-center justify-center">
              <UserLink
                v-if="project.lead"
                :userId="project.lead.id"
                :name="project.lead.name"
                :avatarUrl="project.lead.avatarUrl"
                :showName="false"
                avatarSize="sm"
              />
              <div v-else class="w-6 h-6 rounded-full bg-[#2a2a2a]" />
            </div>
          </div>
          
          <!-- Empty state -->
          <div v-if="filteredProjects.length === 0" class="py-8 text-center">
            <p class="text-[13px] text-gray-500">No projects found</p>
          </div>
        </div>
      </div>
      
      <!-- Timeline area -->
      <div ref="timelineArea" class="flex-1 flex flex-col overflow-hidden">
        <!-- Timeline header -->
        <div class="flex-shrink-0 border-b border-[#1f1f1f]">
          <!-- Year row -->
          <div 
            class="h-[26px] flex border-b border-[#1f1f1f] overflow-hidden"
            ref="timelineHeader"
          >
            <div :style="{ width: `${timelineWidth}px` }" class="flex">
              <div 
                v-for="yearGroup in yearGroups" 
                :key="yearGroup.year"
                class="flex items-center justify-center text-[11px] text-gray-500 font-medium border-l border-[#2a2a2a] first:border-l-0"
                :style="{ width: `${yearGroup.count * colWidth}px` }"
              >
                {{ yearGroup.year }}
              </div>
            </div>
          </div>
          
          <!-- Month/date row -->
          <div class="h-[26px] flex overflow-hidden">
            <div :style="{ width: `${timelineWidth}px` }" class="flex">
              <div 
                v-for="(col, idx) in timelineColumns" 
                :key="idx"
                class="flex flex-col items-center justify-center text-[10px] border-l flex-shrink-0"
                :class="col.isYearStart ? 'border-[#2a2a2a]' : 'border-[#1a1a1a]'"
                :style="{ width: `${colWidth}px` }"
              >
                <span class="text-gray-500">{{ col.label }}</span>
                <span v-if="timeScale === 'year'" class="text-gray-600 text-[9px]">{{ col.date.getDate() }}</span>
              </div>
            </div>
          </div>
        </div>
        
        <!-- Timeline body -->
        <div 
          ref="timelineContainer"
          class="flex-1 overflow-auto"
          @scroll="onTimelineBodyScroll"
        >
          <div 
            class="relative" 
            :style="{ width: `${timelineWidth}px`, minHeight: '100%' }"
          >
            <!-- Grid lines -->
            <div class="absolute inset-0 flex pointer-events-none">
              <div 
                v-for="(col, idx) in timelineColumns" 
                :key="idx"
                class="h-full border-l flex-shrink-0"
                :class="col.isYearStart ? 'border-[#2a2a2a]' : 'border-[#151515]'"
                :style="{ width: `${colWidth}px` }"
              />
            </div>
            
            <!-- Today indicator -->
            <div 
              class="absolute top-0 bottom-0 w-[2px] bg-[#5e6ad2] z-20 pointer-events-none"
              :style="{ left: `${todayPosition}%` }"
            >
              <div class="absolute -top-0 left-1/2 -translate-x-1/2 px-1.5 py-0.5 bg-[#5e6ad2] text-[10px] text-white rounded-b font-medium">
                Today
              </div>
            </div>
            
            <!-- Project rows -->
            <div 
              v-for="project in filteredProjects" 
              :key="project.id"
              class="h-[44px] relative"
            >
              <!-- Project bar -->
              <template v-if="getBarPixelPosition(project)">
                <div 
                  class="absolute top-[8px] h-[28px] flex flex-col justify-center cursor-pointer group"
                  :style="{ 
                    left: `${getBarPixelPosition(project)!.left}px`, 
                    width: `${getBarPixelPosition(project)!.width}px`
                  }"
                  @click="goToProject(project)"
                >
                  <!-- Project name above bar -->
                  <span class="text-[11px] text-gray-400 truncate mb-0.5 group-hover:text-white transition-colors">
                    {{ project.name }}
                  </span>
                  <!-- Bar -->
                  <div 
                    class="h-[14px] rounded-sm group-hover:opacity-90 transition-opacity"
                    :style="{ backgroundColor: project.color || '#6b7280' }"
                  />
                </div>
              </template>
              
              <!-- No dates placeholder -->
              <div 
                v-else 
                class="absolute top-1/2 -translate-y-1/2 left-4 text-[11px] text-gray-600 italic"
              >
                No dates
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Bottom zoom controls -->
    <div class="flex items-center justify-between px-4 py-1.5 border-t border-[#1f1f1f]">
      <div class="flex items-center gap-2">
        <button 
          @click="zoomOut"
          :disabled="colWidth <= MIN_COL_WIDTH"
          class="p-1 text-gray-500 hover:text-white disabled:opacity-30 disabled:cursor-not-allowed rounded"
        >
          <ZoomOut class="w-4 h-4" />
        </button>
        <span class="text-[11px] text-gray-500 w-10 text-center">{{ zoomPercent }}%</span>
        <button 
          @click="zoomIn"
          :disabled="colWidth >= MAX_COL_WIDTH"
          class="p-1 text-gray-500 hover:text-white disabled:opacity-30 disabled:cursor-not-allowed rounded"
        >
          <ZoomIn class="w-4 h-4" />
        </button>
      </div>
      
      <div class="flex items-center gap-1">
        <button 
          @click="navigateTimeline('prev')"
          class="p-1 text-gray-500 hover:text-white rounded"
        >
          <ChevronLeft class="w-4 h-4" />
        </button>
        <span class="text-[11px] text-gray-500 px-2">{{ currentDateLabel }}</span>
        <button 
          @click="navigateTimeline('next')"
          class="p-1 text-gray-500 hover:text-white rounded"
        >
          <ChevronRight class="w-4 h-4" />
        </button>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { FolderKanban, User } from 'lucide-vue-next'
export default {
  components: { FolderKanban, User }
}
</script>
