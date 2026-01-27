<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useAppStore } from '@/stores/app'
import { api } from '@/api/client'
import Button from '@/components/ui/Button.vue'
import Input from '@/components/ui/Input.vue'
import Modal from '@/components/ui/Modal.vue'
import Badge from '@/components/ui/Badge.vue'
import Avatar from '@/components/ui/Avatar.vue'
import UserLink from '@/components/ui/UserLink.vue'
import Dropdown from '@/components/ui/Dropdown.vue'
import DropdownItem from '@/components/ui/DropdownItem.vue'
import { 
  UserPlus, 
  Mail, 
  MoreHorizontal, 
  Shield, 
  User, 
  Crown,
  UserCog,
  Pencil,
  AtSign,
  UserX,
  Users,
  Check
} from 'lucide-vue-next'
import type { User as UserType, Team } from '@/types'

const authStore = useAuthStore()
const appStore = useAppStore()

const currentUser = computed(() => authStore.user)
const isAdmin = computed(() => authStore.isAdmin)
const isOwner = computed(() => authStore.isOwner)

const members = ref<UserType[]>([])
const teams = ref<Team[]>([])
const loading = ref(true)
const showInviteModal = ref(false)
const inviteEmail = ref('')
const inviteRole = ref<'member' | 'admin'>('member')
const inviting = ref(false)
const inviteError = ref('')

// Selected member for actions
const selectedMember = ref<UserType | null>(null)

// Modal states
const showChangeRoleModal = ref(false)
const showUpdateNameModal = ref(false)
const showUpdateEmailModal = ref(false)
const showSuspendModal = ref(false)
const showManageTeamsModal = ref(false)

// Form states
const newRole = ref<'member' | 'admin' | 'owner'>('member')
const newName = ref('')
const newEmail = ref('')
const memberTeamIds = ref<string[]>([])
const saving = ref(false)
const saveError = ref('')

async function fetchMembers() {
  loading.value = true
  try {
    const data = await api.get<{ users: UserType[] }>('/api/v1/users')
    members.value = data.users
  } catch (err) {
    console.error('Failed to fetch members:', err)
  } finally {
    loading.value = false
  }
}

async function fetchTeams() {
  try {
    const data = await api.get<{ teams: Team[] }>('/api/v1/teams')
    teams.value = data.teams
  } catch (err) {
    console.error('Failed to fetch teams:', err)
  }
}

onMounted(() => {
  fetchMembers()
  fetchTeams()
})

async function handleInvite() {
  if (!inviteEmail.value) return
  
  inviting.value = true
  inviteError.value = ''

  try {
    // In single-tenant mode, we would create a new user or send an invite
    // For now, just close the modal
    showInviteModal.value = false
    inviteEmail.value = ''
    inviteRole.value = 'member'
    fetchMembers()
  } catch (err) {
    inviteError.value = err instanceof Error ? err.message : 'Failed to invite member'
  } finally {
    inviting.value = false
  }
}

function getRoleBadge(role: string) {
  switch (role) {
    case 'owner':
      return { variant: 'warning' as const, icon: Crown, label: 'Owner' }
    case 'admin':
      return { variant: 'primary' as const, icon: Shield, label: 'Admin' }
    default:
      return { variant: 'secondary' as const, icon: User, label: 'Member' }
  }
}

// Open modals with selected member
function openChangeRole(member: UserType) {
  selectedMember.value = member
  newRole.value = member.role as 'member' | 'admin' | 'owner'
  saveError.value = ''
  showChangeRoleModal.value = true
}

function openUpdateName(member: UserType) {
  selectedMember.value = member
  newName.value = member.name || ''
  saveError.value = ''
  showUpdateNameModal.value = true
}

function openUpdateEmail(member: UserType) {
  selectedMember.value = member
  newEmail.value = member.email || ''
  saveError.value = ''
  showUpdateEmailModal.value = true
}

