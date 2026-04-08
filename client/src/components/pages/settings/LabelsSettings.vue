<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { api } from '@/api/client'
import Button from '@/components/ui/Button.vue'
import Input from '@/components/ui/Input.vue'
import Modal from '@/components/ui/Modal.vue'
import { Plus, Tags, Pencil, Trash2 } from 'lucide-vue-next'
import type { Label } from '@/types'

const authStore = useAuthStore()
const isAdmin = computed(() => authStore.isAdmin)

const labels = ref<Label[]>([])
const loading = ref(true)
const error = ref('')

const showCreateModal = ref(false)
const showEditModal = ref(false)
const editingLabelId = ref<string | null>(null)
const newLabelName = ref('')
const newLabelColor = ref('#6366f1')
const newLabelDescription = ref('')
const creating = ref(false)
const updating = ref(false)
const deletingLabelId = ref<string | null>(null)

const editLabelName = ref('')
const editLabelColor = ref('#6366f1')
const editLabelDescription = ref('')

const colors = [
  '#ef4444', '#f97316', '#f59e0b', '#eab308', '#84cc16',
  '#22c55e', '#10b981', '#14b8a6', '#06b6d4', '#0ea5e9',
  '#3b82f6', '#6366f1', '#8b5cf6', '#a855f7', '#d946ef',
  '#ec4899', '#f43f5e',
]

async function fetchLabels() {
  loading.value = true
  error.value = ''
  try {
    const data = await api.get<{ labels: Label[] }>('/api/v1/labels')
    labels.value = data.labels
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to fetch labels'
  } finally {
    loading.value = false
  }
}

async function handleCreate() {
  if (!newLabelName.value) return
  
  creating.value = true
  error.value = ''
  
  try {
    const data = await api.post<{ label: Label }>(
      '/api/v1/labels',
      {
        label: {
          name: newLabelName.value.trim(),
          color: newLabelColor.value,
          description: newLabelDescription.value.trim() || undefined,
        }
      }
    )
    labels.value = [data.label, ...labels.value]
    showCreateModal.value = false
    newLabelName.value = ''
    newLabelColor.value = '#6366f1'
    newLabelDescription.value = ''
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to create label'
  } finally {
    creating.value = false
  }
}

function openEditModal(label: Label) {
  editingLabelId.value = label.id
  editLabelName.value = label.name
  editLabelColor.value = label.color
  editLabelDescription.value = label.description || ''
  showEditModal.value = true
}

async function handleUpdate() {
  if (!editingLabelId.value || !editLabelName.value.trim()) return

  updating.value = true
  error.value = ''
  try {
    const data = await api.patch<{ label: Label }>(
      `/api/v1/labels/${editingLabelId.value}`,
      {
        label: {
          name: editLabelName.value.trim(),
          color: editLabelColor.value,
          description: editLabelDescription.value.trim() || undefined,
        }
      }
    )
    labels.value = labels.value.map(label => (
      label.id === editingLabelId.value ? data.label : label
    ))
    showEditModal.value = false
    editingLabelId.value = null
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to update label'
  } finally {
    updating.value = false
  }
}

async function handleDelete(label: Label) {
  if (!isAdmin.value) return
  const confirmed = window.confirm(`Delete label "${label.name}"? This action cannot be undone.`)
  if (!confirmed) return

  deletingLabelId.value = label.id
  error.value = ''
  try {
    await api.delete(`/api/v1/labels/${label.id}`)
    labels.value = labels.value.filter(existing => existing.id !== label.id)
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to delete label'
  } finally {
    deletingLabelId.value = null
  }
}

onMounted(() => {
  fetchLabels()
})
</script>

