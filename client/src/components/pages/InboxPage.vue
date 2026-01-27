<script setup lang="ts">
import { ref, computed } from 'vue'
import { Inbox, CheckCheck, Archive, Bell } from 'lucide-vue-next'

// Placeholder notifications
const notifications = ref<unknown[]>([])
const loading = ref(false)

const hasNotifications = computed(() => notifications.value.length > 0)

const activeTab = ref<'all' | 'unread' | 'archived'>('all')
</script>

<template>
  <div class="h-full flex flex-col bg-[#0d0d0d]">
    <!-- Header -->
    <div class="flex items-center justify-between px-4 py-2 border-b border-[#1f1f1f]">
      <div class="flex items-center gap-1">
        <button 
          @click="activeTab = 'all'"
          :class="[
            'px-3 py-1.5 text-sm rounded-md transition-colors',
            activeTab === 'all' 
              ? 'bg-[#1a1a1a] text-white' 
              : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
          ]"
        >
          All
        </button>
        <button 
          @click="activeTab = 'unread'"
          :class="[
            'px-3 py-1.5 text-sm rounded-md transition-colors',
            activeTab === 'unread' 
              ? 'bg-[#1a1a1a] text-white' 
              : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
          ]"
        >
          Unread
        </button>
        <button 
          @click="activeTab = 'archived'"
          :class="[
            'px-3 py-1.5 text-sm rounded-md transition-colors',
            activeTab === 'archived' 
              ? 'bg-[#1a1a1a] text-white' 
              : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
          ]"
        >
          Archived
        </button>
      </div>
      
      <div class="flex items-center gap-2">
        <button class="flex items-center gap-1.5 px-3 py-1.5 text-sm text-gray-400 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors">
          <CheckCheck class="w-4 h-4" />
          Mark all read
        </button>
        <button class="flex items-center gap-1.5 px-3 py-1.5 text-sm text-gray-400 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors">
          <Archive class="w-4 h-4" />
          Archive all
        </button>
      </div>
    </div>

    <!-- Content -->
    <div class="flex-1 overflow-auto">
      <div v-if="loading" class="flex items-center justify-center py-16">
        <div class="animate-spin rounded-full h-8 w-8 border-2 border-indigo-500 border-t-transparent"></div>
      </div>

      <div v-else-if="!hasNotifications" class="flex flex-col items-center justify-center py-16">
        <div class="w-16 h-16 rounded-full bg-[#1a1a1a] flex items-center justify-center mb-4">
          <Inbox class="h-8 w-8 text-gray-500" />
        </div>
        <h3 class="text-lg font-medium text-white mb-1">
          All caught up!
        </h3>
        <p class="text-sm text-gray-500 text-center max-w-sm">
          You have no notifications. We'll let you know when there's something new.
        </p>
      </div>

      <div v-else class="divide-y divide-[#1f1f1f]">
        <!-- Notification items will go here -->
      </div>
    </div>
  </div>
</template>
