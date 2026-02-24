<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useUiStore } from '@/stores/ui'
import IssueList from '@/components/issues/IssueList.vue'
import type { Issue } from '@/types'
import { useCurrentTeam } from '@/composables/useCurrentTeam'

const router = useRouter()
const uiStore = useUiStore()
const { currentTeam } = useCurrentTeam()

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
    :show-filters="true"
    empty-title="No issues"
    empty-description="Issues from this team will appear here."
    @issue-click="handleIssueClick"
    @create-issue="handleCreateIssue"
  />
</template>
