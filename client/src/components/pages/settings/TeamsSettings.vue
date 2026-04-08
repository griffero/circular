<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useAppStore } from '@/stores/app'
import type { Team, TeamMembership } from '@/types'
import Button from '@/components/ui/Button.vue'
import Input from '@/components/ui/Input.vue'
import Modal from '@/components/ui/Modal.vue'
import Avatar from '@/components/ui/Avatar.vue'
import OriginBadge from '@/components/ui/OriginBadge.vue'
import { isFromLinear } from '@/composables/useOrigin'
import { api } from '@/api/client'
import { Plus, Users, Pencil, Trash2, UserPlus, X } from 'lucide-vue-next'

const authStore = useAuthStore()
const appStore = useAppStore()

const teams = computed(() => appStore.teams)
const isAdmin = computed(() => authStore.isAdmin)
const loading = computed(() => appStore.loading)

onMounted(() => {
  if (teams.value.length === 0) appStore.fetchTeams()
})

const colors = [
  '#ef4444', '#f97316', '#f59e0b', '#eab308', '#84cc16',
  '#22c55e', '#10b981', '#14b8a6', '#06b6d4', '#0ea5e9',
  '#3b82f6', '#6366f1', '#8b5cf6', '#a855f7', '#d946ef',
  '#ec4899', '#f43f5e',
]

// Create team modal
const showCreateModal = ref(false)
const newTeamName = ref('')
const newTeamKey = ref('')
const newTeamColor = ref('#6366f1')
const creating = ref(false)
const createError = ref('')

watch(newTeamName, (name) => {
  if (name && !newTeamKey.value) {
    newTeamKey.value = name
      .replace(/[^a-zA-Z0-9]/g, '')
      .toUpperCase()
      .substring(0, 5)
  }
})

async function handleCreate() {
  if (!newTeamName.value || !newTeamKey.value) return
  creating.value = true
  createError.value = ''
  try {
    await appStore.createTeam({
      name: newTeamName.value,
      key: newTeamKey.value.toUpperCase(),
      color: newTeamColor.value,
    })
    showCreateModal.value = false
    newTeamName.value = ''
    newTeamKey.value = ''
    newTeamColor.value = '#6366f1'
  } catch (err) {
    createError.value = err instanceof Error ? err.message : 'Failed to create team'
  } finally {
    creating.value = false
  }
}

// Edit team modal
const showEditModal = ref(false)
const editingTeam = ref<Team | null>(null)
const editTeamName = ref('')
const editTeamColor = ref('')
const editSaving = ref(false)
const editError = ref('')

function openEditModal(team: Team) {
  editingTeam.value = team
  editTeamName.value = team.name
  editTeamColor.value = team.color || '#6366f1'
  editError.value = ''
  showEditModal.value = true
}

async function handleEdit() {
  if (!editingTeam.value || !editTeamName.value) return
  editSaving.value = true
  editError.value = ''
  try {
    await appStore.updateTeam(editingTeam.value.key, {
      name: editTeamName.value,
      color: editTeamColor.value,
    })
    showEditModal.value = false
    editingTeam.value = null
  } catch (err) {
    editError.value = err instanceof Error ? err.message : 'Failed to update team'
  } finally {
    editSaving.value = false
  }
}

// Delete team
const showDeleteConfirm = ref(false)
const deletingTeam = ref<Team | null>(null)
const deleting = ref(false)

function openDeleteConfirm(team: Team) {
  deletingTeam.value = team
  showDeleteConfirm.value = true
}

async function handleDelete() {
  if (!deletingTeam.value) return
  deleting.value = true
  try {
    await appStore.deleteTeam(deletingTeam.value.key)
    showDeleteConfirm.value = false
    deletingTeam.value = null
  } catch (err) {
    console.error('Failed to delete team:', err)
  } finally {
    deleting.value = false
  }
}

// Members modal
const showMembersModal = ref(false)
const membersTeam = ref<Team | null>(null)
const teamMembers = ref<TeamMembership[]>([])
const membersLoading = ref(false)
const allUsers = computed(() => appStore.users)