function openSuspend(member: UserType) {
  selectedMember.value = member
  saveError.value = ''
  showSuspendModal.value = true
}

function openManageTeams(member: UserType) {
  selectedMember.value = member
  // Get current team memberships
  memberTeamIds.value = member.teamMemberships?.map(tm => tm.teamId) || []
  saveError.value = ''
  showManageTeamsModal.value = true
}

// API actions
async function saveRole() {
  if (!selectedMember.value) return
  
  saving.value = true
  saveError.value = ''
  
  try {
    await api.patch(`/api/v1/users/${selectedMember.value.id}`, {
      role: newRole.value
    })
    await fetchMembers()
    showChangeRoleModal.value = false
  } catch (err) {
    saveError.value = err instanceof Error ? err.message : 'Failed to update role'
  } finally {
    saving.value = false
  }
}

async function saveName() {
  if (!selectedMember.value || !newName.value.trim()) return
  
  saving.value = true
  saveError.value = ''
  
  try {
    await api.patch(`/api/v1/users/${selectedMember.value.id}`, {
      name: newName.value.trim()
    })
    await fetchMembers()
    showUpdateNameModal.value = false
  } catch (err) {
    saveError.value = err instanceof Error ? err.message : 'Failed to update name'
  } finally {
    saving.value = false
  }
}

async function saveEmail() {
  if (!selectedMember.value || !newEmail.value.trim()) return
  
  saving.value = true
  saveError.value = ''
  
  try {
    await api.patch(`/api/v1/users/${selectedMember.value.id}`, {
      email: newEmail.value.trim()
    })
    await fetchMembers()
    showUpdateEmailModal.value = false
  } catch (err) {
    saveError.value = err instanceof Error ? err.message : 'Failed to update email'
  } finally {
    saving.value = false
  }
}

async function suspendUser() {
  if (!selectedMember.value) return
  
  saving.value = true
  saveError.value = ''
  
  try {
    await api.patch(`/api/v1/users/${selectedMember.value.id}`, {
      active: !selectedMember.value.active
    })
    await fetchMembers()
    showSuspendModal.value = false
  } catch (err) {
    saveError.value = err instanceof Error ? err.message : 'Failed to update user status'
  } finally {
    saving.value = false
  }
}

async function saveTeamMemberships() {
  if (!selectedMember.value) return
  
  saving.value = true
  saveError.value = ''
  
  try {
    // Get current team memberships
    const currentTeamIds = selectedMember.value.teamMemberships?.map(tm => tm.teamId) || []
    
    // Teams to add
    const teamsToAdd = memberTeamIds.value.filter(id => !currentTeamIds.includes(id))
    // Teams to remove
    const teamsToRemove = currentTeamIds.filter(id => !memberTeamIds.value.includes(id))
    
    // Add to new teams
    for (const teamId of teamsToAdd) {
      const team = teams.value.find(t => t.id === teamId)
      if (team) {
        await api.post(`/api/v1/teams/${team.key}/members`, {
          user_id: selectedMember.value.id
        })
      }
    }
    
    // Remove from teams
    for (const teamId of teamsToRemove) {
      const team = teams.value.find(t => t.id === teamId)
      if (team) {
        await api.delete(`/api/v1/teams/${team.key}/members/${selectedMember.value.id}`)
      }
    }
    
    await fetchMembers()
    showManageTeamsModal.value = false
  } catch (err) {
    saveError.value = err instanceof Error ? err.message : 'Failed to update team memberships'
  } finally {
    saving.value = false
  }
}

function toggleTeam(teamId: string) {
  const index = memberTeamIds.value.indexOf(teamId)
  if (index === -1) {
    memberTeamIds.value.push(teamId)
  } else {
    memberTeamIds.value.splice(index, 1)
  }
}

function isUserSuspended(member: UserType): boolean {
  return member.active === false
}
</script>

