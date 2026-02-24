import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useAppStore } from '@/stores/app'

function normalize(value?: string | null): string {
  return String(value || '').trim().toLowerCase()
}

export function useCurrentTeam() {
  const route = useRoute()
  const appStore = useAppStore()

  const currentTeam = computed(() => {
    const raw = route.params.teamKey as string | undefined
    const key = normalize(raw)
    if (!key) return null

    return (
      appStore.teams.find((team) => normalize(team.key) === key) ||
      appStore.teams.find((team) => normalize(team.name) === key) ||
      null
    )
  })

  return { currentTeam }
}

