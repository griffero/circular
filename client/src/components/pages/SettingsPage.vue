<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { cn } from '@/utils/cn'
import {
  Settings,
  Users,
  UsersRound,
  Tags
} from 'lucide-vue-next'

const route = useRoute()
const authStore = useAuthStore()

const isAdmin = computed(() => authStore.isAdmin)

interface NavItem {
  name: string
  to: string
  icon: typeof Settings
  active: boolean
  adminOnly?: boolean
}

const navItems = computed<NavItem[]>(() => {
  return [
    { name: 'General', to: '/settings', icon: Settings, active: route.name === 'general-settings' },
    { name: 'Members', to: '/settings/members', icon: Users, active: route.name === 'members-settings', adminOnly: true },
    { name: 'Teams', to: '/settings/teams', icon: UsersRound, active: route.name === 'teams-settings' },
    { name: 'Labels', to: '/settings/labels', icon: Tags, active: route.name === 'labels-settings' },
  ]
})

const visibleNavItems = computed(() => {
  return navItems.value.filter(item => !item.adminOnly || isAdmin.value)
})
</script>

<template>
  <div class="flex h-full">
    <!-- Settings sidebar -->
    <aside class="w-56 border-r border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900/50">
      <div class="p-4">
        <h2 class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">
          Settings
        </h2>
      <nav class="space-y-1">
        <router-link
          v-for="item in visibleNavItems"
          :key="item.name"
          :to="item.to"
          :class="cn(
            'flex items-center gap-2 px-3 py-2 rounded-md text-sm',
            'transition-colors',
            item.active
              ? 'bg-gray-200 dark:bg-gray-800 text-gray-900 dark:text-gray-100'
              : 'text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800'
          )"
        >
          <component :is="item.icon" class="h-4 w-4" />
          {{ item.name }}
        </router-link>
      </nav>
      </div>
    </aside>

    <!-- Settings content -->
    <div class="flex-1 overflow-auto">
      <router-view />
    </div>
  </div>
</template>
