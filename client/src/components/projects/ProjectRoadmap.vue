<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { useAppStore } from '@/stores/app'
import { useEmojiStore } from '@/stores/emoji'
import { useRouter } from 'vue-router'
import type { Project } from '@/types'
import { ChevronLeft, ChevronRight, Circle, CheckCircle2, PauseCircle, XCircle, ZoomIn, ZoomOut } from 'lucide-vue-next'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'

const appStore = useAppStore()
const emojiStore = useEmojiStore()
const router = useRouter()

// Check if a project has a valid emoji (custom slack emoji or unicode)
function hasEmoji(icon?: string | null): boolean {
  if (!icon) return false
  // Check if it's a custom slack emoji
  if (emojiStore.getEmojiUrl(icon)) return true
  // Check if it looks like a unicode emoji
  const stripped = icon.replace(/^:|:$/g, '')
  return /^[\p{Emoji}\u200d]+$/u.test(stripped) && stripped.length <= 8
}

// Refs
const timelineContainer = ref<HTMLElement | null>(null)
const timelineHeader = ref<HTMLElement | null>(null)
const timelineArea = ref<HTMLElement | null>(null)

// Timeline range: 2 years back to 2 years forward
const today = new Date()
const timelineStart = new Date(today.getFullYear() - 1, 0, 1)
const timelineEnd = new Date(today.getFullYear() + 2, 11, 31)

// Generate months for timeline
const months = computed(() => {
  const result: { date: Date; label: string; year: number }[] = []
  const current = new Date(timelineStart)
  
  while (current <= timelineEnd) {
    result.push({
      date: new Date(current),
      label: current.toLocaleDateString('en-US', { month: 'short' }),
      year: current.getFullYear()
    })
    current.setMonth(current.getMonth() + 1)
  }
  
  return result
})

// Group months by year for header
const years = computed(() => {
  const result: { year: number; monthCount: number }[] = []
  let currentYear = -1
  
  months.value.forEach(month => {
    if (month.year !== currentYear) {
      result.push({ year: month.year, monthCount: 1 })
      currentYear = month.year
    } else {
      result[result.length - 1].monthCount++
    }
  })
  
  return result
})

// All projects sorted by name
const sortedProjects = computed(() => {
  return [...appStore.projects].sort((a, b) => a.name.localeCompare(b.name))
})

// Column width in pixels (reactive for zoom)
const colWidth = ref(50)
const MIN_COL_WIDTH = 20
const MAX_COL_WIDTH = 150
const ZOOM_STEP = 10

// Zoom level display
const zoomPercent = computed(() => Math.round((colWidth.value / 50) * 100))

// Total timeline width
const timelineWidth = computed(() => months.value.length * colWidth.value)

// Handle wheel/pinch zoom on timeline
// Pinch gestures on trackpad are detected as wheel events with ctrlKey=true
function handleWheel(e: WheelEvent) {
  // Only zoom on pinch gesture (ctrlKey is true for trackpad pinch)
  // Regular scroll should pan the timeline normally
  if (!e.ctrlKey) return
  
  if (!timelineContainer.value) return
  
  // Prevent default browser zoom
  e.preventDefault()
  
  const container = timelineContainer.value
  const rect = container.getBoundingClientRect()
  
  // Get cursor position relative to timeline
  const cursorX = e.clientX - rect.left + container.scrollLeft
  const cursorRatio = cursorX / timelineWidth.value
  
  // Calculate new column width (pinch uses smaller deltas, so use deltaY directly)
  const zoomDelta = e.deltaY > 0 ? -ZOOM_STEP : ZOOM_STEP
  const newColWidth = Math.min(MAX_COL_WIDTH, Math.max(MIN_COL_WIDTH, colWidth.value + zoomDelta))
  
  if (newColWidth === colWidth.value) return
  
  // Update column width
  colWidth.value = newColWidth
  const newWidth = months.value.length * newColWidth
  
  // Adjust scroll position to keep cursor position stable
  nextTick(() => {
    const newCursorX = cursorRatio * newWidth
    container.scrollLeft = newCursorX - (e.clientX - rect.left)
    
    // Sync header scroll
    if (timelineHeader.value) {
      timelineHeader.value.scrollLeft = container.scrollLeft
    }
  })
}

// Zoom controls
function zoomIn() {
  colWidth.value = Math.min(MAX_COL_WIDTH, colWidth.value + ZOOM_STEP)
}

function zoomOut() {
  colWidth.value = Math.max(MIN_COL_WIDTH, colWidth.value - ZOOM_STEP)
}

function resetZoom() {
  colWidth.value = 50
}

