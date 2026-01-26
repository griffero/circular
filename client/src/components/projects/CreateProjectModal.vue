<script setup lang="ts">
import { ref, watch } from 'vue'
import Modal from '@/components/ui/Modal.vue'
import Button from '@/components/ui/Button.vue'
import Input from '@/components/ui/Input.vue'
import { useAppStore } from '@/stores/app'
import api from '@/api/client'

const props = defineProps<{
  open: boolean
}>()

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'created', project: unknown): void
}>()

const appStore = useAppStore()

const name = ref('')
const description = ref('')
const color = ref('#6366f1')
const creating = ref(false)
const error = ref('')

const colors = [
  '#6366f1', '#8b5cf6', '#ec4899', '#ef4444', 
  '#f97316', '#eab308', '#22c55e', '#14b8a6', 
  '#06b6d4', '#3b82f6'
]

watch(() => props.open, (open) => {
  if (open) {
    name.value = ''
    description.value = ''
    color.value = '#6366f1'
    error.value = ''
  }
})

async function handleSubmit() {
  if (!name.value.trim()) return

  creating.value = true
  error.value = ''

  try {
    const response = await api.post('/projects', {
      project: {
        name: name.value.trim(),
        description: description.value || undefined,
        color: color.value,
      }
    })

    if (response.data) {
      await appStore.fetchProjects()
      emit('created', response.data)
      emit('close')
    }
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to create project'
  } finally {
    creating.value = false
  }
}
</script>

<template>
  <Modal :open="open" @close="emit('close')" size="md" title="Create project">
    <form @submit.prevent="handleSubmit" class="space-y-4">
      <div v-if="error" class="p-3 bg-red-900/20 border border-red-800 rounded-lg text-sm text-red-400">
        {{ error }}
      </div>

      <div>
        <label class="block text-xs font-medium text-gray-400 mb-1">Project name</label>
        <Input
          v-model="name"
          type="text"
          placeholder="e.g. Website Redesign"
          required
          autofocus
        />
      </div>

      <div>
        <label class="block text-xs font-medium text-gray-400 mb-1">Description</label>
        <textarea
          v-model="description"
          rows="3"
          placeholder="What is this project about?"
          class="w-full px-3 py-2 text-sm rounded-md border border-gray-700 bg-gray-800 text-gray-100 placeholder-gray-500 focus:ring-2 focus:ring-indigo-500 focus:border-transparent resize-none"
        />
      </div>

      <div>
        <label class="block text-xs font-medium text-gray-400 mb-2">Color</label>
        <div class="flex gap-2">
          <button
            v-for="c in colors"
            :key="c"
            type="button"
            @click="color = c"
            :class="[
              'w-6 h-6 rounded-full transition-transform',
              color === c ? 'ring-2 ring-white ring-offset-2 ring-offset-gray-900 scale-110' : 'hover:scale-110'
            ]"
            :style="{ backgroundColor: c }"
          />
        </div>
      </div>

      <div class="flex justify-end gap-3 pt-4 border-t border-gray-700">
        <Button type="button" variant="ghost" @click="emit('close')">
          Cancel
        </Button>
        <Button type="submit" :loading="creating" :disabled="!name.trim()">
          Create project
        </Button>
      </div>
    </form>
  </Modal>
</template>
