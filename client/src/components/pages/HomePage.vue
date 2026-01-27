<script setup lang="ts">
import { ref, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useAppStore, type ProjectUpdate } from '@/stores/app'
import { useEmojiStore } from '@/stores/emoji'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
import UserLink from '@/components/ui/UserLink.vue'
import {
  Zap,
  MessageCircle,
  Smile,
  ChevronDown,
  MoreHorizontal
} from 'lucide-vue-next'

const authStore = useAuthStore()
const appStore = useAppStore()
const emojiStore = useEmojiStore()

const user = computed(() => authStore.user)
const projectUpdates = computed(() => appStore.projectUpdates)

// Active tab
const activeTab = ref<'pulse' | 'forme' | 'popular' | 'recent'>('pulse')

// Group updates by time period
const groupedUpdates = computed(() => {
  const today: ProjectUpdate[] = []
  const thisWeek: ProjectUpdate[] = []
  const older: ProjectUpdate[] = []
  
  const now = new Date()
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  const weekStart = new Date(todayStart)
  weekStart.setDate(weekStart.getDate() - 7)
  
  projectUpdates.value.forEach(update => {
    const updateDate = new Date(update.createdAt)
    if (updateDate >= todayStart) {
      today.push(update)
    } else if (updateDate >= weekStart) {
      thisWeek.push(update)
    } else {
      older.push(update)
    }
  })
  
  return { today, thisWeek, older }
})

// Check if has emoji
function hasEmoji(icon?: string | null): boolean {
  if (!icon) return false
  if (emojiStore.getEmojiUrl(icon)) return true
  const stripped = icon.replace(/^:|:$/g, '')
  return /^[\p{Emoji}\u200d]+$/u.test(stripped) && stripped.length <= 8
}

function getStatusBadgeClass(health: string | null) {
  if (health === 'atRisk') return 'bg-yellow-500/20 text-yellow-400'
  if (health === 'offTrack') return 'bg-red-500/20 text-red-400'
  return 'bg-green-500/20 text-green-400'
}

function getStatusDotClass(health: string | null) {
  if (health === 'atRisk') return 'bg-yellow-500'
  if (health === 'offTrack') return 'bg-red-500'
  return 'bg-green-500'
}

function getStatusLabel(health: string | null) {
  if (health === 'atRisk') return 'at risk'
  if (health === 'offTrack') return 'off track'
  return 'on track'
}

function formatTimeAgo(dateStr: string): string {
  const date = new Date(dateStr)
  const now = new Date()
  const diff = now.getTime() - date.getTime()
  
  const minutes = Math.floor(diff / 60000)
  const hours = Math.floor(diff / 3600000)
  const days = Math.floor(diff / 86400000)
  
  if (minutes < 60) return `${minutes} minute${minutes !== 1 ? 's' : ''} ago`
  if (hours < 24) return `${hours} hour${hours !== 1 ? 's' : ''} ago`
  return `${days} day${days !== 1 ? 's' : ''} ago`
}
</script>

