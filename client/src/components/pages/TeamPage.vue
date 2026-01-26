<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useUiStore } from '@/stores/ui'
import { cn } from '@/utils/cn'
import Button from '@/components/ui/Button.vue'
import {
  LayoutList,
  Columns3,
  Clock,
  CircleDot,
  Plus,
  Filter,
  MoreHorizontal
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const appStore = useAppStore()
const uiStore = useUiStore()

const teams = computed(() => appStore.teams)
const currentTeam = computed(() => {
  const teamKey = route.params.teamKey as string
  return teams.value.find(t => t.key === teamKey)
})

interface Tab {
  name: string
  to: string
  icon: typeof LayoutList
  active: boolean
}

const tabs = computed<Tab[]>(() => {
  if (!currentTeam.value) return []
  const base = `/team/${currentTeam.value.key}`
  return [
    { name: 'Active', to: `${base}/active`, icon: CircleDot, active: route.name === 'team-active' },
    { name: 'Backlog', to: `${base}/backlog`, icon: LayoutList, active: route.name === 'team-backlog' },
    { name: 'Board', to: `${base}/board`, icon: Columns3, active: route.name === 'team-board' },
    { name: 'Cycles', to: `${base}/cycles`, icon: Clock, active: route.name === 'team-cycles' },
  ]
})
</script>

<template>
  <div v-if="currentTeam" class="flex flex-col h-full">
    <!-- Team header with tabs -->
    <div class="flex items-center justify-between px-4 py-2 border-b border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900">
      <div class="flex items-center gap-4">
        <div class="flex items-center gap-2">
          <div 
            class="w-6 h-6 rounded flex items-center justify-center text-white text-xs font-bold"
            :style="{ backgroundColor: currentTeam.color || '#6b7280' }"
          >
            {{ currentTeam.key.charAt(0) }}
          </div>
          <h2 class="font-medium text-gray-900 dark:text-gray-100">{{ currentTeam.name }}</h2>
        </div>

        <nav class="flex items-center gap-1">
          <router-link
            v-for="tab in tabs"
            :key="tab.name"
            :to="tab.to"
            :class="cn(
              'flex items-center gap-1.5 px-3 py-1.5 text-sm rounded-md',
              'transition-colors',
              tab.active
                ? 'bg-gray-100 dark:bg-gray-800 text-gray-900 dark:text-gray-100'
                : 'text-gray-500 hover:text-gray-900 dark:hover:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-800/50'
            )"
          >
            <component :is="tab.icon" class="h-4 w-4" />
            {{ tab.name }}
          </router-link>
        </nav>
      </div>

      <div class="flex items-center gap-2">
        <Button size="sm" variant="ghost" @click="uiStore.toggleFilters()">
          <Filter class="h-4 w-4" />
          Filter
        </Button>
        <Button size="sm" @click="uiStore.openCreateIssueModal()">
          <Plus class="h-4 w-4" />
          New issue
        </Button>
        <button class="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-md">
          <MoreHorizontal class="h-4 w-4 text-gray-500" />
        </button>
      </div>
    </div>

    <!-- Team content -->
    <div class="flex-1 overflow-auto">
      <router-view />
    </div>
  </div>

  <div v-else class="flex items-center justify-center h-full">
    <div class="text-center">
      <p class="text-gray-500">Team not found</p>
      <Button variant="ghost" class="mt-4" @click="router.push('/')">
        Go back home
      </Button>
    </div>
  </div>
</template>
