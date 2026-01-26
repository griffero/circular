<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useAppStore } from '@/stores/app'
import { useRouter } from 'vue-router'
import type { Project, Team } from '@/types'
import { 
  ChevronLeft, ChevronRight, Circle, CheckCircle2, 
  PauseCircle, XCircle, AlertCircle, ChevronDown
} from 'lucide-vue-next'

const appStore = useAppStore()
const router = useRouter()

// View mode: 'month' | 'quarter' | 'year'
const viewMode = ref<'month' | 'quarter' | 'year'>('year')

// Scroll container ref
const timelineContainer = ref<HTMLElement | null>(null)

// Calculate timeline range
const today = new Date()
const timelineStart = ref(new Date(today.getFullYear() - 1, 0, 1))
const timelineEnd = ref(new Date(today.getFullYear() + 3, 11, 31))

// Projects with dates
const projectsWithDates = computed(() => {
  return appStore.projects.filter(p => p.startDate || p.targetDate)
})

const projectsWithoutDates = computed(() => {
  return appStore.projects.filter(p => !p.startDate && !p.targetDate)
})

// Group projects by team
const projectsByTeam = computed(() => {
  const grouped: Record<string, { team: Team | null; projects: Project[] }> = {}
  
  appStore.projects.forEach(project => {
    const teamId = project.teams?.[0]?.id || 'no-team'
    const team = project.teams?.[0] || null
    
    if (!grouped[teamId]) {
      grouped[teamId] = { team, projects: [] }
    }
    grouped[teamId].projects.push(project)
  })
  
  return Object.values(grouped).sort((a, b) => {
    if (!a.team) return 1
    if (!b.team) return -1
    return a.team.name.localeCompare(b.team.name)
  })
})

// Generate time columns based on view mode
const timeColumns = computed(() => {
  const columns: { date: Date; label: string; isMonth: boolean }[] = []
  const start = new Date(timelineStart.value)
  const end = new Date(timelineEnd.value)
  
  let current = new Date(start)
  
  while (current <= end) {
    if (viewMode.value === 'year') {
      // Show months
      columns.push({
        date: new Date(current),
        label: current.toLocaleDateString('en-US', { month: 'short' }),
        isMonth: current.getMonth() === 0
      })
      current.setMonth(current.getMonth() + 1)
    } else if (viewMode.value === 'quarter') {
      // Show weeks
      columns.push({
        date: new Date(current),
        label: `W${Math.ceil(current.getDate() / 7)}`,
        isMonth: current.getDate() <= 7
      })
      current.setDate(current.getDate() + 7)
    } else {
      // Show days
      columns.push({
        date: new Date(current),
        label: current.getDate().toString(),
        isMonth: current.getDate() === 1
      })
      current.setDate(current.getDate() + 1)
    }
  }
  
  return columns
})

// Get year markers
const yearMarkers = computed(() => {
  const years: { year: number; startIndex: number }[] = []
  let currentYear = -1
  
  timeColumns.value.forEach((col, index) => {
    const year = col.date.getFullYear()
    if (year !== currentYear) {
      years.push({ year, startIndex: index })
      currentYear = year
    }
  })
  
  return years
})

// Calculate column width based on view mode
const columnWidth = computed(() => {
  switch (viewMode.value) {
    case 'year': return 40
    case 'quarter': return 20
    case 'month': return 30
    default: return 40
  }
})

// Calculate bar position and width for a project
function getProjectBarStyle(project: Project) {
  const startDate = project.startDate ? new Date(project.startDate) : null
  const endDate = project.targetDate ? new Date(project.targetDate) : null
  
  if (!startDate && !endDate) {
    return { display: 'none' }
  }
  
  const timelineStartTime = timelineStart.value.getTime()
  const timelineEndTime = timelineEnd.value.getTime()
  const totalDuration = timelineEndTime - timelineStartTime
  
  const barStart = startDate ? startDate.getTime() : timelineStartTime
  const barEnd = endDate ? endDate.getTime() : timelineEndTime
  
  const leftPercent = ((barStart - timelineStartTime) / totalDuration) * 100
  const widthPercent = ((barEnd - barStart) / totalDuration) * 100
  
  return {
    left: `${Math.max(0, leftPercent)}%`,
    width: `${Math.min(100 - leftPercent, widthPercent)}%`,
    backgroundColor: project.color || '#6366f1'
  }
}

