<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useAppStore } from '@/stores/app'

const route = useRoute()
const appStore = useAppStore()

const teams = computed(() => appStore.teams)
const currentTeam = computed(() => {
  const teamKey = route.params.teamKey as string
  return teams.value.find(t => t.key === teamKey)
})

const teamViews = computed(() => {
  const teamId = currentTeam.value?.id
  if (!teamId) return []
  return appStore.projects
    .filter(project => project.teams?.some(team => team.id === teamId))
    .map(project => ({
      id: project.id,
      name: project.name,
      description: project.description || `Issues related to ${project.name}`,
    }))
})
</script>

<template>
  <div class="h-full bg-[var(--linear-bg)] overflow-auto">
    <div class="h-8 px-3 border-b border-[var(--linear-border-subtle)] bg-[var(--linear-elevated)] text-[13px] text-[var(--linear-text)] font-medium flex items-center">
      {{ currentTeam?.name }} views
    </div>

    <div v-if="teamViews.length === 0" class="h-full flex items-center justify-center text-[var(--linear-muted)] text-sm">
      No views for this team
    </div>

    <div v-else class="divide-y divide-[var(--linear-border-subtle)]">
      <div v-for="view in teamViews" :key="view.id" class="px-3 py-2">
        <p class="text-[13px] font-medium text-[var(--linear-text)]">{{ view.name }}</p>
        <p class="text-[12px] text-[var(--linear-muted)] truncate">{{ view.description }}</p>
      </div>
    </div>
  </div>
</template>
