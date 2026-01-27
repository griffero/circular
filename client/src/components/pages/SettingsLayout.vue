<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { cn } from '@/utils/cn'
import {
  ChevronLeft,
  Settings,
  Users,
  UsersRound,
  Tags,
  User,
  Bell,
  Shield,
  Link2
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const user = computed(() => authStore.user)
const isAdmin = computed(() => authStore.isAdmin)

interface NavItem {
  name: string
  to: string
  icon: typeof Settings
  routeName: string
  adminOnly?: boolean
}

interface NavSection {
  title: string
  items: NavItem[]
}

const navSections = computed<NavSection[]>(() => [
  {
    title: 'Account',
    items: [
      { name: 'Preferences', to: '/settings/preferences', icon: Settings, routeName: 'preferences-settings' },
      { name: 'Profile', to: '/settings/profile', icon: User, routeName: 'profile-settings' },
      // { name: 'Notifications', to: '/settings/notifications', icon: Bell, routeName: 'notifications-settings' },
    ]
  },
  {
    title: 'Workspace',
    items: [
      { name: 'General', to: '/settings', icon: Settings, routeName: 'general-settings' },
      { name: 'Members', to: '/settings/members', icon: Users, routeName: 'members-settings', adminOnly: true },
      { name: 'Teams', to: '/settings/teams', icon: UsersRound, routeName: 'teams-settings' },
      { name: 'Labels', to: '/settings/labels', icon: Tags, routeName: 'labels-settings' },
    ]
  }
])

const filteredSections = computed(() => {
  return navSections.value.map(section => ({
    ...section,
    items: section.items.filter(item => !item.adminOnly || isAdmin.value)
  })).filter(section => section.items.length > 0)
})

function isActive(routeName: string) {
  return route.name === routeName
}

function goBack() {
  router.push('/')
}
</script>

<template>
  <div class="h-screen bg-[#0d0d0d] flex overflow-hidden">
    <!-- Settings Sidebar -->
    <aside class="w-[240px] h-full flex flex-col bg-[#0d0d0d] border-r border-[#1f1f1f]">
      <!-- Back to app -->
      <div class="px-3 py-3">
        <button
          @click="goBack"
          class="flex items-center gap-2 px-2 py-1.5 text-[13px] text-gray-400 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors w-full"
        >
          <ChevronLeft class="w-4 h-4" />
          Back to app
        </button>
      </div>

      <!-- Navigation -->
      <nav class="flex-1 overflow-y-auto px-3 pb-4">
        <div v-for="section in filteredSections" :key="section.title" class="mb-6">
          <h3 class="px-2 mb-2 text-[11px] font-medium text-gray-500 uppercase tracking-wider">
            {{ section.title }}
          </h3>
          <div class="space-y-0.5">
            <router-link
              v-for="item in section.items"
              :key="item.name"
              :to="item.to"
              :class="cn(
                'flex items-center gap-2.5 px-2 py-1.5 rounded text-[13px] transition-colors',
                isActive(item.routeName)
                  ? 'bg-[#1a1a1a] text-white'
                  : 'text-gray-400 hover:bg-[#1a1a1a] hover:text-white'
              )"
            >
              <component :is="item.icon" class="w-4 h-4" />
              {{ item.name }}
            </router-link>
          </div>
        </div>
      </nav>

      <!-- User info at bottom -->
      <div class="px-3 py-3 border-t border-[#1f1f1f]">
        <div class="flex items-center gap-2 px-2">
          <div class="w-7 h-7 rounded-full bg-indigo-600 flex items-center justify-center">
            <span class="text-xs font-medium text-white">
              {{ user?.name?.charAt(0)?.toUpperCase() || '?' }}
            </span>
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-[13px] text-white truncate">{{ user?.name }}</p>
            <p class="text-[11px] text-gray-500 truncate">{{ user?.email }}</p>
          </div>
        </div>
      </div>
    </aside>

    <!-- Settings Content -->
    <main class="flex-1 overflow-auto">
      <router-view />
    </main>
  </div>
</template>
