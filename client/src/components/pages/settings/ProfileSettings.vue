<script setup lang="ts">
import { ref, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const user = computed(() => authStore.user)

const fullName = ref(user.value?.name || '')
const displayName = ref(user.value?.name || '')
const username = ref(user.value?.email?.split('@')[0] || '')
const saving = ref(false)

async function handleSave() {
  saving.value = true
  try {
    // TODO: Implement profile update API
    await new Promise(resolve => setTimeout(resolve, 500))
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div class="p-8 max-w-2xl">
    <h1 class="text-xl font-semibold text-white mb-8">
      Profile
    </h1>

    <form @submit.prevent="handleSave" class="space-y-6">
      <!-- Avatar -->
      <div class="flex items-center gap-4 pb-6 border-b border-[#222]">
        <div class="w-16 h-16 rounded-full bg-indigo-600 flex items-center justify-center">
          <span class="text-2xl font-medium text-white">
            {{ user?.name?.charAt(0)?.toUpperCase() || '?' }}
          </span>
        </div>
        <div>
          <button 
            type="button"
            class="px-3 py-1.5 bg-[#1a1a1a] border border-[#333] rounded text-[13px] text-white hover:bg-[#222] transition-colors"
          >
            Upload photo
          </button>
          <p class="mt-1 text-[12px] text-gray-500">
            Recommended size: 256x256px
          </p>
        </div>
      </div>

      <!-- Full name -->
      <div>
        <label class="block text-[14px] text-white mb-2">
          Full name
        </label>
        <input
          v-model="fullName"
          type="text"
          class="w-full bg-[#1a1a1a] border border-[#333] rounded px-3 py-2 text-[14px] text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
          placeholder="Your full name"
        />
      </div>

      <!-- Display name -->
      <div>
        <label class="block text-[14px] text-white mb-2">
          Display name
        </label>
        <input
          v-model="displayName"
          type="text"
          class="w-full bg-[#1a1a1a] border border-[#333] rounded px-3 py-2 text-[14px] text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
          placeholder="Display name"
        />
        <p class="mt-1 text-[12px] text-gray-500">
          This could be your first name, or a nickname
        </p>
      </div>

      <!-- Username -->
      <div>
        <label class="block text-[14px] text-white mb-2">
          Username
        </label>
        <input
          v-model="username"
          type="text"
          class="w-full bg-[#1a1a1a] border border-[#333] rounded px-3 py-2 text-[14px] text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500"
          placeholder="username"
        />
      </div>

      <!-- Email (read-only) -->
      <div>
        <label class="block text-[14px] text-white mb-2">
          Email
        </label>
        <input
          :value="user?.email"
          type="email"
          disabled
          class="w-full bg-[#111] border border-[#222] rounded px-3 py-2 text-[14px] text-gray-500 cursor-not-allowed"
        />
      </div>

      <!-- Save button -->
      <div class="pt-4">
        <button
          type="submit"
          :disabled="saving"
          class="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 rounded text-[14px] text-white font-medium transition-colors"
        >
          {{ saving ? 'Saving...' : 'Save changes' }}
        </button>
      </div>
    </form>
  </div>
</template>