// Today indicator position
const todayPosition = computed(() => {
  const timelineStartTime = timelineStart.value.getTime()
  const timelineEndTime = timelineEnd.value.getTime()
  const totalDuration = timelineEndTime - timelineStartTime
  const todayTime = today.getTime()
  
  return ((todayTime - timelineStartTime) / totalDuration) * 100
})

// Get project state icon
function getStateIcon(state?: string) {
  switch (state) {
    case 'completed': return CheckCircle2
    case 'paused': return PauseCircle
    case 'canceled': return XCircle
    case 'started': return Circle
    default: return Circle
  }
}

// Get project state color
function getStateColor(state?: string) {
  switch (state) {
    case 'completed': return 'text-green-500'
    case 'paused': return 'text-yellow-500'
    case 'canceled': return 'text-red-500'
    case 'started': return 'text-blue-500'
    default: return 'text-gray-500'
  }
}

// Get health indicator
function getHealthIndicator(health?: string) {
  switch (health) {
    case 'onTrack': return { color: 'bg-green-500', label: 'On track' }
    case 'atRisk': return { color: 'bg-yellow-500', label: 'At risk' }
    case 'offTrack': return { color: 'bg-red-500', label: 'Off track' }
    default: return null
  }
}

// Navigate to project
function goToProject(project: Project) {
  router.push(`/project/${project.slug}`)
}

// Scroll timeline
function scrollTimeline(direction: 'left' | 'right') {
  if (!timelineContainer.value) return
  const scrollAmount = 300
  timelineContainer.value.scrollBy({
    left: direction === 'right' ? scrollAmount : -scrollAmount,
    behavior: 'smooth'
  })
}

// Scroll to today on mount
onMounted(() => {
  if (timelineContainer.value) {
    const containerWidth = timelineContainer.value.clientWidth
    const scrollPosition = (todayPosition.value / 100) * timelineContainer.value.scrollWidth - containerWidth / 2
    timelineContainer.value.scrollLeft = Math.max(0, scrollPosition)
  }
})
</script>

