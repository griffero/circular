<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useAppStore } from '@/stores/app'
import { api } from '@/api/client'
import Button from '@/components/ui/Button.vue'
import Input from '@/components/ui/Input.vue'
import Modal from '@/components/ui/Modal.vue'
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

function getRoleLabel(member: UserType): string {
  if (member.guest) return 'Guest'
  switch (member.role) {
    case 'owner': return 'Owner'
    case 'admin': return 'Admin'
    default: return 'Member'
  }
}

function getTeamsCount(member: UserType): string {
  const count = member.teamMemberships?.length || member.teams?.length || 0
  if (count === 0) return ''
  return count === 1 ? '1 team' : `${count} teams`
}

function formatDate(dateStr?: string): string {
  if (!dateStr) return ''
  const date = new Date(dateStr)
  const now = new Date()
  const diffDays = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24))
  
  if (diffDays < 1) return 'Today'
  if (diffDays < 7) return `${diffDays}d ago`
  
  const month = date.toLocaleDateString('en-US', { month: 'short' })
  const year = date.getFullYear()
  const currentYear = now.getFullYear()
  
  if (year === currentYear) {
    return month
  }
  return `${month} ${year}`
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
    const currentTeamIds = selectedMember.value.teamMemberships?.map(tm => tm.teamId) || []
    const teamsToAdd = memberTeamIds.value.filter(id => !currentTeamIds.includes(id))
    const teamsToRemove = currentTeamIds.filter(id => !memberTeamIds.value.includes(id))
    
    for (const teamId of teamsToAdd) {
      const team = teams.value.find(t => t.id === teamId)
      if (team) {
        await api.post(`/api/v1/teams/${team.key}/members`, {
          user_id: selectedMember.value.id
        })
      }
    }
    
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
  <div class="h-full bg-[#0d0d0d]">
    <!-- Header -->
    <div class="flex items-center justify-between px-6 py-4 border-b border-[#1f1f1f]">
      <h1 class="text-[15px] font-medium text-white">Members</h1>
      <Button v-if="isAdmin" @click="showInviteModal = true" size="sm">
        <UserPlus class="h-4 w-4" />
        Invite member
      </Button>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="animate-spin rounded-full h-8 w-8 border-2 border-indigo-600 border-t-transparent"></div>
    </div>

    <!-- Table -->
    <div v-else class="overflow-x-auto">
      <!-- Table header -->
      <div class="grid grid-cols-[1fr_100px_100px_100px_100px_48px] gap-4 px-6 py-2 border-b border-[#1f1f1f] text-[11px] text-gray-500 uppercase tracking-wider">
        <div></div>
        <div>Status</div>
        <div>Teams</div>
        <div>Joined</div>
        <div>Last seen</div>
        <div></div>
      </div>

      <!-- Table body -->
      <div class="divide-y divide-[#1a1a1a]">
        <div
          v-for="member in members"
          :key="member.id"
          :class="[
            'grid grid-cols-[1fr_100px_100px_100px_100px_48px] gap-4 px-6 py-3 items-center hover:bg-[#151515] transition-colors',
            isUserSuspended(member) && 'opacity-50'
          ]"
        >
          <!-- User info -->
          <div class="flex items-center gap-3 min-w-0">
            <Avatar
              :name="member.name || 'U'"
              :src="member.avatarUrl"
              size="md"
            />
            <div class="min-w-0">
              <div class="flex items-center gap-2">
                <UserLink
                  :userId="member.id"
                  :name="member.name || 'Unknown'"
                  :showAvatar="false"
                  class="text-[14px] font-medium text-white truncate hover:text-indigo-400"
                />
                <span
                  v-if="member.id === currentUser?.id"
                  class="text-[11px] text-gray-500 px-1.5 py-0.5 bg-[#252525] rounded flex-shrink-0"
                >
                  You
                </span>
              </div>
              <p class="text-[13px] text-gray-500 truncate">{{ member.email }}</p>
            </div>
          </div>

          <!-- Status/Role badge -->
          <div>
            <span 
              :class="[
                'inline-flex items-center gap-1.5 px-2 py-1 text-[12px] rounded',
                member.guest 
                  ? 'bg-[#252525] text-gray-400' 
                  : 'bg-[#252525] text-gray-300'
              ]"
            >
              <User class="w-3 h-3" />
              {{ getRoleLabel(member) }}
            </span>
          </div>

          <!-- Teams -->
          <div class="text-[13px] text-gray-400">
            {{ getTeamsCount(member) }}
          </div>

          <!-- Joined -->
          <div class="text-[13px] text-gray-500">
            {{ formatDate(member.createdAt) }}
          </div>

          <!-- Last seen -->
          <div class="text-[13px] text-gray-500">
            {{ formatDate(member.updatedAt) }}
          </div>

          <!-- Actions -->
          <div class="flex justify-end">
            <Dropdown v-if="isOwner && member.id !== currentUser?.id" align="right" width="w-52">
              <template #trigger>
                <button class="p-1.5 text-gray-500 hover:text-white hover:bg-[#252525] rounded transition-colors">
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
            <!-- Placeholder for alignment when no dropdown -->
            <div v-else class="w-7 h-7"></div>
          </div>
        </div>
      </div>
    </div>

    <!-- Invite modal -->
    <Modal :open="showInviteModal" @close="showInviteModal = false" title="Invite member">
      <form @submit.prevent="handleInvite" class="space-y-4">
        <div v-if="inviteError" class="p-3 bg-red-900/20 border border-red-800 rounded-lg text-sm text-red-400">
          {{ inviteError }}
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-300 mb-1">
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
          <label class="block text-sm font-medium text-gray-300 mb-2">
            Role
          </label>
          <div class="space-y-2">
            <label class="flex items-start gap-3 p-3 border border-[#2a2a2a] rounded-lg cursor-pointer hover:bg-[#1a1a1a]" :class="inviteRole === 'member' && 'border-indigo-500 bg-indigo-500/10'">
              <input v-model="inviteRole" type="radio" value="member" class="mt-1" />
              <div>
                <p class="font-medium text-gray-100">Member</p>
                <p class="text-sm text-gray-500">Can view and create issues within teams they belong to</p>
              </div>
            </label>
            <label class="flex items-start gap-3 p-3 border border-[#2a2a2a] rounded-lg cursor-pointer hover:bg-[#1a1a1a]" :class="inviteRole === 'admin' && 'border-indigo-500 bg-indigo-500/10'">
              <input v-model="inviteRole" type="radio" value="admin" class="mt-1" />
              <div>
                <p class="font-medium text-gray-100">Admin</p>
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
        <div v-if="saveError" class="p-3 bg-red-900/20 border border-red-800 rounded-lg text-sm text-red-400">
          {{ saveError }}
        </div>

        <p class="text-sm text-gray-400">
          Change the role for <span class="text-white font-medium">{{ selectedMember?.name }}</span>
        </p>

        <div class="space-y-2">
          <label class="flex items-start gap-3 p-3 border border-[#2a2a2a] rounded-lg cursor-pointer hover:bg-[#1a1a1a]" :class="newRole === 'member' && 'border-indigo-500 bg-indigo-500/10'">
            <input v-model="newRole" type="radio" value="member" class="mt-1" />
            <div>
              <p class="font-medium text-gray-100">Member</p>
              <p class="text-sm text-gray-500">Can view and create issues within teams they belong to</p>
            </div>
          </label>
          <label class="flex items-start gap-3 p-3 border border-[#2a2a2a] rounded-lg cursor-pointer hover:bg-[#1a1a1a]" :class="newRole === 'admin' && 'border-indigo-500 bg-indigo-500/10'">
            <input v-model="newRole" type="radio" value="admin" class="mt-1" />
            <div>
              <p class="font-medium text-gray-100">Admin</p>
              <p class="text-sm text-gray-500">Can manage settings, teams, and members</p>
            </div>
          </label>
          <label class="flex items-start gap-3 p-3 border border-[#2a2a2a] rounded-lg cursor-pointer hover:bg-[#1a1a1a]" :class="newRole === 'owner' && 'border-indigo-500 bg-indigo-500/10'">
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
        <div v-if="saveError" class="p-3 bg-red-900/20 border border-red-800 rounded-lg text-sm text-red-400">
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
        <div v-if="saveError" class="p-3 bg-red-900/20 border border-red-800 rounded-lg text-sm text-red-400">
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
    <Modal :open="showSuspendModal" @close="showSuspendModal = false" :title="selectedMember && isUserSuspended(selectedMember) ? 'Reactivate user' : 'Suspend user'">
      <div class="space-y-4">
        <div v-if="saveError" class="p-3 bg-red-900/20 border border-red-800 rounded-lg text-sm text-red-400">
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
        <div v-if="saveError" class="p-3 bg-red-900/20 border border-red-800 rounded-lg text-sm text-red-400">
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
            class="w-full flex items-center justify-between px-3 py-2.5 rounded-lg hover:bg-[#1a1a1a] transition-colors text-left"
            :class="memberTeamIds.includes(team.id) && 'bg-indigo-500/10'"
          >
            <div class="flex items-center gap-3">
              <div 
                class="w-7 h-7 rounded flex items-center justify-center text-xs font-medium text-white"
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
