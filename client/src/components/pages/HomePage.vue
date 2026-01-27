<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useAppStore } from '@/stores/app'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
import {
  Circle,
  Clock,
  CheckCircle2,
  TrendingUp,
  ArrowUpRight,
  Filter,
  Bell
} from 'lucide-vue-next'

const authStore = useAuthStore()
const appStore = useAppStore()

const teams = computed(() => appStore.teams)
const projects = computed(() => appStore.projects)

// Stats - these would come from API in real implementation
const stats = computed(() => ({
  openIssues: 0,
  inProgress: 0,
  completedThisWeek: 0,
  assignedToYou: 0
}))

const greeting = computed(() => {
  const hour = new Date().getHours()
  if (hour < 12) return 'Good morning'
  if (hour < 18) return 'Good afternoon'
  return 'Good evening'
})

const user = computed(() => authStore.user)

// Get status label for project
function getProjectStatus(project: any) {
  if (project.state === 'completed') return 'Completed'
  if (project.state === 'started') return 'Active'
  if (project.state === 'paused') return 'Paused'
  if (project.state === 'canceled') return 'Canceled'
  return 'Active'
}
</script>

<template>
  <div class="h-full flex flex-col bg-[#0d0d0d]">
    <!-- Header -->
    <div class="flex items-center justify-between px-6 py-3 border-b border-[#1f1f1f]">
      <div class="flex items-center gap-2">
        <span class="text-sm font-medium text-white">Pulse</span>
      </div>
      <div class="flex items-center gap-2">
        <button class="flex items-center gap-1.5 px-2.5 py-1.5 text-sm text-gray-400 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors">
          <Filter class="w-4 h-4" />
          Filter
        </button>
        <button class="p-1.5 text-gray-400 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors">
          <Bell class="w-4 h-4" />
        </button>
      </div>
    </div>

    <!-- Content -->
    <div class="flex-1 overflow-y-auto">
      <div class="max-w-4xl mx-auto px-6 py-8">
        <!-- Greeting -->
        <div class="mb-8">
          <h1 class="text-2xl font-semibold text-white">
            {{ greeting }}, {{ user?.email }}
          </h1>
          <p class="mt-1 text-gray-500 text-sm">
            Here's what's happening today
          </p>
        </div>

        <!-- Stats cards -->
        <div class="grid grid-cols-4 gap-4 mb-8">
          <!-- Open issues -->
          <div class="bg-[#151515] rounded-lg border border-[#252525] p-4">
            <div class="flex items-center gap-3">
              <Circle class="w-5 h-5 text-blue-500" />
              <div>
                <p class="text-2xl font-semibold text-white">{{ stats.openIssues }}</p>
                <p class="text-xs text-gray-500">Open issues</p>
              </div>
            </div>
          </div>

          <!-- In progress -->
          <div class="bg-[#151515] rounded-lg border border-[#252525] p-4">
            <div class="flex items-center gap-3">
              <Clock class="w-5 h-5 text-yellow-500" />
              <div>
                <p class="text-2xl font-semibold text-white">{{ stats.inProgress }}</p>
                <p class="text-xs text-gray-500">In progress</p>
              </div>
            </div>
          </div>

          <!-- Completed this week -->
          <div class="bg-[#151515] rounded-lg border border-[#252525] p-4">
            <div class="flex items-center gap-3">
              <CheckCircle2 class="w-5 h-5 text-green-500" />
              <div>
                <p class="text-2xl font-semibold text-white">{{ stats.completedThisWeek }}</p>
                <p class="text-xs text-gray-500">Completed this week</p>
              </div>
            </div>
          </div>

          <!-- Assigned to you -->
          <div class="bg-[#151515] rounded-lg border border-[#252525] p-4">
            <div class="flex items-center gap-3">
              <TrendingUp class="w-5 h-5 text-purple-500" />
              <div>
                <p class="text-2xl font-semibold text-white">{{ stats.assignedToYou }}</p>
                <p class="text-xs text-gray-500">Assigned to you</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Teams & Projects -->
        <div class="grid grid-cols-2 gap-6">
          <!-- Your Teams -->
          <div class="bg-[#151515] rounded-lg border border-[#252525] overflow-hidden">
            <div class="flex items-center justify-between px-4 py-3 border-b border-[#252525]">
              <h2 class="text-sm font-medium text-white">Your Teams</h2>
              <router-link
                to="/settings"
                class="text-xs text-indigo-400 hover:text-indigo-300"
              >
                Manage
              </router-link>
            </div>
            
            <div class="max-h-[400px] overflow-y-auto">
              <div v-if="teams.length === 0" class="p-8 text-center">
                <p class="text-gray-500 text-sm">No teams yet</p>
              </div>
              
              <router-link
                v-for="team in teams"
                :key="team.id"
                :to="`/team/${team.key}`"
                class="flex items-center gap-3 px-4 py-2.5 hover:bg-[#1a1a1a] transition-colors border-b border-[#1f1f1f] last:border-b-0"
              >
                <div 
                  class="w-7 h-7 rounded flex items-center justify-center flex-shrink-0"
                  :style="{ backgroundColor: team.color || '#6366f1' }"
                >
                  <EmojiIcon 
                    :name="team.icon" 
                    :fallback="team.key.charAt(0)" 
                    size="sm"
                  />
                </div>
                <div class="flex-1 min-w-0">
                  <p class="text-sm text-white truncate">{{ team.name }}</p>
                  <p class="text-xs text-gray-500">{{ team.key }}</p>
                </div>
                <ArrowUpRight class="w-4 h-4 text-gray-600" />
              </router-link>
            </div>
          </div>

          <!-- Projects -->
          <div class="bg-[#151515] rounded-lg border border-[#252525] overflow-hidden">
            <div class="flex items-center justify-between px-4 py-3 border-b border-[#252525]">
              <h2 class="text-sm font-medium text-white">Projects</h2>
              <router-link
                to="/projects"
                class="text-xs text-indigo-400 hover:text-indigo-300"
              >
                Manage
              </router-link>
            </div>
            
            <div class="max-h-[400px] overflow-y-auto">
              <div v-if="projects.length === 0" class="p-8 text-center">
                <p class="text-gray-500 text-sm">No projects yet</p>
              </div>
              
              <router-link
                v-for="project in projects"
                :key="project.id"
                :to="`/project/${project.slug}`"
                class="flex items-center gap-3 px-4 py-2.5 hover:bg-[#1a1a1a] transition-colors border-b border-[#1f1f1f] last:border-b-0"
              >
                <div 
                  class="w-7 h-7 rounded flex items-center justify-center flex-shrink-0"
                  :style="{ backgroundColor: project.color || '#6366f1' }"
                >
                  <EmojiIcon 
                    :name="project.icon" 
                    :fallback="project.name.charAt(0)" 
                    size="sm"
                  />
                </div>
                <div class="flex-1 min-w-0">
                  <p class="text-sm text-white truncate">{{ project.name }}</p>
                  <p class="text-xs text-gray-500">{{ getProjectStatus(project) }}</p>
                </div>
                <ArrowUpRight class="w-4 h-4 text-gray-600" />
              </router-link>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
