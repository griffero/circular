<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { Loader2, CheckCircle, XCircle } from 'lucide-vue-next'
import Button from '@/components/ui/Button.vue'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const status = ref<'loading' | 'success' | 'error'>('loading')
const error = ref('')

onMounted(async () => {
  const token = route.query.token as string

  if (!token) {
    status.value = 'error'
    error.value = 'No token provided'
    return
  }

  try {
    await authStore.verifyMagicLink(token)
    status.value = 'success'
    
    // Redirect to home after a short delay
    setTimeout(() => {
      router.replace('/')
    }, 1500)
  } catch (err) {
    status.value = 'error'
    error.value = err instanceof Error ? err.message : 'Invalid or expired magic link'
  }
})
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 flex items-center justify-center px-4">
    <!-- Subtle grid pattern -->
    <div class="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PGRlZnM+PHBhdHRlcm4gaWQ9ImdyaWQiIHdpZHRoPSI0MCIgaGVpZ2h0PSI0MCIgcGF0dGVyblVuaXRzPSJ1c2VyU3BhY2VPblVzZSI+PHBhdGggZD0iTSAwIDEwIEwgNDAgMTAgTSAxMCAwIEwgMTAgNDAgTSAwIDIwIEwgNDAgMjAgTSAyMCAwIEwgMjAgNDAgTSAwIDMwIEwgNDAgMzAgTSAzMCAwIEwgMzAgNDAiIGZpbGw9Im5vbmUiIHN0cm9rZT0icmdiYSgyNTUsMjU1LDI1NSwwLjAyKSIgc3Ryb2tlLXdpZHRoPSIxIi8+PC9wYXR0ZXJuPjwvZGVmcz48cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSJ1cmwoI2dyaWQpIi8+PC9zdmc+')] opacity-40" />

    <div class="relative w-full max-w-md">
      <!-- Card -->
      <div class="bg-slate-800/50 backdrop-blur-xl border border-slate-700/50 rounded-2xl p-8 shadow-2xl">
        <!-- Logo -->
        <div class="text-center mb-8">
          <div class="inline-flex items-center justify-center w-14 h-14 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 text-white text-2xl font-bold mb-5 shadow-lg shadow-indigo-500/25">
            ◐
          </div>
        </div>

        <!-- Loading State -->
        <div v-if="status === 'loading'" class="text-center py-8">
          <Loader2 class="w-12 h-12 text-indigo-400 animate-spin mx-auto mb-4" />
          <h2 class="text-xl font-semibold text-white mb-2">Verifying your link</h2>
          <p class="text-slate-400 text-sm">Please wait while we sign you in...</p>
        </div>

        <!-- Success State -->
        <div v-else-if="status === 'success'" class="text-center py-8">
          <div class="w-16 h-16 rounded-full bg-emerald-500/10 flex items-center justify-center mx-auto mb-4">
            <CheckCircle class="w-8 h-8 text-emerald-400" />
          </div>
          <h2 class="text-xl font-semibold text-white mb-2">You're signed in!</h2>
          <p class="text-slate-400 text-sm">Redirecting you to the app...</p>
        </div>

        <!-- Error State -->
        <div v-else class="text-center py-8">
          <div class="w-16 h-16 rounded-full bg-red-500/10 flex items-center justify-center mx-auto mb-4">
            <XCircle class="w-8 h-8 text-red-400" />
          </div>
          <h2 class="text-xl font-semibold text-white mb-2">Link expired or invalid</h2>
          <p class="text-slate-400 text-sm mb-6">{{ error }}</p>
          
          <Button 
            @click="router.push('/login')"
            class="bg-gradient-to-r from-indigo-500 to-purple-600 hover:from-indigo-600 hover:to-purple-700 text-white font-medium px-6 py-2.5 rounded-lg transition-all duration-200"
          >
            Request new link
          </Button>
        </div>
      </div>

      <!-- Decorative elements -->
      <div class="absolute -top-20 -right-20 w-40 h-40 bg-purple-500/20 rounded-full blur-3xl" />
      <div class="absolute -bottom-20 -left-20 w-40 h-40 bg-indigo-500/20 rounded-full blur-3xl" />
    </div>
  </div>
</template>