<template>
  <div class="h-full flex flex-col bg-[#0d0d0d]">
    <!-- Header -->
    <div class="flex items-center justify-between px-4 py-3 border-b border-[#222]">
      <div class="flex items-center gap-4">
        <h1 class="text-lg font-semibold text-white">Projects</h1>
        <div class="flex items-center gap-1 text-sm">
          <button class="px-3 py-1 rounded text-gray-400 hover:text-white hover:bg-[#1a1a1a]">
            All projects
          </button>
          <button class="px-3 py-1 rounded text-gray-400 hover:text-white hover:bg-[#1a1a1a]">
            Current projects
          </button>
          <button class="px-3 py-1 rounded text-gray-400 hover:text-white hover:bg-[#1a1a1a]">
            My projects
          </button>
        </div>
      </div>
      
      <div class="flex items-center gap-2">
        <button 
          @click="scrollTimeline('left')"
          class="p-1 rounded hover:bg-[#1a1a1a] text-gray-400"
        >
          <ChevronLeft class="w-5 h-5" />
        </button>
        <button 
          class="px-3 py-1 rounded bg-[#1a1a1a] text-white text-sm"
        >
          Today
        </button>
        <button 
          @click="scrollTimeline('right')"
          class="p-1 rounded hover:bg-[#1a1a1a] text-gray-400"
        >
          <ChevronRight class="w-5 h-5" />
        </button>
        
        <div class="relative ml-4">
          <button class="flex items-center gap-1 px-3 py-1 rounded bg-[#1a1a1a] text-white text-sm">
            {{ viewMode === 'year' ? 'Year' : viewMode === 'quarter' ? 'Quarter' : 'Month' }}
            <ChevronDown class="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
    
    <!-- Main content -->
    <div class="flex-1 flex overflow-hidden">
      <!-- Left sidebar - Project list -->
      <div class="w-64 flex-shrink-0 border-r border-[#222] overflow-y-auto">
        <div v-for="group in projectsByTeam" :key="group.team?.id || 'no-team'" class="border-b border-[#222]">
          <!-- Team header -->
          <div v-if="group.team" class="px-3 py-2 bg-[#111] sticky top-0">
            <div class="flex items-center gap-2">
              <div 
                class="w-4 h-4 rounded"
                :style="{ backgroundColor: group.team.color || '#6366f1' }"
              ></div>
              <span class="text-sm font-medium text-gray-300">{{ group.team.name }}</span>
            </div>
          </div>
          
          <!-- Projects in team -->
          <div 
            v-for="project in group.projects" 
            :key="project.id"
            @click="goToProject(project)"
            class="flex items-center gap-2 px-3 py-2 hover:bg-[#1a1a1a] cursor-pointer border-b border-[#1a1a1a] last:border-b-0"
          >
            <!-- Project icon -->
            <div 
              class="w-5 h-5 rounded flex items-center justify-center text-xs"
              :style="{ backgroundColor: project.color || '#6366f1' }"
            >
              {{ project.icon || project.name.charAt(0).toUpperCase() }}
            </div>
            
            <!-- Project name -->
            <span class="flex-1 text-sm text-white truncate">{{ project.name }}</span>
            
            <!-- State indicator -->
            <component 
              :is="getStateIcon(project.state)" 
              class="w-4 h-4" 
              :class="getStateColor(project.state)"
            />
            
            <!-- Health indicator -->
            <div 
              v-if="getHealthIndicator(project.health)"
              class="w-2 h-2 rounded-full"
              :class="getHealthIndicator(project.health)?.color"
            ></div>
          </div>
        </div>
      </div>
      
      <!-- Timeline area -->
      <div class="flex-1 overflow-hidden flex flex-col">
        <!-- Timeline header -->
        <div class="flex-shrink-0 border-b border-[#222] bg-[#0d0d0d]">
          <!-- Year row -->
          <div class="flex h-6 border-b border-[#1a1a1a]">
            <div 
              v-for="marker in yearMarkers" 
              :key="marker.year"
              class="text-xs text-gray-500 px-2 border-l border-[#222] flex items-center"
              :style="{ 
                marginLeft: marker.startIndex === 0 ? '0' : 'auto',
                position: 'sticky',
                left: 0
              }"
            >
              {{ marker.year }}
            </div>
          </div>
          
          <!-- Month/Week row -->
          <div 
            ref="timelineHeader"
            class="flex h-6 overflow-hidden"
          >
            <div 
              v-for="(col, index) in timeColumns" 
              :key="index"
              class="flex-shrink-0 text-xs text-gray-500 text-center border-l border-[#1a1a1a]"
              :class="{ 'border-l-[#333]': col.isMonth }"
              :style="{ width: `${columnWidth}px` }"
            >
              {{ col.label }}
            </div>
          </div>
        </div>
        
        <!-- Timeline body -->
        <div 
          ref="timelineContainer"
          class="flex-1 overflow-x-auto overflow-y-auto relative"
          @scroll="(e) => {
            const header = $refs.timelineHeader as HTMLElement
            if (header) header.scrollLeft = (e.target as HTMLElement).scrollLeft
          }"
        >
          <!-- Today indicator -->
          <div 
            class="absolute top-0 bottom-0 w-px bg-indigo-500 z-10 pointer-events-none"
            :style="{ left: `${todayPosition}%` }"
          >
            <div class="absolute -top-0.5 -left-1 w-2 h-2 rounded-full bg-indigo-500"></div>
          </div>
          
          <!-- Grid background -->
          <div 
            class="absolute inset-0 flex pointer-events-none"
            :style="{ width: `${timeColumns.length * columnWidth}px` }"
          >
            <div 
              v-for="(col, index) in timeColumns" 
              :key="index"
              class="flex-shrink-0 h-full border-l"
              :class="col.isMonth ? 'border-[#222]' : 'border-[#1a1a1a]'"
              :style="{ width: `${columnWidth}px` }"
            ></div>
          </div>
          
          <!-- Project rows -->
          <div 
            class="relative"
            :style="{ width: `${timeColumns.length * columnWidth}px`, minHeight: '100%' }"
          >
            <template v-for="group in projectsByTeam" :key="group.team?.id || 'no-team'">
              <!-- Team header row -->
              <div v-if="group.team" class="h-8 bg-[#111]/50"></div>
              
              <!-- Project rows -->
              <div 
                v-for="project in group.projects" 
                :key="project.id"
                class="h-10 relative flex items-center"
              >
                <!-- Project bar -->
                <div 
                  v-if="project.startDate || project.targetDate"
                  class="absolute h-6 rounded-md cursor-pointer hover:opacity-80 transition-opacity flex items-center px-2"
                  :style="getProjectBarStyle(project)"
                  @click="goToProject(project)"
                >
                  <span class="text-xs text-white font-medium truncate">
                    {{ project.name }}
                  </span>
                </div>
                
                <!-- No dates indicator -->
                <div 
                  v-else
                  class="absolute left-2 text-xs text-gray-600 italic"
                >
                  No dates set
                </div>
              </div>
            </template>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
