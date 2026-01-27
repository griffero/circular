<script setup lang="ts">
import { ref, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const isAdmin = computed(() => authStore.isAdmin)
const user = computed(() => authStore.user)

const appName = ref('Linear Clone')
const saving = ref(false)

async function handleSave() {
  if (!isAdmin.value) return
  
  saving.value = true
  try {
    // TODO: Implement settings update API
    await new Promise(resolve => setTimeout(resolve, 500))
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div class="p-8 max-w-2xl">
    <h1 class="text-xl font-semibold text-white mb-2">
      General
    </h1>
    <p class="text-[13px] text-gray-500 mb-8">
      Manage your workspace settings and preferences
    </p>

    <form @submit.prevent="handleSave" class="space-y-6">
      <!-- Application name -->
      <div>
        <label class="block text-[14px] text-white mb-2">
          Workspace name
        </label>
        <input
          v-model="appName"
          type="text"
          :disabled="!isAdmin"
          class="w-full bg-[#1a1a1a] border border-[#333] rounded px-3 py-2 text-[14px] text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
          placeholder="Linear Clone"
        />
        <p class="mt-1 text-[12px] text-gray-500">
          This is the display name of your workspace
        </p>
      </div>

      <!-- Role -->
      <div>
        <label class="block text-[14px] text-white mb-2">
          Your role
        </label>
        <p class="text-[14px] text-white capitalize">
          {{ user?.role || 'Member' }}
        </p>
        <p class="mt-1 text-[12px] text-gray-500">
          Your role determines what actions you can perform
        </p>
      </div>

      <!-- Save button -->
      <div class="pt-4">
        <button
          type="submit"
          :disabled="saving || !isAdmin"
          class="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed rounded text-[14px] text-white font-medium transition-colors"
        >
          {{ saving ? 'Saving...' : 'Save changes' }}
        </button>
      </div>
    </form>

    <!-- Danger zone -->
    <div class="mt-12 pt-6 border-t border-[#222]" v-if="authStore.isOwner">
      <h2 class="text-lg font-medium text-red-500 mb-4">
        Danger Zone
      </h2>
      <div class="p-4 bg-red-950/30 border border-red-900/50 rounded-lg">
        <h3 class="text-[14px] font-medium text-red-400 mb-1">
          Reset application
        </h3>
        <p class="text-[13px] text-red-400/80 mb-3">
          This will delete all data. This action cannot be undone.
        </p>
        <button
          type="button"
          class="px-3 py-1.5 bg-red-600 hover:bg-red-700 rounded text-[13px] text-white font-medium transition-colors"
        >
          Reset application
        </button>
      </div>
    </div>
  </div>
</template>
