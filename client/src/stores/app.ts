import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { Team, Project } from '@/types'
import { api } from '@/api/client'

export interface ProjectUpdate {
  id: string
  body: string
  health: string | null
  editedAt: string | null
  createdAt: string
  updatedAt: string
  project: Project
  user: {
    id: string
    name: string
    displayName: string | null
    email: string
    avatarUrl: string | null
  }
}

export const useAppStore = defineStore('app', () => {
  const teams = ref<Team[]>([])
  const projects = ref<Project[]>([])
  const projectUpdates = ref<ProjectUpdate[]>([])
  const users = ref<{ id: string; name: string; email: string; avatarUrl?: string }[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchTeams() {
    try {
      loading.value = true
      const data = await api.get<{ teams: Team[] }>('/api/v1/teams')
      teams.value = data.teams
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch teams'
    } finally {
      loading.value = false
    }
  }

  async function fetchProjects() {
    try {
      loading.value = true
      const data = await api.get<{ projects: Project[] }>('/api/v1/projects')
      projects.value = data.projects
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch projects'
    } finally {
      loading.value = false
    }
  }

  async function fetchUsers() {
    try {
      const data = await api.get<{ users: typeof users.value }>('/api/v1/users')
      users.value = data.users
    } catch (err) {
      console.error('Failed to fetch users:', err)
    }
  }

  async function fetchProjectUpdates() {
    try {
      const data = await api.get<{ project_updates: ProjectUpdate[] }>('/api/v1/project_updates')
      projectUpdates.value = data.project_updates
    } catch (err) {
      console.error('Failed to fetch project updates:', err)
    }
  }

  async function createTeam(teamData: { name: string; key: string; description?: string; color?: string }) {
    try {
      loading.value = true
      const data = await api.post<{ team: Team }>('/api/v1/teams', {
        team: teamData
      })
      teams.value.push(data.team)
      return data.team
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to create team'
      throw err
    } finally {
      loading.value = false
    }
  }

  async function createProject(projectData: { name: string; slug?: string; description?: string; color?: string; privacy?: string }) {
    try {
      loading.value = true
      const data = await api.post<{ project: Project }>('/api/v1/projects', {
        project: projectData
      })
      projects.value.push(data.project)
      return data.project
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to create project'
      throw err
    } finally {
      loading.value = false
    }
  }

  function reset() {
    teams.value = []
    projects.value = []
    projectUpdates.value = []
    users.value = []
    error.value = null
  }

  return {
    teams,
    projects,
    projectUpdates,
    users,
    loading,
    error,
    fetchTeams,
    fetchProjects,
    fetchProjectUpdates,
    fetchUsers,
    createTeam,
    createProject,
    reset
  }
})