<template>
  <div class="min-h-full flex flex-col bg-[#0d0d0d]">
    <!-- Header with tabs -->
    <div class="flex items-center justify-between px-4 py-2 border-b border-[#1f1f1f]">
      <div class="flex items-center gap-1">
        <button 
          @click="activeTab = 'pulse'"
          :class="[
            'px-3 py-1.5 text-sm rounded-md transition-colors',
            activeTab === 'pulse' 
              ? 'bg-[#1a1a1a] text-white' 
              : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
          ]"
        >
          Pulse
        </button>
        <button 
          @click="activeTab = 'forme'"
          :class="[
            'px-3 py-1.5 text-sm rounded-md transition-colors',
            activeTab === 'forme' 
              ? 'bg-[#1a1a1a] text-white' 
              : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
          ]"
        >
          For me
        </button>
        <button 
          @click="activeTab = 'popular'"
          :class="[
            'px-3 py-1.5 text-sm rounded-md transition-colors',
            activeTab === 'popular' 
              ? 'bg-[#1a1a1a] text-white' 
              : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
          ]"
        >
          Popular
        </button>
        <button 
          @click="activeTab = 'recent'"
          :class="[
            'px-3 py-1.5 text-sm rounded-md transition-colors',
            activeTab === 'recent' 
              ? 'bg-[#1a1a1a] text-white' 
              : 'text-gray-400 hover:text-white hover:bg-[#1a1a1a]'
          ]"
        >
          Recent
        </button>
      </div>
      
      <div class="flex items-center gap-2">
        <button class="p-1.5 text-gray-400 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors">
          <span class="text-xs">Subscription</span>
          <ChevronDown class="w-3 h-3 inline ml-1" />
        </button>
      </div>
    </div>

    <!-- Content -->
    <div class="flex-1 overflow-y-auto">
      <div class="max-w-3xl mx-auto px-6 py-8">
        <!-- Welcome banner -->
        <div class="text-center mb-8">
          <div class="flex justify-center mb-4">
            <Zap class="w-12 h-12 text-gray-600" />
          </div>
          <h1 class="text-xl font-semibold text-white mb-2">Welcome to Pulse</h1>
          <p class="text-gray-500 text-sm max-w-md mx-auto">
            Your feed to keep up with your company's product work, tailored to your needs and interests.
          </p>
        </div>

        <!-- Empty state if no updates -->
        <div v-if="projectUpdates.length === 0" class="text-center py-16">
          <p class="text-gray-500">No project updates yet</p>
          <p class="text-gray-600 text-sm mt-1">Updates will appear here as your team makes progress</p>
        </div>

        <!-- Project updates feed -->
        <div v-else>
          <!-- Today section -->
          <div v-if="groupedUpdates.today.length > 0" class="mb-8">
            <div class="flex items-center gap-4 mb-4">
              <span class="text-xs text-gray-500 uppercase tracking-wide">Today</span>
              <div class="flex-1 h-px bg-[#252525]"></div>
            </div>
            
            <div class="space-y-4">
              <div 
                v-for="update in groupedUpdates.today" 
                :key="update.id"
                class="bg-[#0d0d0d] border border-[#1f1f1f] rounded-lg p-5 hover:border-[#333] transition-colors"
              >
                <!-- Update header -->
                <div class="flex items-start justify-between mb-3">
                  <div>
                    <router-link 
                      :to="`/project/${update.project.slug}`"
                      class="text-lg font-medium text-white hover:text-indigo-400 transition-colors"
                    >
                      {{ update.project.name }}
                    </router-link>
                    <div class="flex items-center gap-2 mt-1">
                      <span 
                        class="flex items-center gap-1.5 text-xs px-2 py-0.5 rounded"
                        :class="getStatusBadgeClass(update.health)"
                      >
                        <span class="w-1.5 h-1.5 rounded-full" :class="getStatusDotClass(update.health)"></span>
                        Project {{ getStatusLabel(update.health) }}
                      </span>
                      <div class="flex items-center gap-1.5 text-xs text-gray-500">
                        <UserLink
                          :userId="update.user.id"
                          :name="update.user.name"
                          :displayName="update.user.displayName"
                          :avatarUrl="update.user.avatarUrl"
                          avatarSize="xs"
                          class="text-gray-400"
                        />
                        <span class="text-gray-600">·</span>
                        <span>{{ formatTimeAgo(update.createdAt) }}</span>
                      </div>
                    </div>
                  </div>
                  <button class="p-1 text-gray-500 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors">
                    <MoreHorizontal class="w-4 h-4" />
                  </button>
                </div>

                <!-- Update content -->
                <div class="text-sm text-gray-300 mb-4 leading-relaxed whitespace-pre-wrap">
                  {{ update.body }}
                </div>

                <!-- Footer -->
                <div class="flex items-center gap-3 text-xs text-gray-500">
                  <button class="flex items-center gap-1.5 hover:text-white transition-colors">
                    <MessageCircle class="w-3.5 h-3.5" />
                    Comments
                  </button>
                  <button class="flex items-center gap-1.5 hover:text-white transition-colors">
                    <Smile class="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- This week section -->
          <div v-if="groupedUpdates.thisWeek.length > 0" class="mb-8">
            <div class="flex items-center gap-4 mb-4">
              <span class="text-xs text-gray-500 uppercase tracking-wide">This week</span>
              <div class="flex-1 h-px bg-[#252525]"></div>
            </div>
            
            <div class="space-y-4">
              <div 
                v-for="update in groupedUpdates.thisWeek" 
                :key="update.id"
                class="bg-[#0d0d0d] border border-[#1f1f1f] rounded-lg p-5 hover:border-[#333] transition-colors"
              >
                <!-- Update header -->
                <div class="flex items-start justify-between mb-3">
                  <div>
                    <router-link 
                      :to="`/project/${update.project.slug}`"
                      class="text-lg font-medium text-white hover:text-indigo-400 transition-colors"
                    >
                      {{ update.project.name }}
                    </router-link>
                    <div class="flex items-center gap-2 mt-1">
                      <span 
                        class="flex items-center gap-1.5 text-xs px-2 py-0.5 rounded"
                        :class="getStatusBadgeClass(update.health)"
                      >
                        <span class="w-1.5 h-1.5 rounded-full" :class="getStatusDotClass(update.health)"></span>
                        Project {{ getStatusLabel(update.health) }}
                      </span>
                      <div class="flex items-center gap-1.5 text-xs text-gray-500">
                        <UserLink
                          :userId="update.user.id"
                          :name="update.user.name"
                          :displayName="update.user.displayName"
                          :avatarUrl="update.user.avatarUrl"
                          avatarSize="xs"
                          class="text-gray-400"
                        />
                        <span class="text-gray-600">·</span>
                        <span>{{ formatTimeAgo(update.createdAt) }}</span>
                      </div>
                    </div>
                  </div>
                  <button class="p-1 text-gray-500 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors">
                    <MoreHorizontal class="w-4 h-4" />
                  </button>
                </div>

                <!-- Update content -->
                <div class="text-sm text-gray-300 mb-4 leading-relaxed whitespace-pre-wrap">
                  {{ update.body }}
                </div>

                <!-- Footer -->
                <div class="flex items-center gap-3 text-xs text-gray-500">
                  <button class="flex items-center gap-1.5 hover:text-white transition-colors">
                    <MessageCircle class="w-3.5 h-3.5" />
                    Comments
                  </button>
                  <button class="flex items-center gap-1.5 hover:text-white transition-colors">
                    <Smile class="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Older section -->
          <div v-if="groupedUpdates.older.length > 0" class="mb-8">
            <div class="flex items-center gap-4 mb-4">
              <span class="text-xs text-gray-500 uppercase tracking-wide">Older</span>
              <div class="flex-1 h-px bg-[#252525]"></div>
            </div>
            
            <div class="space-y-4">
              <div 
                v-for="update in groupedUpdates.older" 
                :key="update.id"
                class="bg-[#0d0d0d] border border-[#1f1f1f] rounded-lg p-5 hover:border-[#333] transition-colors"
              >
                <!-- Update header -->
                <div class="flex items-start justify-between mb-3">
                  <div>
                    <router-link 
                      :to="`/project/${update.project.slug}`"
                      class="text-lg font-medium text-white hover:text-indigo-400 transition-colors"
                    >
                      {{ update.project.name }}
                    </router-link>
                    <div class="flex items-center gap-2 mt-1">
                      <span 
                        class="flex items-center gap-1.5 text-xs px-2 py-0.5 rounded"
                        :class="getStatusBadgeClass(update.health)"
                      >
                        <span class="w-1.5 h-1.5 rounded-full" :class="getStatusDotClass(update.health)"></span>
                        Project {{ getStatusLabel(update.health) }}
                      </span>
                      <div class="flex items-center gap-1.5 text-xs text-gray-500">
                        <UserLink
                          :userId="update.user.id"
                          :name="update.user.name"
                          :displayName="update.user.displayName"
                          :avatarUrl="update.user.avatarUrl"
                          avatarSize="xs"
                          class="text-gray-400"
                        />
                        <span class="text-gray-600">·</span>
                        <span>{{ formatTimeAgo(update.createdAt) }}</span>
                      </div>
                    </div>
                  </div>
                  <button class="p-1 text-gray-500 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors">
                    <MoreHorizontal class="w-4 h-4" />
                  </button>
                </div>

                <!-- Update content -->
                <div class="text-sm text-gray-300 mb-4 leading-relaxed whitespace-pre-wrap">
                  {{ update.body }}
                </div>

                <!-- Footer -->
                <div class="flex items-center gap-3 text-xs text-gray-500">
                  <button class="flex items-center gap-1.5 hover:text-white transition-colors">
                    <MessageCircle class="w-3.5 h-3.5" />
                    Comments
                  </button>
                  <button class="flex items-center gap-1.5 hover:text-white transition-colors">
                    <Smile class="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
