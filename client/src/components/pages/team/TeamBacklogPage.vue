<script setup lang="ts">
import { computed, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useIssuesStore } from '@/stores/issues'
import { useUiStore } from '@/stores/ui'
import IssueListItem from '@/components/issues/IssueListItem.vue'
import Button from '@/components/ui/Button.vue'
import { Archive, Plus } from 'lucide-vue-next'

const route = useRoute()
const appStore = useAppStore()
const issuesStore = useIssuesStore()
const uiStore = useUiStore()

const teams = computed(() => appStore.teams)
const currentTeam = computed(() => {
  const teamKey = route.params.teamKey as string
  return teams.value.find(t => t.key === teamKey)
})

const loading = computed(() => issuesStore.loading)
const backlogIssues = computed(() => 
  issuesStore.issues.filter(i => 
    i.teamId === currentTeam.value?.id && i.status === 'backlog'
  )
)

// Fetch issues when team changes
watch(
  () => currentTeam.value?.id,
  async (teamId) => {
    if (teamId) {
      await issuesStore.fetchIssues({ teamId, status: 'backlog' })
    }
  },
  { immediate: true }
)
</script>

<template>
  <div class="h-full flex flex-col">
    <div v-if="loading" class="flex items-center justify-center py-16">
      <div class="animate-spin rounded-full h-8 w-8 border-2 border-primary-600 border-t-transparent"></div>
    </div>

    <div v-else-if="backlogIssues.length === 0" class="flex flex-col items-center justify-center py-16 flex-1">
      <div class="w-16 h-16 rounded-full bg-gray-100 dark:bg-gray-800 flex items-center justify-center mb-4">
        <Archive class="h-8 w-8 text-gray-400" />
      </div>
      <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-1">
        Backlog is empty
      </h3>
      <p class="text-sm text-gray-500 text-center max-w-sm mb-4">
        Issues that haven't been prioritized yet will appear here.
        Add issues to the backlog to plan future work.
      </p>
      <Button @click="uiStore.openCreateIssueModal()">
        <Plus class="h-4 w-4" />
        Create issue
      </Button>
    </div>

    <div v-else class="flex-1 overflow-auto">
      <div class="bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-800 m-4">
        <IssueListItem
          v-for="issue in backlogIssues"
          :key="issue.id"
          :issue="issue"
        />
      </div>
    </div>
  </div>
</template>
