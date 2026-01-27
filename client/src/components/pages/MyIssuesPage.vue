<script setup lang="ts">
import { ref, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { User, Filter, LayoutList, Columns3 } from 'lucide-vue-next'

const authStore = useAuthStore()
const user = computed(() => authStore.user)

// Placeholder issues
const issues = ref<unknown[]>([])
const loading = ref(false)

const hasIssues = computed(() => issues.value.length > 0)

const activeTab = ref<'assigned' | 'created' | 'subscribed'>('assigned')
const viewMode = ref<'list' | 'board'>('list')
</script>

<template>
  <div class="h-full flex flex-col bg-[#0d0d0d]">
    <!-- Header -->
    <div class="flex items-center justify-between px-4 py-2 border-b border-[#1f1f1f]">
      <div class="flex items-center gap-1">
        <button 
          @click="activeTab = 'assigned'"
          :class="[
            'px-3 py-1.5 text-sm rounded-md transition-colors',
            activeTab === 'assigned' 
              ? 'bg-[#1a1a1a] text-white' 
              : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
          ]"
        >
          Assigned to me
        </button>
        <button 
          @click="activeTab = 'created'"
          :class="[
            'px-3 py-1.5 text-sm rounded-md transition-colors',
            activeTab === 'created' 
              ? 'bg-[#1a1a1a] text-white' 
              : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
          ]"
        >
          Created by me
        </button>
        <button 
          @click="activeTab = 'subscribed'"
          :class="[
            'px-3 py-1.5 text-sm rounded-md transition-colors',
            activeTab === 'subscribed' 
              ? 'bg-[#1a1a1a] text-white' 
              : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
          ]"
        >
          Subscribed
        </button>
      </div>
      
      <div class="flex items-center gap-2">
        <!-- View mode toggle -->
        <div class="flex items-center gap-0.5 p-0.5 bg-[#1a1a1a] rounded-md">
          <button
            @click="viewMode = 'list'"
            :class="[
              'p-1.5 rounded',
              viewMode === 'list'
                ? 'bg-[#2a2a2a] text-white'
                : 'text-gray-400 hover:text-white'
            ]"
          >
            <LayoutList class="h-4 w-4" />
          </button>
          <button
            @click="viewMode = 'board'"
            :class="[
              'p-1.5 rounded',
              viewMode === 'board'
                ? 'bg-[#2a2a2a] text-white'
                : 'text-gray-400 hover:text-white'
            ]"
          >
            <Columns3 class="h-4 w-4" />
          </button>
        </div>
        
        <button class="flex items-center gap-1.5 px-3 py-1.5 text-sm text-gray-400 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors">
          <Filter class="h-4 w-4" />
          Filter
        </button>
      </div>
    </div>

    <!-- Content -->
    <div class="flex-1 overflow-auto">
      <div v-if="loading" class="flex items-center justify-center py-16">
        <div class="animate-spin rounded-full h-8 w-8 border-2 border-indigo-500 border-t-transparent"></div>
      </div>

      <div v-else-if="!hasIssues" class="flex flex-col items-center justify-center py-16">
        <div class="w-16 h-16 rounded-full bg-[#1a1a1a] flex items-center justify-center mb-4">
          <User class="h-8 w-8 text-gray-500" />
        </div>
        <h3 class="text-lg font-medium text-white mb-1">
          No issues yet
        </h3>
        <p class="text-sm text-gray-500 text-center max-w-sm">
          Issues assigned to you will appear here.
          Get started by creating or being assigned an issue.
        </p>
      </div>

      <div v-else>
        <!-- Issue list/board will go here -->
      </div>
    </div>
  </div>
</template>
