<script setup lang="ts">
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

// With magic link, signup and login are the same flow
onMounted(() => {
  router.replace('/login')
})
</script>

<template>
  <div class="min-h-screen bg-slate-900 flex items-center justify-center">
    <p class="text-slate-400">Redirecting...</p>
  </div>
</template>
