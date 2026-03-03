<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useUiStore } from '@/stores/ui'
import IssueList from '@/components/issues/IssueList.vue'
import type { Issue } from '@/types'
import { useCurrentTeam } from '@/composables/useCurrentTeam'

const router = useRouter()
const uiStore = useUiStore()
const { currentTeam } = useCurrentTeam()

const baseFilters = computed(() => ({
  workflowStateType: 'backlog' as const,
  sort: 'updated_at' as const,
  direction: 'desc' as const,
}))

function handleIssueClick(issue: Issue) {
  router.push(`/issue/${issue.id}`)
}

function handleCreateIssue() {
  uiStore.openCreateIssueModal()
}
</script>

<template>
  <IssueList
    v-if="currentTeam"
    :team-id="currentTeam.id"
    :base-filters="baseFilters"
    :show-filters="true"
    empty-title="Backlog is empty"
    empty-description="Issues that haven't been prioritized yet will appear here."
    @issue-click="handleIssueClick"
    @create-issue="handleCreateIssue"
  />
</template>
