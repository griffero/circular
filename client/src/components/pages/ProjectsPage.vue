<script setup lang="ts">
import { ref, computed } from 'vue'
import { useAppStore } from '@/stores/app'
import { useUiStore } from '@/stores/ui'
import { FolderKanban, Plus, LayoutGrid, Calendar, List, Filter } from 'lucide-vue-next'
import ProjectRoadmap from '@/components/projects/ProjectRoadmap.vue'

const appStore = useAppStore()
const uiStore = useUiStore()

// View mode: 'list' | 'board' | 'roadmap'
const viewMode = ref<'list' | 'board' | 'roadmap'>('roadmap')

const projects = computed(() => appStore.projects)

// Filters
const filter = ref<'all' | 'current' | 'mine'>('all')

const filteredProjects = computed(() => {
  let filtered = projects.value
  
  if (filter.value === 'current') {
    filtered = filtered.filter(p => p.state === 'started' || p.state === 'planned')
  } else if (filter.value === 'mine') {
    const userId = appStore.currentUser?.id
    filtered = filtered.filter(p => p.leadId === userId)
  }
  
  return filtered
})
</script>

<template>
  <div class="h-full flex flex-col bg-[#0d0d0d]">
    <!-- Header -->
    <div class="flex items-center justify-between px-4 py-2 border-b border-[#222]">
      <div class="flex items-center gap-4">
        <h1 class="text-lg font-medium text-white">Projects</h1>
        
        <!-- Filter tabs -->
        <div class="flex items-center gap-1 text-sm">
          <button 
            @click="filter = 'all'"
            class="px-3 py-1 rounded transition-colors"
            :class="filter === 'all' ? 'bg-[#222] text-white' : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'"
          >
            All projects
          </button>
          <button 
            @click="filter = 'current'"
            class="px-3 py-1 rounded transition-colors"
            :class="filter === 'current' ? 'bg-[#222] text-white' : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'"
          >
            Current projects
          </button>
          <button 
            @click="filter = 'mine'"
            class="px-3 py-1 rounded transition-colors"
            :class="filter === 'mine' ? 'bg-[#222] text-white' : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'"
          >
            My projects
          </button>
        </div>
      </div>
      
      <div class="flex items-center gap-2">
        <!-- View mode toggles -->
        <div class="flex items-center gap-1 border border-[#333] rounded-lg p-0.5">
          <button 
            @click="viewMode = 'list'"
            class="p-1.5 rounded transition-colors"
            :class="viewMode === 'list' ? 'bg-[#333] text-white' : 'text-gray-500 hover:text-white'"
            title="List view"
          >
            <List class="w-4 h-4" />
          </button>
          <button 
            @click="viewMode = 'board'"
            class="p-1.5 rounded transition-colors"
            :class="viewMode === 'board' ? 'bg-[#333] text-white' : 'text-gray-500 hover:text-white'"
            title="Board view"
          >
            <LayoutGrid class="w-4 h-4" />
          </button>
          <button 
            @click="viewMode = 'roadmap'"
            class="p-1.5 rounded transition-colors"
            :class="viewMode === 'roadmap' ? 'bg-[#333] text-white' : 'text-gray-500 hover:text-white'"
            title="Roadmap view"
          >
            <Calendar class="w-4 h-4" />
          </button>
        </div>
        
        <button 
          @click="uiStore.openCreateProjectModal()"
          class="flex items-center gap-2 px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-sm rounded-lg transition-colors"
        >
          <Plus class="w-4 h-4" />
          Add project
        </button>
      </div>
    </div>
    
    <!-- Content based on view mode -->
    <div class="flex-1 overflow-hidden">
      <!-- Roadmap view -->
      <ProjectRoadmap v-if="viewMode === 'roadmap'" />
      
      <!-- List view -->
      <div v-else-if="viewMode === 'list'" class="h-full overflow-auto">
        <!-- Empty state -->
        <div v-if="filteredProjects.length === 0" class="flex-1 flex flex-col items-center justify-center py-20">
          <div class="w-16 h-16 rounded-full bg-[#1a1a1a] flex items-center justify-center mb-4">
            <FolderKanban class="w-8 h-8 text-gray-500" />
          </div>
          <h2 class="text-lg font-medium text-white mb-2">No projects yet</h2>
          <p class="text-sm text-gray-500 text-center max-w-sm mb-4">
            Projects help you organize issues around a specific goal or feature.
          </p>
          <button 
            @click="uiStore.openCreateProjectModal()"
            class="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-sm rounded-lg transition-colors"
          >
            <Plus class="w-4 h-4" />
            Create project
          </button>
        </div>
        
        <!-- Projects list -->
        <div v-else class="p-4 space-y-2">
          <router-link
            v-for="project in filteredProjects"
            :key="project.id"
            :to="`/project/${project.slug}`"
            class="flex items-center gap-3 p-3 bg-[#1a1a1a] hover:bg-[#222] rounded-lg transition-colors"
          >
            <div 
              class="w-8 h-8 rounded flex items-center justify-center text-sm font-medium"
              :style="{ backgroundColor: project.color || '#6366f1' }"
            >
              {{ project.icon || project.name.charAt(0).toUpperCase() }}
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-white truncate">{{ project.name }}</p>
              <p v-if="project.description" class="text-xs text-gray-500 truncate">{{ project.description }}</p>
            </div>
            
            <!-- Progress -->
            <div v-if="project.progress" class="flex items-center gap-2">
              <div class="w-20 h-1.5 bg-[#333] rounded-full overflow-hidden">
                <div 
                  class="h-full bg-indigo-500 rounded-full"
                  :style="{ width: `${project.progress}%` }"
                ></div>
              </div>
              <span class="text-xs text-gray-500">{{ Math.round(project.progress || 0) }}%</span>
            </div>
            
            <!-- Status badge -->
            <span 
              class="text-xs px-2 py-0.5 rounded"
              :class="{
                'bg-green-500/20 text-green-400': project.state === 'started',
                'bg-blue-500/20 text-blue-400': project.state === 'planned',
                'bg-yellow-500/20 text-yellow-400': project.state === 'paused',
                'bg-gray-500/20 text-gray-400': !project.state || project.state === 'backlog',
                'bg-emerald-500/20 text-emerald-400': project.state === 'completed',
                'bg-red-500/20 text-red-400': project.state === 'canceled'
              }"
            >
              {{ project.state || 'backlog' }}
            </span>
            
            <!-- Health indicator -->
            <div 
              v-if="project.health"
              class="w-2 h-2 rounded-full"
              :class="{
                'bg-green-500': project.health === 'onTrack',
                'bg-yellow-500': project.health === 'atRisk',
                'bg-red-500': project.health === 'offTrack'
              }"
              :title="project.health"
            ></div>
          </router-link>
        </div>
      </div>
      
      <!-- Board view (grouped by state) -->
      <div v-else-if="viewMode === 'board'" class="h-full overflow-x-auto p-4">
        <div class="flex gap-4 h-full min-w-max">
          <div 
            v-for="state in ['backlog', 'planned', 'started', 'paused', 'completed']" 
            :key="state"
            class="w-72 flex-shrink-0 flex flex-col bg-[#111] rounded-lg"
          >
            <div class="flex items-center gap-2 px-3 py-2 border-b border-[#222]">
              <span 
                class="w-2 h-2 rounded-full"
                :class="{
                  'bg-gray-500': state === 'backlog',
                  'bg-blue-500': state === 'planned',
                  'bg-green-500': state === 'started',
                  'bg-yellow-500': state === 'paused',
                  'bg-emerald-500': state === 'completed'
                }"
              ></span>
              <span class="text-sm font-medium text-white capitalize">{{ state }}</span>
              <span class="text-xs text-gray-500">
                {{ filteredProjects.filter(p => (p.state || 'backlog') === state).length }}
              </span>
            </div>
            
            <div class="flex-1 p-2 space-y-2 overflow-auto">
              <router-link
                v-for="project in filteredProjects.filter(p => (p.state || 'backlog') === state)"
                :key="project.id"
                :to="`/project/${project.slug}`"
                class="block p-3 bg-[#1a1a1a] hover:bg-[#222] rounded-lg transition-colors"
              >
                <div class="flex items-center gap-2 mb-2">
                  <div 
                    class="w-6 h-6 rounded flex items-center justify-center text-xs font-medium"
                    :style="{ backgroundColor: project.color || '#6366f1' }"
                  >
                    {{ project.icon || project.name.charAt(0).toUpperCase() }}
                  </div>
                  <span class="text-sm font-medium text-white truncate">{{ project.name }}</span>
                </div>
                
                <p v-if="project.description" class="text-xs text-gray-500 line-clamp-2 mb-2">
                  {{ project.description }}
                </p>
                
                <!-- Progress bar -->
                <div v-if="project.progress" class="flex items-center gap-2">
                  <div class="flex-1 h-1 bg-[#333] rounded-full overflow-hidden">
                    <div 
                      class="h-full bg-indigo-500 rounded-full"
                      :style="{ width: `${project.progress}%` }"
                    ></div>
                  </div>
                  <span class="text-xs text-gray-500">{{ Math.round(project.progress || 0) }}%</span>
                </div>
              </router-link>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
