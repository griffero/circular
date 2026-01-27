<script setup lang="ts">
import { ref, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useAppStore } from '@/stores/app'
import { useEmojiStore } from '@/stores/emoji'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
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
const projects = computed(() => appStore.projects)

// Active tab
const activeTab = ref<'pulse' | 'forme' | 'popular' | 'recent'>('pulse')

// Mock project updates for demonstration
// In a real app, these would come from an API
const projectUpdates = computed(() => {
  // Group updates by time period
  const today: any[] = []
  const thisWeek: any[] = []
  const older: any[] = []
  
  // Generate some mock updates from projects
  projects.value.slice(0, 5).forEach((project, index) => {
    const update = {
      id: project.id,
      project: project,
      status: project.health === 'atRisk' ? 'at risk' : project.health === 'offTrack' ? 'off track' : 'on track',
      statusColor: project.health === 'atRisk' ? 'yellow' : project.health === 'offTrack' ? 'red' : 'green',
      author: {
        name: project.lead?.name || 'Team member',
        avatar: project.lead?.avatarUrl
      },
      timestamp: index === 0 ? '1 hour ago' : index === 1 ? '3 hours ago' : `${index + 1} days ago`,
      content: project.description || 'Project update content would appear here.',
      progress: [
        { name: 'Feature development', from: 50, to: 75 },
        { name: 'Bug fixes', from: 30, to: 45 }
      ],
      comments: Math.floor(Math.random() * 10)
    }
    
    if (index < 2) {
      today.push(update)
    } else if (index < 4) {
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

function getStatusBadgeClass(status: string) {
  if (status === 'at risk') return 'bg-yellow-500/20 text-yellow-400'
  if (status === 'off track') return 'bg-red-500/20 text-red-400'
  return 'bg-green-500/20 text-green-400'
}

function getStatusDotClass(status: string) {
  if (status === 'at risk') return 'bg-yellow-500'
  if (status === 'off track') return 'bg-red-500'
  return 'bg-green-500'
}
</script>

<template>
  <div class="h-full flex flex-col bg-[#0d0d0d]">
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

        <!-- Notification frequency prompt -->
        <div class="bg-[#151515] border border-[#252525] rounded-lg p-4 mb-8 flex items-center justify-between">
          <div>
            <p class="text-sm text-white">Choose your summary notification frequency</p>
            <p class="text-xs text-gray-500">Summary of Pulse updates delivered straight to your Inbox</p>
          </div>
          <div class="flex items-center gap-2">
            <button class="flex items-center gap-1 px-3 py-1.5 text-sm text-gray-400 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors">
              Never
              <ChevronDown class="w-3 h-3" />
            </button>
            <button class="px-4 py-1.5 text-sm bg-indigo-600 hover:bg-indigo-700 text-white rounded transition-colors">
              Confirm
            </button>
          </div>
        </div>

        <!-- Empty state if no updates -->
        <div v-if="projects.length === 0" class="text-center py-16">
          <p class="text-gray-500">No project updates yet</p>
          <p class="text-gray-600 text-sm mt-1">Updates will appear here as your team makes progress</p>
        </div>

        <!-- Project updates feed -->
        <div v-else>
          <!-- Today section -->
          <div v-if="projectUpdates.today.length > 0" class="mb-8">
            <div class="flex items-center gap-4 mb-4">
              <span class="text-xs text-gray-500 uppercase tracking-wide">Today</span>
              <div class="flex-1 h-px bg-[#252525]"></div>
            </div>
            
            <div class="space-y-4">
              <div 
                v-for="update in projectUpdates.today" 
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
                        :class="getStatusBadgeClass(update.status)"
                      >
                        <span class="w-1.5 h-1.5 rounded-full" :class="getStatusDotClass(update.status)"></span>
                        Project {{ update.status }}
                      </span>
                      <div class="flex items-center gap-1.5 text-xs text-gray-500">
                        <img 
                          v-if="update.author.avatar" 
                          :src="update.author.avatar" 
                          class="w-4 h-4 rounded-full"
                        />
                        <div 
                          v-else 
                          class="w-4 h-4 rounded-full bg-indigo-600 flex items-center justify-center text-[10px] text-white"
                        >
                          {{ update.author.name.charAt(0) }}
                        </div>
                        <span>{{ update.author.name }}</span>
                        <span class="text-gray-600">·</span>
                        <span>{{ update.timestamp }}</span>
                      </div>
                    </div>
                  </div>
                  <button class="p-1 text-gray-500 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors">
                    <MoreHorizontal class="w-4 h-4" />
                  </button>
                </div>

                <!-- Update content -->
                <div class="text-sm text-gray-300 mb-4 leading-relaxed">
                  {{ update.content }}
                </div>

                <!-- Progress section -->
                <div class="bg-[#111] border border-[#1f1f1f] rounded-lg p-3 mb-3">
                  <div class="text-xs text-gray-500 mb-2">Progress since Jan 26</div>
                  <div class="space-y-1.5">
                    <div 
                      v-for="(item, idx) in update.progress" 
                      :key="idx"
                      class="flex items-center gap-2 text-xs"
                    >
                      <span class="w-1.5 h-1.5 rounded-full bg-yellow-500"></span>
                      <span class="text-gray-300 flex-1">{{ item.name }}</span>
                      <span class="text-gray-500">{{ item.from }}% → {{ item.to }}%</span>
                    </div>
                  </div>
                </div>

                <!-- Footer -->
                <div class="flex items-center gap-3 text-xs text-gray-500">
                  <button class="flex items-center gap-1.5 hover:text-white transition-colors">
                    <MessageCircle class="w-3.5 h-3.5" />
                    {{ update.comments }} comments
                  </button>
                  <button class="flex items-center gap-1.5 hover:text-white transition-colors">
                    <Smile class="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- This week section -->
          <div v-if="projectUpdates.thisWeek.length > 0" class="mb-8">
            <div class="flex items-center gap-4 mb-4">
              <span class="text-xs text-gray-500 uppercase tracking-wide">This week</span>
              <div class="flex-1 h-px bg-[#252525]"></div>
            </div>
            
            <div class="space-y-4">
              <div 
                v-for="update in projectUpdates.thisWeek" 
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
                        :class="getStatusBadgeClass(update.status)"
                      >
                        <span class="w-1.5 h-1.5 rounded-full" :class="getStatusDotClass(update.status)"></span>
                        Project {{ update.status }}
                      </span>
                      <div class="flex items-center gap-1.5 text-xs text-gray-500">
                        <img 
                          v-if="update.author.avatar" 
                          :src="update.author.avatar" 
                          class="w-4 h-4 rounded-full"
                        />
                        <div 
                          v-else 
                          class="w-4 h-4 rounded-full bg-indigo-600 flex items-center justify-center text-[10px] text-white"
                        >
                          {{ update.author.name.charAt(0) }}
                        </div>
                        <span>{{ update.author.name }}</span>
                        <span class="text-gray-600">·</span>
                        <span>{{ update.timestamp }}</span>
                      </div>
                    </div>
                  </div>
                  <button class="p-1 text-gray-500 hover:text-white hover:bg-[#1a1a1a] rounded transition-colors">
                    <MoreHorizontal class="w-4 h-4" />
                  </button>
                </div>

                <!-- Update content -->
                <div class="text-sm text-gray-300 mb-4 leading-relaxed">
                  {{ update.content }}
                </div>

                <!-- Progress section -->
                <div class="bg-[#111] border border-[#1f1f1f] rounded-lg p-3 mb-3">
                  <div class="text-xs text-gray-500 mb-2">Progress since Jan 23</div>
                  <div class="space-y-1.5">
                    <div 
                      v-for="(item, idx) in update.progress" 
                      :key="idx"
                      class="flex items-center gap-2 text-xs"
                    >
                      <span class="w-1.5 h-1.5 rounded-full bg-yellow-500"></span>
                      <span class="text-gray-300 flex-1">{{ item.name }}</span>
                      <span class="text-gray-500">{{ item.from }}% → {{ item.to }}%</span>
                    </div>
                  </div>
                </div>

                <!-- Footer -->
                <div class="flex items-center gap-3 text-xs text-gray-500">
                  <button class="flex items-center gap-1.5 hover:text-white transition-colors">
                    <MessageCircle class="w-3.5 h-3.5" />
                    {{ update.comments }} comments
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