const memberSearch = ref('')

const nonMembers = computed(() => {
  const memberUserIds = new Set(teamMembers.value.map(m => m.user?.id))
  const available = allUsers.value.filter(u => !memberUserIds.has(u.id))
  if (!memberSearch.value) return available
  const q = memberSearch.value.toLowerCase()
  return available.filter(u => u.name.toLowerCase().includes(q) || u.email.toLowerCase().includes(q))
})

async function openMembersModal(team: Team) {
  membersTeam.value = team
  memberSearch.value = ''
  showMembersModal.value = true
  membersLoading.value = true
  try {
    if (allUsers.value.length === 0) await appStore.fetchUsers()
    const data = await api.get<{ members: TeamMembership[] }>(`/api/v1/teams/${team.key}/members`)
    teamMembers.value = data.members
  } catch (err) {
    console.error('Failed to fetch members:', err)
  } finally {
    membersLoading.value = false
  }
}

async function addMember(userId: string) {
  if (!membersTeam.value) return
  try {
    const data = await api.post<{ member: TeamMembership }>(`/api/v1/teams/${membersTeam.value.key}/members`, {
      user_id: userId,
      role: 'member'
    })
    teamMembers.value.push(data.member)
  } catch (err) {
    console.error('Failed to add member:', err)
  }
}

async function removeMember(userId: string) {
  if (!membersTeam.value) return
  try {
    await api.delete(`/api/v1/teams/${membersTeam.value.key}/members/${userId}`)
    teamMembers.value = teamMembers.value.filter(m => m.user?.id !== userId && m.userId !== userId)
  } catch (err) {
    console.error('Failed to remove member:', err)
  }
}
</script>

