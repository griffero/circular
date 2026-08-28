<script setup lang="ts">
import { ref, computed } from 'vue'
import { useAppStore } from '@/stores/app'
import { useUiStore } from '@/stores/ui'
import { useEmojiStore } from '@/stores/emoji'
import { FolderKanban, Plus } from 'lucide-vue-next'
import ProjectRoadmap from '@/components/projects/ProjectRoadmap.vue'
import ProjectDetailPanel from '@/components/projects/ProjectDetailPanel.vue'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
import type { Project } from '@/types'
const appStore = useAppStore()
const uiStore = useUiStore()
const emojiStore = useEmojiStore()

// View mode: 'list' | 'board' | 'roadmap'
const viewMode = ref<'list' | 'board' | 'roadmap'>('roadmap')

// Selected project for detail panel
const selectedProjectId = ref<string | null>(null)

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

// Check if a project has a valid emoji (custom slack emoji or unicode)
function hasEmoji(icon?: string | null): boolean {
  return emojiStore.isRenderableEmoji(icon)
}

// Select a project to show in detail panel
function selectProject(project: Project) {
  selectedProjectId.value = project.id
}

// Close detail panel
function closeDetailPanel() {
  selectedProjectId.value = null
}
</script>

<template>
  <div data-testid="projects-ready" class="h-full flex bg-[var(--linear-bg)]">
    <!-- Main content -->
    <div class="flex-1 flex flex-col min-w-0">
      <!-- Content based on view mode -->
      <div class="flex-1 overflow-hidden">
        <!-- Roadmap view (has its own header) -->
        <ProjectRoadmap 
          v-if="viewMode === 'roadmap'" 
          @select-project="selectProject"
        />
        
        <!-- List view -->
        <div v-else-if="viewMode === 'list'" class="h-full overflow-auto">
          <!-- Empty state -->
          <div v-if="filteredProjects.length === 0" class="flex-1 flex flex-col items-center justify-center py-20">
            <div class="w-16 h-16 rounded-full bg-[var(--linear-elevated)] flex items-center justify-center mb-4">
              <FolderKanban class="w-8 h-8 text-[var(--linear-muted)]" />
            </div>
            <h2 class="text-lg font-medium text-[var(--linear-text)] mb-2">No projects yet</h2>
            <p class="text-sm text-[var(--linear-muted)] text-center max-w-sm mb-4">
              Projects help you organize issues around a specific goal or feature.
            </p>
            <button 
              @click="uiStore.openCreateProjectModal()"
              class="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-[var(--linear-text)] text-sm rounded-lg transition-colors"
            >
              <Plus class="w-4 h-4" />
              Create project
            </button>
          </div>
          
          <!-- Projects list -->
          <div v-else class="p-4 space-y-2">
            <div
              v-for="project in filteredProjects"
              :key="project.id"
              @click="selectProject(project)"
              class="flex items-center gap-3 p-3 bg-[var(--linear-elevated)] hover:bg-[var(--linear-surface)] rounded-lg transition-colors cursor-pointer"
              :class="{ 'ring-1 ring-indigo-500/50': selectedProjectId === project.id }"
            >
              <div 
                class="w-8 h-8 rounded flex items-center justify-center"
                :style="hasEmoji(project.icon) ? {} : { backgroundColor: project.color || '#6366f1' }"
              >
                <EmojiIcon 
                  :name="project.icon" 
                  :fallback="project.name.charAt(0)" 
                  size="md"
                />
              </div>
              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium text-[var(--linear-text)] truncate">{{ project.name }}</p>
                <p v-if="project.description" class="text-xs text-[var(--linear-muted)] truncate">{{ project.description }}</p>
              </div>
              
              <!-- Progress -->
              <div v-if="project.progress" class="flex items-center gap-2">
                <div class="w-20 h-1.5 bg-[var(--linear-border)] rounded-full overflow-hidden">
                  <div 
                    class="h-full bg-indigo-500 rounded-full"
                    :style="{ width: `${project.progress}%` }"
                  ></div>
                </div>
                <span class="text-xs text-[var(--linear-muted)]">{{ Math.round(project.progress || 0) }}%</span>
              </div>
              
              <!-- Status badge -->
              <span 
                class="text-xs px-2 py-0.5 rounded"
                :class="{
                  'bg-green-500/20 text-green-400': project.state === 'started',
                  'bg-blue-500/20 text-blue-400': project.state === 'planned',
                  'bg-yellow-500/20 text-yellow-400': project.state === 'paused',
                  'bg-gray-500/20 text-[var(--linear-muted)]': !project.state || project.state === 'backlog',
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
            </div>
          </div>
        </div>
        
        <!-- Board view (grouped by state) -->
        <div v-else-if="viewMode === 'board'" class="h-full overflow-x-auto p-4">
          <div class="flex gap-4 h-full min-w-max">
            <div 
              v-for="state in ['backlog', 'planned', 'started', 'paused', 'completed']" 
              :key="state"
              class="w-72 flex-shrink-0 flex flex-col bg-[var(--linear-surface)] rounded-lg"
            >
              <div class="flex items-center gap-2 px-3 py-2 border-b border-[var(--linear-border-subtle)]">
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
                <span class="text-sm font-medium text-[var(--linear-text)] capitalize">{{ state }}</span>
                <span class="text-xs text-[var(--linear-muted)]">
                  {{ filteredProjects.filter(p => (p.state || 'backlog') === state).length }}
                </span>
              </div>
              
              <div class="flex-1 p-2 space-y-2 overflow-auto">
                <div
                  v-for="project in filteredProjects.filter(p => (p.state || 'backlog') === state)"
                  :key="project.id"
                  @click="selectProject(project)"
                  class="block p-3 bg-[var(--linear-elevated)] hover:bg-[var(--linear-surface)] rounded-lg transition-colors cursor-pointer"
                  :class="{ 'ring-1 ring-indigo-500/50': selectedProjectId === project.id }"
                >
                  <div class="flex items-center gap-2 mb-2">
                    <div 
                      class="w-6 h-6 rounded flex items-center justify-center"
                      :style="hasEmoji(project.icon) ? {} : { backgroundColor: project.color || '#6366f1' }"
                    >
                      <EmojiIcon 
                        :name="project.icon" 
                        :fallback="project.name.charAt(0)" 
                        size="sm"
                      />
                    </div>
                    <span class="text-sm font-medium text-[var(--linear-text)] truncate">{{ project.name }}</span>
                  </div>
                  
                  <p v-if="project.description" class="text-xs text-[var(--linear-muted)] line-clamp-2 mb-2">
                    {{ project.description }}
                  </p>
                  
                  <!-- Progress bar -->
                  <div v-if="project.progress" class="flex items-center gap-2">
                    <div class="flex-1 h-1 bg-[var(--linear-border)] rounded-full overflow-hidden">
                      <div 
                        class="h-full bg-indigo-500 rounded-full"
                        :style="{ width: `${project.progress}%` }"
                      ></div>
                    </div>
                    <span class="text-xs text-[var(--linear-muted)]">{{ Math.round(project.progress || 0) }}%</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Detail panel -->
    <ProjectDetailPanel 
      v-if="selectedProjectId"
      :project-id="selectedProjectId"
      @close="closeDetailPanel"
    />
  </div>
</template>
