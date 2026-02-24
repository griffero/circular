<script setup lang="ts">
import { computed, watch } from 'vue'
import { useIssuesStore } from '@/stores/issues'
import { useUiStore } from '@/stores/ui'
import IssueListItem from '@/components/issues/IssueListItem.vue'
import Button from '@/components/ui/Button.vue'
import { Archive, Plus } from 'lucide-vue-next'
import { useCurrentTeam } from '@/composables/useCurrentTeam'

const issuesStore = useIssuesStore()
const uiStore = useUiStore()
const { currentTeam } = useCurrentTeam()

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
  <div class="h-full flex flex-col bg-[var(--linear-bg)]">
    <div v-if="loading" class="flex items-center justify-center py-16">
      <div class="animate-spin rounded-full h-8 w-8 border-2 border-[var(--linear-accent)] border-t-transparent"></div>
    </div>

    <div v-else-if="backlogIssues.length === 0" class="flex flex-col items-center justify-center py-16 flex-1">
      <div class="w-16 h-16 rounded-full bg-[var(--linear-elevated)] border border-[var(--linear-border)] flex items-center justify-center mb-4">
        <Archive class="h-8 w-8 text-[var(--linear-muted)]" />
      </div>
      <h3 class="text-lg font-medium text-[var(--linear-text)] mb-1">
        Backlog is empty
      </h3>
      <p class="text-sm text-[var(--linear-muted)] text-center max-w-sm mb-4">
        Issues that haven't been prioritized yet will appear here.
        Add issues to the backlog to plan future work.
      </p>
      <Button @click="uiStore.openCreateIssueModal()">
        <Plus class="h-4 w-4" />
        Create issue
      </Button>
    </div>

    <div v-else class="flex-1 overflow-auto">
      <div class="linear-panel m-4">
        <IssueListItem
          v-for="issue in backlogIssues"
          :key="issue.id"
          :issue="issue"
        />
      </div>
    </div>
  </div>
</template>
