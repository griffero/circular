<script setup lang="ts">
import { ref, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import Button from '@/components/ui/Button.vue'
import Input from '@/components/ui/Input.vue'
import Modal from '@/components/ui/Modal.vue'
import { Plus, Tags, Pencil, Trash2 } from 'lucide-vue-next'

const authStore = useAuthStore()
const isAdmin = computed(() => authStore.isAdmin)

// Placeholder labels (will be fetched from API later)
const labels = ref<{ id: string; name: string; color: string; description?: string }[]>([
  { id: '1', name: 'Bug', color: '#ef4444', description: 'Something isn\'t working' },
  { id: '2', name: 'Feature', color: '#22c55e', description: 'New feature request' },
  { id: '3', name: 'Improvement', color: '#3b82f6', description: 'Enhancement to existing feature' },
  { id: '4', name: 'Documentation', color: '#8b5cf6', description: 'Documentation updates' },
])

const showCreateModal = ref(false)
const newLabelName = ref('')
const newLabelColor = ref('#6366f1')
const newLabelDescription = ref('')
const creating = ref(false)

const colors = [
  '#ef4444', '#f97316', '#f59e0b', '#eab308', '#84cc16',
  '#22c55e', '#10b981', '#14b8a6', '#06b6d4', '#0ea5e9',
  '#3b82f6', '#6366f1', '#8b5cf6', '#a855f7', '#d946ef',
  '#ec4899', '#f43f5e',
]

async function handleCreate() {
  if (!newLabelName.value) return
  
  creating.value = true
  
  try {
    // TODO: Implement label creation API
    labels.value.push({
      id: String(Date.now()),
      name: newLabelName.value,
      color: newLabelColor.value,
      description: newLabelDescription.value || undefined,
    })
    showCreateModal.value = false
    newLabelName.value = ''
    newLabelColor.value = '#6366f1'
    newLabelDescription.value = ''
  } finally {
    creating.value = false
  }
}
</script>

<template>
  <div class="p-6 max-w-4xl bg-[var(--linear-bg)] min-h-full">
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

    <!-- Labels list -->
    <div v-if="labels.length === 0" class="text-center py-12">
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
          <button class="p-2 text-[var(--linear-muted)] hover:text-[var(--linear-text)] hover:bg-[var(--linear-surface)] rounded-md">
            <Pencil class="h-4 w-4" />
          </button>
          <button class="p-2 text-[var(--linear-muted)] hover:text-red-400 hover:bg-[var(--linear-surface)] rounded-md">
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
  </div>
</template>