// Calculate position for a date
function getDatePosition(dateStr: string | undefined): number | null {
  if (!dateStr) return null
  
  const date = new Date(dateStr)
  if (isNaN(date.getTime())) return null
  
  const totalMs = timelineEnd.getTime() - timelineStart.getTime()
  const dateMs = date.getTime() - timelineStart.getTime()
  
  return (dateMs / totalMs) * 100
}

// Get bar style for a project
function getBarStyle(project: Project): Record<string, string> | null {
  const startPos = getDatePosition(project.startDate)
  const endPos = getDatePosition(project.targetDate)
  
  // If no dates, return null
  if (startPos === null && endPos === null) {
    return null
  }
  
  // Default to today's position if only one date
  const todayPos = getDatePosition(today.toISOString())
  const left = startPos ?? (endPos !== null ? Math.max(0, endPos - 5) : todayPos ?? 50)
  const right = endPos ?? (startPos !== null ? Math.min(100, startPos + 5) : todayPos ?? 50)
  
  const width = Math.max(1, right - left)
  
  return {
    left: `${left}%`,
    width: `${width}%`,
    backgroundColor: project.color || '#6366f1'
  }
}

// Today indicator position
const todayPosition = computed(() => {
  return getDatePosition(today.toISOString()) ?? 50
})

// State icon component
function getStateIcon(state?: string) {
  switch (state) {
    case 'completed': return CheckCircle2
    case 'paused': return PauseCircle
    case 'canceled': return XCircle
    default: return Circle
  }
}

function getStateColor(state?: string) {
  switch (state) {
    case 'completed': return 'text-green-500'
    case 'paused': return 'text-yellow-500'
    case 'canceled': return 'text-red-500'
    case 'started': return 'text-blue-500'
    default: return 'text-gray-500'
  }
}

// Navigate to project
function goToProject(project: Project) {
  router.push(`/project/${project.slug}`)
}

// Scroll sync
function onTimelineScroll(e: Event) {
  const target = e.target as HTMLElement
  if (timelineHeader.value) {
    timelineHeader.value.scrollLeft = target.scrollLeft
  }
}

// Scroll navigation
function scrollTimeline(direction: 'left' | 'right') {
  if (!timelineContainer.value) return
  const amount = colWidth.value * 6 // Scroll by 6 months
  timelineContainer.value.scrollBy({
    left: direction === 'right' ? amount : -amount,
    behavior: 'smooth'
  })
}