<template>
  <div class="p-6 max-w-4xl">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-xl font-semibold text-gray-900 dark:text-gray-100 mb-1">
          Members
        </h1>
        <p class="text-sm text-gray-500">
          Manage team members and their roles
        </p>
      </div>
      <Button v-if="isAdmin" @click="showInviteModal = true">
        <UserPlus class="h-4 w-4" />
        Invite member
      </Button>
    </div>

    <!-- Members list -->
    <div v-if="loading" class="text-center py-12">
      <div class="animate-spin rounded-full h-8 w-8 border-2 border-primary-600 border-t-transparent mx-auto"></div>
    </div>

    <div v-else class="bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-800 divide-y divide-gray-200 dark:divide-gray-800">
      <div
        v-for="member in members"
        :key="member.id"
        :class="[
          'flex items-center justify-between px-4 py-3',
          isUserSuspended(member) && 'opacity-50'
        ]"
      >
        <div class="flex items-center gap-3">
          <UserLink
            :userId="member.id"
            :name="member.name || 'U'"
            :avatarUrl="member.avatarUrl"
            :showName="false"
            avatarSize="md"
          />
          <div>
            <div class="flex items-center gap-2">
              <UserLink
                :userId="member.id"
                :name="member.name || 'Unknown'"
                :showAvatar="false"
                class="font-medium text-gray-900 dark:text-gray-100 hover:text-indigo-400"
              />
              <span
                v-if="member.id === currentUser?.id"
                class="text-xs text-gray-500 px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded"
              >
                You
              </span>
              <span
                v-if="isUserSuspended(member)"
                class="text-xs text-red-400 px-1.5 py-0.5 bg-red-500/10 rounded"
              >
                Suspended
              </span>
            </div>
            <p class="text-sm text-gray-500">{{ member.email }}</p>
          </div>
        </div>
        <div class="flex items-center gap-3">
          <Badge :variant="getRoleBadge(member.role).variant">
            <component :is="getRoleBadge(member.role).icon" class="h-3 w-3 mr-1" />
            {{ getRoleBadge(member.role).label }}
          </Badge>
          
          <!-- Dropdown menu -->
          <Dropdown v-if="isOwner && member.id !== currentUser?.id" align="right" width="w-52">
            <template #trigger>
              <button class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-md">
                <MoreHorizontal class="h-4 w-4" />
              </button>
            </template>
            <template #default="{ close }">
              <DropdownItem @click="() => { openChangeRole(member); close() }">
                <UserCog class="h-4 w-4" />
                Change role...
              </DropdownItem>
              <DropdownItem @click="() => { openUpdateName(member); close() }">
                <Pencil class="h-4 w-4" />
                Update name...
              </DropdownItem>
              <DropdownItem @click="() => { openUpdateEmail(member); close() }">
                <AtSign class="h-4 w-4" />
                Update email...
              </DropdownItem>
              <div class="border-t border-[#2a2a2a] my-1" />
              <DropdownItem @click="() => { openSuspend(member); close() }" :danger="!isUserSuspended(member)">
                <UserX class="h-4 w-4" />
                {{ isUserSuspended(member) ? 'Reactivate user...' : 'Suspend user...' }}
              </DropdownItem>
              <div class="border-t border-[#2a2a2a] my-1" />
              <DropdownItem @click="() => { openManageTeams(member); close() }">
                <Users class="h-4 w-4" />
                Manage teams...
              </DropdownItem>
            </template>
          </Dropdown>
        </div>
      </div>
    </div>

    <!-- Invite modal -->
    <Modal :open="showInviteModal" @close="showInviteModal = false" title="Invite member">
      <form @submit.prevent="handleInvite" class="space-y-4">
        <div v-if="inviteError" class="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-sm text-red-600 dark:text-red-400">
          {{ inviteError }}
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            Email address
          </label>
          <Input
            v-model="inviteEmail"
            type="email"
            placeholder="colleague@example.com"
            required
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Role
          </label>
          <div class="space-y-2">
            <label class="flex items-start gap-3 p-3 border border-gray-200 dark:border-gray-700 rounded-lg cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800/50">
              <input
                v-model="inviteRole"
                type="radio"
                value="member"
                class="mt-1"
              />
              <div>
                <p class="font-medium text-gray-900 dark:text-gray-100">Member</p>
                <p class="text-sm text-gray-500">Can view and create issues within teams they belong to</p>
              </div>
            </label>
            <label class="flex items-start gap-3 p-3 border border-gray-200 dark:border-gray-700 rounded-lg cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800/50">
              <input
                v-model="inviteRole"
                type="radio"
                value="admin"
                class="mt-1"
              />
              <div>
                <p class="font-medium text-gray-900 dark:text-gray-100">Admin</p>
                <p class="text-sm text-gray-500">Can manage settings, teams, and members</p>
              </div>
            </label>
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-4">
          <Button type="button" variant="ghost" @click="showInviteModal = false">
            Cancel
          </Button>
          <Button type="submit" :loading="inviting">
            <Mail class="h-4 w-4" />
            Send invite
          </Button>
        </div>
      </form>
    </Modal>

    <!-- Change Role Modal -->
    <Modal :open="showChangeRoleModal" @close="showChangeRoleModal = false" title="Change role">
      <form @submit.prevent="saveRole" class="space-y-4">
        <div v-if="saveError" class="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-sm text-red-600 dark:text-red-400">
          {{ saveError }}
        </div>

        <p class="text-sm text-gray-500">
          Change the role for <span class="text-white font-medium">{{ selectedMember?.name }}</span>
        </p>

        <div class="space-y-2">
          <label class="flex items-start gap-3 p-3 border border-gray-700 rounded-lg cursor-pointer hover:bg-gray-800/50" :class="newRole === 'member' && 'border-indigo-500 bg-indigo-500/10'">
            <input v-model="newRole" type="radio" value="member" class="mt-1" />
            <div>
              <p class="font-medium text-gray-100">Member</p>
              <p class="text-sm text-gray-500">Can view and create issues within teams they belong to</p>
            </div>
          </label>
          <label class="flex items-start gap-3 p-3 border border-gray-700 rounded-lg cursor-pointer hover:bg-gray-800/50" :class="newRole === 'admin' && 'border-indigo-500 bg-indigo-500/10'">
            <input v-model="newRole" type="radio" value="admin" class="mt-1" />
            <div>
              <p class="font-medium text-gray-100">Admin</p>
              <p class="text-sm text-gray-500">Can manage settings, teams, and members</p>
            </div>
          </label>
          <label class="flex items-start gap-3 p-3 border border-gray-700 rounded-lg cursor-pointer hover:bg-gray-800/50" :class="newRole === 'owner' && 'border-indigo-500 bg-indigo-500/10'">
            <input v-model="newRole" type="radio" value="owner" class="mt-1" />
            <div>
              <p class="font-medium text-gray-100">Owner</p>
              <p class="text-sm text-gray-500">Full access to all settings and billing</p>
            </div>
          </label>
        </div>

        <div class="flex justify-end gap-3 pt-4">
          <Button type="button" variant="ghost" @click="showChangeRoleModal = false">
            Cancel
          </Button>
          <Button type="submit" :loading="saving">
            Save changes
          </Button>
        </div>
      </form>
    </Modal>

    <!-- Update Name Modal -->
    <Modal :open="showUpdateNameModal" @close="showUpdateNameModal = false" title="Update name">
      <form @submit.prevent="saveName" class="space-y-4">
        <div v-if="saveError" class="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-sm text-red-600 dark:text-red-400">
          {{ saveError }}
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-300 mb-1">
            Name
          </label>
          <Input
            v-model="newName"
            type="text"
            placeholder="Full name"
            required
          />
        </div>

        <div class="flex justify-end gap-3 pt-4">
          <Button type="button" variant="ghost" @click="showUpdateNameModal = false">
            Cancel
          </Button>
          <Button type="submit" :loading="saving">
            Save changes
          </Button>
        </div>
      </form>
    </Modal>

    <!-- Update Email Modal -->
    <Modal :open="showUpdateEmailModal" @close="showUpdateEmailModal = false" title="Update email">
      <form @submit.prevent="saveEmail" class="space-y-4">
        <div v-if="saveError" class="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-sm text-red-600 dark:text-red-400">
          {{ saveError }}
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-300 mb-1">
            Email address
          </label>
          <Input
            v-model="newEmail"
            type="email"
            placeholder="email@example.com"
            required
          />
        </div>

        <div class="flex justify-end gap-3 pt-4">
          <Button type="button" variant="ghost" @click="showUpdateEmailModal = false">
            Cancel
          </Button>
          <Button type="submit" :loading="saving">
            Save changes
          </Button>
        </div>
      </form>
    </Modal>

    <!-- Suspend User Modal -->
    <Modal :open="showSuspendModal" @close="showSuspendModal = false" :title="isUserSuspended(selectedMember!) ? 'Reactivate user' : 'Suspend user'">
      <div class="space-y-4">
        <div v-if="saveError" class="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-sm text-red-600 dark:text-red-400">
          {{ saveError }}
        </div>

        <p v-if="selectedMember && !isUserSuspended(selectedMember)" class="text-sm text-gray-400">
          Are you sure you want to suspend <span class="text-white font-medium">{{ selectedMember?.name }}</span>?
          They will no longer be able to access the workspace.
        </p>
        <p v-else class="text-sm text-gray-400">
          Are you sure you want to reactivate <span class="text-white font-medium">{{ selectedMember?.name }}</span>?
          They will regain access to the workspace.
        </p>

        <div class="flex justify-end gap-3 pt-4">
          <Button type="button" variant="ghost" @click="showSuspendModal = false">
            Cancel
          </Button>
          <Button 
            @click="suspendUser" 
            :loading="saving"
            :variant="selectedMember && !isUserSuspended(selectedMember) ? 'danger' : 'primary'"
          >
            {{ selectedMember && isUserSuspended(selectedMember) ? 'Reactivate' : 'Suspend' }}
          </Button>
        </div>
      </div>
    </Modal>

    <!-- Manage Teams Modal -->
    <Modal :open="showManageTeamsModal" @close="showManageTeamsModal = false" title="Manage teams">
      <div class="space-y-4">
        <div v-if="saveError" class="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-sm text-red-600 dark:text-red-400">
          {{ saveError }}
        </div>

        <p class="text-sm text-gray-400">
          Select the teams <span class="text-white font-medium">{{ selectedMember?.name }}</span> should be a member of.
        </p>

        <div class="max-h-64 overflow-y-auto space-y-1">
          <button
            v-for="team in teams"
            :key="team.id"
            @click="toggleTeam(team.id)"
            class="w-full flex items-center justify-between px-3 py-2.5 rounded-lg hover:bg-gray-800/50 transition-colors text-left"
            :class="memberTeamIds.includes(team.id) && 'bg-indigo-500/10'"
          >
            <div class="flex items-center gap-3">
              <div 
                class="w-7 h-7 rounded flex items-center justify-center text-xs font-medium"
                :style="{ backgroundColor: team.color || '#5e6ad2' }"
              >
                {{ team.icon || team.name?.charAt(0).toUpperCase() }}
              </div>
              <span class="text-sm text-gray-200">{{ team.name }}</span>
            </div>
            <Check 
              v-if="memberTeamIds.includes(team.id)" 
              class="h-4 w-4 text-indigo-400" 
            />
          </button>
        </div>

        <div class="flex justify-end gap-3 pt-4">
          <Button type="button" variant="ghost" @click="showManageTeamsModal = false">
            Cancel
          </Button>
          <Button @click="saveTeamMemberships" :loading="saving">
            Save changes
          </Button>
        </div>
      </div>
    </Modal>
  </div>
</template>
