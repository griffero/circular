<script setup lang="ts">
import { computed } from 'vue'
import { useAppStore } from '@/stores/app'
import { FolderKanban, Plus } from 'lucide-vue-next'

const appStore = useAppStore()
const projects = computed(() => appStore.projects)
</script>

<template>
  <div class="h-full flex flex-col bg-[#0d0d0d]">
    <!-- Empty state -->
    <div v-if="projects.length === 0" class="flex-1 flex flex-col items-center justify-center">
      <div class="w-16 h-16 rounded-full bg-[#1a1a1a] flex items-center justify-center mb-4">
        <FolderKanban class="w-8 h-8 text-gray-500" />
      </div>
      <h2 class="text-lg font-medium text-white mb-2">No projects yet</h2>
      <p class="text-sm text-gray-500 text-center max-w-sm mb-4">
        Projects help you organize issues around a specific goal or feature.
      </p>
      <button class="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-sm rounded-lg transition-colors">
        <Plus class="w-4 h-4" />
        Create project
      </button>
    </div>

    <!-- Projects list -->
    <div v-else class="p-4">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-lg font-medium text-white">Projects</h2>
        <button class="flex items-center gap-2 px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-sm rounded-lg transition-colors">
          <Plus class="w-4 h-4" />
          New project
        </button>
      </div>
      <div class="space-y-2">
        <router-link
          v-for="project in projects"
          :key="project.id"
          :to="`/project/${project.slug}`"
          class="flex items-center gap-3 p-3 bg-[#1a1a1a] hover:bg-[#222] rounded-lg transition-colors"
        >
          <div 
            class="w-8 h-8 rounded flex items-center justify-center"
            :style="{ backgroundColor: project.color || '#6366f1' }"
          >
            <FolderKanban class="w-4 h-4 text-white" />
          </div>
          <div>
            <p class="text-sm font-medium text-white">{{ project.name }}</p>
            <p v-if="project.description" class="text-xs text-gray-500">{{ project.description }}</p>
          </div>
        </router-link>
      </div>
    </div>
  </div>
</template>