// Scroll to today on mount
onMounted(async () => {
  await nextTick()
  if (timelineContainer.value) {
    const containerWidth = timelineContainer.value.clientWidth
    const todayPx = (todayPosition.value / 100) * timelineWidth.value
    timelineContainer.value.scrollLeft = Math.max(0, todayPx - containerWidth / 2)
  }
  
  // Add wheel event listener with passive: false to allow preventDefault
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
  <div class="h-full flex flex-col">
    <!-- Timeline controls -->
    <div class="flex items-center justify-between px-4 py-2 border-b border-[#222]">
      <!-- Zoom controls -->
      <div class="flex items-center gap-2">
        <button 
          @click="zoomOut"
          :disabled="colWidth <= MIN_COL_WIDTH"
          class="p-1.5 rounded hover:bg-[#222] text-gray-400 disabled:opacity-30 disabled:cursor-not-allowed"
          title="Zoom out (or pinch on trackpad)"
        >
          <ZoomOut class="w-4 h-4" />
        </button>
        <button
          @click="resetZoom"
          class="px-2 py-1 text-xs text-gray-500 hover:text-white hover:bg-[#222] rounded min-w-[48px]"
          title="Reset zoom"
        >
          {{ zoomPercent }}%
        </button>
        <button 
          @click="zoomIn"
          :disabled="colWidth >= MAX_COL_WIDTH"
          class="p-1.5 rounded hover:bg-[#222] text-gray-400 disabled:opacity-30 disabled:cursor-not-allowed"
          title="Zoom in (or pinch on trackpad)"
        >
          <ZoomIn class="w-4 h-4" />
        </button>
      </div>
      
      <!-- Navigation controls -->
      <div class="flex items-center gap-2">
        <button 
          @click="scrollTimeline('left')"
          class="p-1.5 rounded hover:bg-[#222] text-gray-400"
        >
          <ChevronLeft class="w-4 h-4" />
        </button>
        <span class="text-xs text-gray-500">{{ today.toLocaleDateString('en-US', { month: 'short', year: 'numeric' }) }}</span>
        <button 
          @click="scrollTimeline('right')"
          class="p-1.5 rounded hover:bg-[#222] text-gray-400"
        >
          <ChevronRight class="w-4 h-4" />
        </button>
      </div>
    </div>

    <!-- Main content area -->
    <div class="flex-1 flex overflow-hidden">
      <!-- Left sidebar - Project list -->
      <div class="w-72 flex-shrink-0 border-r border-[#222] flex flex-col">
        <!-- Header aligned with timeline -->
        <div class="h-12 border-b border-[#222] flex items-end px-3 pb-1">
          <span class="text-xs text-gray-500 uppercase tracking-wide">Project</span>
        </div>
        
        <!-- Projects list -->
        <div class="flex-1 overflow-y-auto">
          <div 
            v-for="project in sortedProjects" 
            :key="project.id"
            @click="goToProject(project)"
            class="h-10 flex items-center gap-2 px-3 hover:bg-[#1a1a1a] cursor-pointer border-b border-[#1a1a1a]"
          >
            <!-- Project icon -->
            <div 
              class="w-5 h-5 rounded flex-shrink-0 flex items-center justify-center"
              :style="hasEmoji(project.icon) ? {} : { backgroundColor: project.color || '#6366f1' }"
            >
              <EmojiIcon 
                :name="project.icon" 
                :fallback="project.name.charAt(0)" 
                size="sm"
              />
            </div>
            
            <!-- Project name -->
            <span class="flex-1 text-sm text-white truncate">{{ project.name }}</span>
            
            <!-- State indicator -->
            <component 
              :is="getStateIcon(project.state)" 
              class="w-3.5 h-3.5 flex-shrink-0" 
              :class="getStateColor(project.state)"
            />
            
            <!-- Health indicator -->
            <div 
              v-if="project.health"
              class="w-2 h-2 rounded-full flex-shrink-0"
              :class="{
                'bg-green-500': project.health === 'onTrack',
                'bg-yellow-500': project.health === 'atRisk',
                'bg-red-500': project.health === 'offTrack'
              }"
            ></div>
          </div>
        </div>
      </div>
      
      <!-- Timeline area -->
      <div ref="timelineArea" class="flex-1 flex flex-col overflow-hidden">
        <!-- Timeline header (years + months) -->
        <div class="flex-shrink-0 border-b border-[#222]">
          <!-- Years row -->
          <div class="h-6 flex" :style="{ width: `${timelineWidth}px` }">
            <div 
              v-for="year in years" 
              :key="year.year"
              class="flex items-center justify-center text-xs text-gray-400 border-l border-[#333]"
              :style="{ width: `${year.monthCount * colWidth}px` }"
            >
              {{ year.year }}
            </div>
          </div>
          
          <!-- Months row (scrollable header) -->
          <div 
            ref="timelineHeader"
            class="h-6 flex overflow-hidden"
          >
            <div 
              v-for="(month, idx) in months" 
              :key="idx"
              class="flex-shrink-0 flex items-center justify-center text-xs text-gray-500 border-l border-[#222]"
              :class="{ 'border-l-[#333]': month.label === 'Jan' }"
              :style="{ width: `${colWidth}px` }"
            >
              {{ month.label }}
            </div>
          </div>
        </div>
        
        <!-- Timeline body -->
        <div 
          ref="timelineContainer"
          class="flex-1 overflow-auto"
          @scroll="onTimelineScroll"
        >
          <div class="relative" :style="{ width: `${timelineWidth}px`, minHeight: '100%' }">
            <!-- Grid lines -->
            <div class="absolute inset-0 flex pointer-events-none">
              <div 
                v-for="(month, idx) in months" 
                :key="idx"
                class="flex-shrink-0 h-full border-l"
                :class="month.label === 'Jan' ? 'border-[#333]' : 'border-[#1a1a1a]'"
                :style="{ width: `${colWidth}px` }"
              ></div>
            </div>
            
            <!-- Today indicator -->
            <div 
              class="absolute top-0 bottom-0 w-0.5 bg-indigo-500 z-10 pointer-events-none"
              :style="{ left: `${todayPosition}%` }"
            >
              <div class="absolute -top-1 left-1/2 -translate-x-1/2 px-1.5 py-0.5 bg-indigo-500 text-[10px] text-white rounded">
                Today
              </div>
            </div>
            
            <!-- Project rows -->
            <div 
              v-for="project in sortedProjects" 
              :key="project.id"
              class="h-10 relative flex items-center"
            >
              <!-- Project bar -->
              <div 
                v-if="getBarStyle(project)"
                class="absolute h-6 rounded cursor-pointer hover:opacity-80 transition-opacity flex items-center px-2 overflow-hidden"
                :style="getBarStyle(project)!"
                @click="goToProject(project)"
              >
                <span class="text-xs text-white font-medium truncate whitespace-nowrap">
                  {{ project.name }}
                </span>
              </div>
              
              <!-- No dates indicator -->
              <span 
                v-else
                class="absolute left-4 text-xs text-gray-600 italic"
              >
                No dates set
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
