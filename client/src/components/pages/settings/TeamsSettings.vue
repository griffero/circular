<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useAppStore } from '@/stores/app'
import Button from '@/components/ui/Button.vue'
import Input from '@/components/ui/Input.vue'
import Modal from '@/components/ui/Modal.vue'
import { Plus, Users, Pencil, Trash2 } from 'lucide-vue-next'

const authStore = useAuthStore()
const appStore = useAppStore()

const teams = computed(() => appStore.teams)
const isAdmin = computed(() => authStore.isAdmin)
const loading = computed(() => appStore.loading)

// Create team modal
const showCreateModal = ref(false)
const newTeamName = ref('')
const newTeamKey = ref('')
const newTeamColor = ref('#6366f1')
const creating = ref(false)
const createError = ref('')

// Auto-generate key from name
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

const colors = [
  '#ef4444', '#f97316', '#f59e0b', '#eab308', '#84cc16',
  '#22c55e', '#10b981', '#14b8a6', '#06b6d4', '#0ea5e9',
  '#3b82f6', '#6366f1', '#8b5cf6', '#a855f7', '#d946ef',
  '#ec4899', '#f43f5e',
]
</script>

<template>
  <div class="p-6 max-w-4xl bg-[var(--linear-bg)] min-h-full">
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
        class="flex items-center justify-between px-4 py-3 hover:bg-[var(--linear-surface)]"
      >
        <div class="flex items-center gap-3">
          <div 
            class="w-10 h-10 rounded-lg flex items-center justify-center text-white font-bold"
            :style="{ backgroundColor: team.color || '#6b7280' }"
          >
            {{ team.key.substring(0, 2) }}
          </div>
          <div>
            <h3 class="font-medium text-[var(--linear-text)]">{{ team.name }}</h3>
            <p class="text-sm text-[var(--linear-muted)]">{{ team.key }}</p>
          </div>
        </div>
        <div v-if="isAdmin" class="flex items-center gap-2">
          <button class="p-2 text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-surface)] rounded-md">
            <Pencil class="h-4 w-4" />
          </button>
          <button class="p-2 text-[var(--linear-muted)] hover:text-red-400 hover:bg-[var(--linear-surface)] rounded-md">
            <Trash2 class="h-4 w-4" />
          </button>
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
  </div>
</template>