<template>
  <div class="p-6 max-w-4xl mx-auto bg-[var(--linear-bg)] min-h-full">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-xl font-semibold text-[var(--linear-text)] mb-1">
          Labels
        </h1>
        <p class="text-sm text-[var(--linear-muted)]">
          Manage labels used to categorize issues
        </p>
      </div>
      <Button v-if="isAdmin" @click="showCreateModal = true">
        <Plus class="h-4 w-4" />
        Create label
      </Button>
    </div>

    <div
      v-if="error"
      class="mb-4 px-3 py-2 text-sm rounded border border-red-500/40 bg-red-500/10 text-red-300"
    >
      {{ error }}
    </div>

    <div v-if="loading" class="py-12 flex justify-center">
      <div class="animate-spin rounded-full h-8 w-8 border-2 border-[var(--linear-accent)] border-t-transparent"></div>
    </div>

    <!-- Labels list -->
    <div v-else-if="labels.length === 0" class="text-center py-12">
      <Tags class="h-12 w-12 text-[var(--linear-muted)] mx-auto mb-4" />
      <h3 class="text-lg font-medium text-[var(--linear-text)] mb-2">No labels yet</h3>
      <p class="text-[var(--linear-muted)] mb-4">Create labels to categorize and organize your issues</p>
      <Button v-if="isAdmin" @click="showCreateModal = true">
        <Plus class="h-4 w-4" />
        Create label
      </Button>
    </div>

    <div v-else class="linear-panel divide-y divide-[var(--linear-border-subtle)]">
      <div
        v-for="label in labels"
        :key="label.id"
        class="flex items-center justify-between px-4 py-3 hover:bg-[var(--linear-surface)]"
      >
        <div class="flex items-center gap-3">
          <div 
            class="w-4 h-4 rounded-full"
            :style="{ backgroundColor: label.color }"
          />
          <div>
            <h3 class="font-medium text-[var(--linear-text)]">{{ label.name }}</h3>
            <p v-if="label.description" class="text-sm text-[var(--linear-muted)]">{{ label.description }}</p>
          </div>
        </div>
        <div v-if="isAdmin" class="flex items-center gap-2">
          <button
            class="p-2 text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-surface)] rounded-md"
            @click="openEditModal(label)"
          >
            <Pencil class="h-4 w-4" />
          </button>
          <button
            class="p-2 text-[var(--linear-muted)] hover:text-red-400 hover:bg-[var(--linear-surface)] rounded-md disabled:opacity-60"
            :disabled="deletingLabelId === label.id"
            @click="handleDelete(label)"
          >
            <Trash2 class="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>

    <!-- Create label modal -->
    <Modal :open="showCreateModal" @close="showCreateModal = false" title="Create label">
      <form @submit.prevent="handleCreate" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-[var(--linear-text)] mb-1">
            Label name
          </label>
          <Input
            v-model="newLabelName"
            type="text"
            placeholder="Bug, Feature, etc."
            required
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-[var(--linear-text)] mb-1">
            Description (optional)
          </label>
          <Input
            v-model="newLabelDescription"
            type="text"
            placeholder="Brief description of this label"
          />
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
              @click="newLabelColor = color"
              :class="[
                'w-8 h-8 rounded-full border-2 transition-transform',
                newLabelColor === color ? 'border-white scale-110' : 'border-transparent hover:scale-105'
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
            Create label
          </Button>
        </div>
      </form>
    </Modal>

    <Modal :open="showEditModal" @close="showEditModal = false" title="Edit label">
      <form @submit.prevent="handleUpdate" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-[var(--linear-text)] mb-1">
            Label name
          </label>
          <Input
            v-model="editLabelName"
            type="text"
            placeholder="Bug, Feature, etc."
            required
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-[var(--linear-text)] mb-1">
            Description (optional)
          </label>
          <Input
            v-model="editLabelDescription"
            type="text"
            placeholder="Brief description of this label"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-[var(--linear-text)] mb-2">
            Color
          </label>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="color in colors"
              :key="`edit-${color}`"
              type="button"
              @click="editLabelColor = color"
              :class="[
                'w-8 h-8 rounded-full border-2 transition-transform',
                editLabelColor === color ? 'border-white scale-110' : 'border-transparent hover:scale-105'
              ]"
              :style="{ backgroundColor: color }"
            />
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-4">
          <Button type="button" variant="ghost" @click="showEditModal = false">
            Cancel
          </Button>
          <Button type="submit" :loading="updating">
            Save changes
          </Button>
        </div>
      </form>
    </Modal>
  </div>
</template>
