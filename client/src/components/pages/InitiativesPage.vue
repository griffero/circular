<script setup lang="ts">
import { Lightbulb, Plus } from 'lucide-vue-next'
</script>

<template>
  <div class="h-full flex flex-col bg-[#0d0d0d]">
    <div class="flex-1 flex flex-col items-center justify-center">
      <div class="w-16 h-16 rounded-full bg-[#1a1a1a] flex items-center justify-center mb-4">
        <Lightbulb class="w-8 h-8 text-gray-500" />
      </div>
      <h2 class="text-lg font-medium text-white mb-2">No initiatives yet</h2>
      <p class="text-sm text-gray-500 text-center max-w-sm mb-4">
        Initiatives help you track larger goals across multiple projects and teams.
      </p>
      <button class="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-sm rounded-lg transition-colors">
        <Plus class="w-4 h-4" />
        Create initiative
      </button>
    </div>
  </div>
</template>