<template>
  <div class="p-6 max-w-4xl mx-auto bg-[var(--linear-bg)] min-h-full">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-xl font-semibold text-[var(--linear-text)] mb-1">
          Teams
        </h1>
        <p class="text-sm text-[var(--linear-muted)]">
          Manage teams and their configuration
        </p>
      </div>
      <Button v-if="isAdmin" @click="showCreateModal = true">
        <Plus class="h-4 w-4" />
        Create team
      </Button>
    </div>

    <!-- Teams list -->
    <div v-if="loading" class="text-center py-12">
      <div class="animate-spin rounded-full h-8 w-8 border-2 border-[var(--linear-accent)] border-t-transparent mx-auto"></div>
    </div>

    <div v-else-if="teams.length === 0" class="text-center py-12">
      <Users class="h-12 w-12 text-[var(--linear-muted)] mx-auto mb-4" />
      <h3 class="text-lg font-medium text-[var(--linear-text)] mb-2">No teams yet</h3>
      <p class="text-[var(--linear-muted)] mb-4">Create your first team to start organizing work</p>
      <Button v-if="isAdmin" @click="showCreateModal = true">
        <Plus class="h-4 w-4" />
        Create team
      </Button>
    </div>

    <div v-else class="linear-panel divide-y divide-[var(--linear-border-subtle)]">
      <div
        v-for="team in teams"
        :key="team.id"
        class="group flex items-center justify-between px-4 py-3 hover:bg-[var(--linear-surface)]"
      >
        <div class="flex items-center gap-3">
          <div
            class="w-10 h-10 rounded-lg flex items-center justify-center text-white font-bold"
            :style="{ backgroundColor: team.color || '#6b7280' }"
          >
            {{ team.key.substring(0, 2) }}
          </div>
          <div>
            <div class="flex items-center gap-2">
              <h3 class="font-medium text-[var(--linear-text)]">{{ team.name }}</h3>
              <OriginBadge :linear-id="team.linearId" />
            </div>
            <p class="text-sm text-[var(--linear-muted)]">{{ team.key }}</p>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <button
            v-if="isAdmin"
            @click="openMembersModal(team)"
            class="p-2 text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-surface)] rounded-md"
            title="Manage members"
          >
            <Users class="h-4 w-4" />
          </button>
          <template v-if="isAdmin && !isFromLinear(team)">
            <button
              @click="openEditModal(team)"
              class="p-2 text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-surface)] rounded-md"
              title="Edit team"
            >
              <Pencil class="h-4 w-4" />
            </button>
            <button
              @click="openDeleteConfirm(team)"
              class="p-2 text-[var(--linear-muted)] hover:text-red-400 hover:bg-[var(--linear-surface)] rounded-md"
              title="Delete team"
            >
              <Trash2 class="h-4 w-4" />
            </button>
          </template>
        </div>
      </div>
    </div>

    <!-- Create team modal -->
    <Modal :open="showCreateModal" @close="showCreateModal = false" title="Create team">
      <form @submit.prevent="handleCreate" class="space-y-4">
        <div v-if="createError" class="p-3 bg-red-500/10 border border-red-500/20 rounded-lg text-sm text-red-300">
          {{ createError }}
        </div>

        <div>
          <label class="block text-sm font-medium text-[var(--linear-text)] mb-1">
            Team name
          </label>
          <Input
            v-model="newTeamName"
            type="text"
            placeholder="Engineering"
            required
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-[var(--linear-text)] mb-1">
            Team identifier
          </label>
          <Input
            v-model="newTeamKey"
            type="text"
            placeholder="ENG"
            maxlength="5"
            required
          />
          <p class="mt-1 text-xs text-[var(--linear-muted)]">
            This will be used as a prefix for issue identifiers (e.g., ENG-123)
          </p>
        </div>

        <div>
          <label class="block text-sm font-medium text-[var(--linear-text)] mb-2">
            Color
          </label>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="color in colors"
              :key="color"
              type="button"
              @click="newTeamColor = color"
              :class="[
                'w-8 h-8 rounded-lg border-2 transition-transform',
                newTeamColor === color ? 'border-white scale-110' : 'border-transparent hover:scale-105'
              ]"
              :style="{ backgroundColor: color }"
            />
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-4">
          <Button type="button" variant="ghost" @click="showCreateModal = false">
            Cancel
          </Button>
          <Button type="submit" :loading="creating">
            Create team
          </Button>
        </div>
      </form>
    </Modal>

    <!-- Edit team modal -->
    <Modal :open="showEditModal" @close="showEditModal = false" title="Edit team">
      <form @submit.prevent="handleEdit" class="space-y-4">
        <div v-if="editError" class="p-3 bg-red-500/10 border border-red-500/20 rounded-lg text-sm text-red-300">
          {{ editError }}
        </div>

        <div>
          <label class="block text-sm font-medium text-[var(--linear-text)] mb-1">
            Team name
          </label>
          <Input
            v-model="editTeamName"
            type="text"
            placeholder="Engineering"
            required
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-[var(--linear-text)] mb-1">
            Identifier
          </label>
          <div class="px-3 py-2 text-sm text-[var(--linear-muted)] bg-[var(--linear-surface)] border border-[var(--linear-border)] rounded-md">
            {{ editingTeam?.key }}
          </div>
          <p class="mt-1 text-xs text-[var(--linear-muted)]">
            Team identifier cannot be changed
          </p>
        </div>

        <div>
          <label class="block text-sm font-medium text-[var(--linear-text)] mb-2">
            Color
          </label>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="color in colors"
              :key="color"
              type="button"
              @click="editTeamColor = color"
              :class="[
                'w-8 h-8 rounded-lg border-2 transition-transform',
                editTeamColor === color ? 'border-white scale-110' : 'border-transparent hover:scale-105'
              ]"
              :style="{ backgroundColor: color }"
            />
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-4">
          <Button type="button" variant="ghost" @click="showEditModal = false">
            Cancel
          </Button>
          <Button type="submit" :loading="editSaving">
            Save changes
          </Button>
        </div>
      </form>
    </Modal>

    <!-- Members modal -->
    <Modal :open="showMembersModal" @close="showMembersModal = false" :title="`Members — ${membersTeam?.name || ''}`">
      <div class="space-y-4">
        <!-- Add member -->
        <div>
          <label class="block text-sm font-medium text-[var(--linear-text)] mb-2">Add member</label>
          <input
            v-model="memberSearch"
            type="text"
            placeholder="Search by name or email..."
            class="w-full text-sm px-3 py-2 mb-2 border border-[var(--linear-border)] rounded-md bg-[var(--linear-bg)] text-[var(--linear-text)] placeholder:text-[var(--linear-muted)] focus:outline-none focus:border-[var(--linear-accent)]"
          />
          <div class="max-h-[150px] overflow-auto space-y-0.5 border border-[var(--linear-border)] rounded-md p-1.5">
            <button
              v-for="user in nonMembers"
              :key="user.id"
              @click="addMember(user.id); memberSearch = ''"
              class="w-full flex items-center gap-2 px-2 py-1.5 rounded hover:bg-[var(--linear-surface)] transition-colors text-left"
            >
              <UserPlus class="h-3.5 w-3.5 text-[var(--linear-muted)] flex-shrink-0" />
              <span class="text-sm text-[var(--linear-text)] truncate">{{ user.name }}</span>
              <span class="text-xs text-[var(--linear-muted)] truncate">{{ user.email }}</span>
            </button>
            <div v-if="nonMembers.length === 0 && memberSearch" class="px-2 py-3 text-sm text-[var(--linear-muted)] text-center">
              No results for "{{ memberSearch }}"
            </div>
            <div v-else-if="nonMembers.length === 0" class="px-2 py-3 text-sm text-[var(--linear-muted)] text-center">
              All users are already members
            </div>
          </div>
        </div>

        <!-- Current members -->
        <div>
          <label class="block text-sm font-medium text-[var(--linear-text)] mb-2">
            Current members ({{ teamMembers.length }})
          </label>
          <div v-if="membersLoading" class="py-4 text-center">
            <div class="animate-spin rounded-full h-5 w-5 border-2 border-[var(--linear-accent)] border-t-transparent mx-auto"></div>
          </div>
          <div v-else-if="teamMembers.length === 0" class="text-sm text-[var(--linear-muted)] text-center py-4">
            No members yet
          </div>
          <div v-else class="space-y-1">
            <div
              v-for="membership in teamMembers"
              :key="membership.id"
              class="flex items-center justify-between px-3 py-2 rounded-md hover:bg-[var(--linear-surface)]"
            >
              <div class="flex items-center gap-2">
                <Avatar :name="membership.user?.name || ''" size="sm" />
                <div>
                  <span class="text-sm text-[var(--linear-text)]">{{ membership.user?.name }}</span>
                  <span v-if="membership.role === 'lead'" class="ml-1 text-xs text-[var(--linear-accent)]">Lead</span>
                </div>
              </div>
              <button
                @click="removeMember(membership.user?.id || membership.userId)"
                class="p-1 text-[var(--linear-muted)] hover:text-red-400 rounded transition-colors"
                title="Remove member"
              >
                <X class="h-3.5 w-3.5" />
              </button>
            </div>
          </div>
        </div>
      </div>

      <template #footer>
        <Button variant="ghost" @click="showMembersModal = false">
          Done
        </Button>
      </template>
    </Modal>

    <!-- Delete team confirm -->
    <Modal
      :open="showDeleteConfirm"
      @close="showDeleteConfirm = false"
      title="Delete team"
      description="This action cannot be undone."
      size="sm"
      :closable="!deleting"
    >
      <div class="space-y-3">
        <p class="text-sm text-[var(--linear-muted)]">
          Delete team
          <span class="font-medium text-[var(--linear-text)]">{{ deletingTeam?.name }}</span>
          ({{ deletingTeam?.key }})? All issues in this team will also be deleted.
        </p>
      </div>
      <template #footer>
        <Button variant="ghost" :disabled="deleting" @click="showDeleteConfirm = false">
          Cancel
        </Button>
        <Button variant="danger" :loading="deleting" @click="handleDelete">
          Delete team
        </Button>
      </template>
    </Modal>
  </div>
</template>
