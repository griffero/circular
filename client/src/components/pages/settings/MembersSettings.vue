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
import { UserPlus, Mail, MoreHorizontal, Shield, User, Crown } from 'lucide-vue-next'
import type { User as UserType } from '@/types'

const authStore = useAuthStore()
const appStore = useAppStore()

const currentUser = computed(() => authStore.user)
const isAdmin = computed(() => authStore.isAdmin)
const isOwner = computed(() => authStore.isOwner)

const members = ref<UserType[]>([])
const loading = ref(true)
const showInviteModal = ref(false)
const inviteEmail = ref('')
const inviteRole = ref<'member' | 'admin'>('member')
const inviting = ref(false)
const inviteError = ref('')

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

onMounted(() => {
  fetchMembers()
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
        class="flex items-center justify-between px-4 py-3"
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
            </div>
            <p class="text-sm text-gray-500">{{ member.email }}</p>
          </div>
        </div>
        <div class="flex items-center gap-3">
          <Badge :variant="getRoleBadge(member.role).variant">
            <component :is="getRoleBadge(member.role).icon" class="h-3 w-3 mr-1" />
            {{ getRoleBadge(member.role).label }}
          </Badge>
          <button 
            v-if="isOwner && member.id !== currentUser?.id"
            class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-md"
          >
            <MoreHorizontal class="h-4 w-4" />
          </button>
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
  </div>
</template>
