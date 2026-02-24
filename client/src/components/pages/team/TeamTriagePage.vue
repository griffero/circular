<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useIssuesStore } from '@/stores/issues'
import IssueListItem from '@/components/issues/IssueListItem.vue'
import { useCurrentTeam } from '@/composables/useCurrentTeam'

const router = useRouter()
const issuesStore = useIssuesStore()
const { currentTeam } = useCurrentTeam()

const loading = ref(false)

const triageIssues = computed(() => {
  return issuesStore.issues.filter((issue) => {
    if (issue.teamId !== currentTeam.value?.id) return false
    const stateType = issue.workflowState?.stateType
    return stateType === 'triage' || stateType === 'backlog' || issue.status === 'backlog'
  })
})

watch(
  () => currentTeam.value?.id,
  async (teamId) => {
    if (!teamId) return
    loading.value = true
    try {
      await issuesStore.fetchIssues({ teamId, sort: 'updated_at', direction: 'desc', perPage: 500 })
    } finally {
      loading.value = false
    }
  },
  { immediate: true }
)

function openIssue(issueId: string) {
  router.push(`/issue/${issueId}`)
}
</script>

<template>
  <div class="h-full bg-[var(--linear-bg)] overflow-auto p-2">
    <div v-if="loading" class="h-full flex items-center justify-center">
      <div class="animate-spin rounded-full h-8 w-8 border-2 border-[var(--linear-accent)] border-t-transparent"></div>
    </div>

    <div v-else-if="triageIssues.length === 0" class="h-full flex items-center justify-center text-[var(--linear-muted)] text-sm">
      No issues in triage
    </div>

    <div v-else class="linear-panel overflow-hidden">
      <IssueListItem
        v-for="issue in triageIssues"
        :key="issue.id"
        :issue="issue"
        @click="openIssue(issue.id)"
      />
    </div>
  </div>
</template>
