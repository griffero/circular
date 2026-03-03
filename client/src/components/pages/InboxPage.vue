<script setup lang="ts">
import { ref, computed } from 'vue'
import { Inbox, CheckCheck, Archive } from 'lucide-vue-next'
import Button from '@/components/ui/Button.vue'

// Placeholder notifications
const notifications = ref<unknown[]>([])
const loading = ref(false)

const activeTab = ref<'all' | 'unread' | 'archived'>('all')
const hasNotifications = computed(() => notifications.value.length > 0)

const filteredNotifications = computed(() => {
  if (activeTab.value === 'all') return notifications.value
  // Placeholder data does not include unread/archive flags yet.
  return notifications.value
})

function markAllRead() {
  // TODO: Implement when notifications backend is ready
  console.log('Mark all notifications as read')
}

function archiveAll() {
  // TODO: Implement when notifications backend is ready
  console.log('Archive all notifications')
  notifications.value = []
}
</script>

<template>
  <div class="h-full flex flex-col bg-[var(--linear-bg)]">
    <!-- Header -->
    <div class="flex items-center justify-between px-4 py-2 border-b border-[var(--linear-border)]">
      <div class="flex items-center gap-1">
        <button 
          @click="activeTab = 'all'"
          :class="[
            'px-3 py-1.5 text-sm rounded-md transition-colors',
            activeTab === 'all' 
              ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]' 
              : 'text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-elevated)]'
          ]"
        >
          All
        </button>
        <button 
          @click="activeTab = 'unread'"
          :class="[
            'px-3 py-1.5 text-sm rounded-md transition-colors',
            activeTab === 'unread' 
              ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]' 
              : 'text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-elevated)]'
          ]"
        >
          Unread
        </button>
        <button 
          @click="activeTab = 'archived'"
          :class="[
            'px-3 py-1.5 text-sm rounded-md transition-colors',
            activeTab === 'archived' 
              ? 'bg-[var(--linear-elevated)] text-[var(--linear-text)]' 
              : 'text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-elevated)]'
          ]"
        >
          Archived
        </button>
      </div>
      
      <div class="flex items-center gap-2">
        <Button
          size="sm"
          variant="ghost"
          @click="markAllRead"
          :disabled="!hasNotifications"
        >
          <CheckCheck class="w-4 h-4" />
          Mark all read
        </Button>
        <Button
          size="sm"
          variant="ghost"
          @click="archiveAll"
          :disabled="!hasNotifications"
        >
          <Archive class="w-4 h-4" />
          Archive all
        </Button>
      </div>
    </div>

    <!-- Content -->
    <div class="flex-1 overflow-auto">
      <div v-if="loading" class="flex items-center justify-center py-16">
        <div class="animate-spin rounded-full h-8 w-8 border-2 border-indigo-500 border-t-transparent"></div>
      </div>

      <div v-else-if="filteredNotifications.length === 0" class="flex flex-col items-center justify-center py-16 px-6 text-center">
        <div class="w-16 h-16 rounded-full bg-[var(--linear-elevated)] flex items-center justify-center mb-4">
          <Inbox class="h-8 w-8 text-[var(--linear-muted)]" />
        </div>
        <h3 class="text-lg font-medium text-[var(--linear-text)] mb-1">
          All caught up!
        </h3>
        <p class="text-sm text-[var(--linear-muted)] max-w-sm">
          You have no notifications. We'll let you know when there's something new.
        </p>
      </div>

      <div v-else class="divide-y divide-[var(--linear-border)]">
        <!-- Notification items will go here -->
      </div>
    </div>
  </div>
</template>
