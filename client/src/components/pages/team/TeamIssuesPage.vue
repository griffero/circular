<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useUiStore } from '@/stores/ui'
import IssueList from '@/components/issues/IssueList.vue'
import type { Issue } from '@/types'

const route = useRoute()
const router = useRouter()
const appStore = useAppStore()
const uiStore = useUiStore()

const teams = computed(() => appStore.teams)
const currentTeam = computed(() => {
  const teamKey = route.params.teamKey as string
  return teams.value.find(t => t.key === teamKey)
})

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
