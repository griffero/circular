<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import { useAppStore } from '@/stores/app'
import { useEmojiStore } from '@/stores/emoji'
import api from '@/api/client'
import EmojiIcon from '@/components/ui/EmojiIcon.vue'
import { 
  X, ChevronDown, Circle, Minus, Users, Calendar, Target,
  Lightbulb, Tag, GitBranch, Plus, Smile
} from 'lucide-vue-next'

const props = defineProps<{
  open: boolean
}>()

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'created', project: unknown): void
}>()

const appStore = useAppStore()
const emojiStore = useEmojiStore()

// Form state
const name = ref('')
const summary = ref('')
const description = ref('')
const icon = ref('')
const color = ref('#bec2c8')
const status = ref('backlog')
const priority = ref(0)
const leadId = ref<string | null>(null)
const startDate = ref<string | null>(null)
const targetDate = ref<string | null>(null)
const creating = ref(false)
const error = ref('')

// UI state
const showIconPicker = ref(false)
const showStatusPicker = ref(false)
const showPriorityPicker = ref(false)
const showLeadPicker = ref(false)
const showStartDatePicker = ref(false)
const showTargetDatePicker = ref(false)
const milestonesExpanded = ref(false)

const statuses = [
  { value: 'backlog', label: 'Idea', color: '#4f4f4f' },
  { value: 'planned', label: 'Planned', color: '#5e6ad2' },
  { value: 'started', label: 'Started', color: '#26b5ce' },
  { value: 'paused', label: 'Paused', color: '#f2994a' },
  { value: 'completed', label: 'Completed', color: '#4cb782' },
  { value: 'canceled', label: 'Canceled', color: '#95a2b3' },
]

const priorities = [
  { value: 0, label: 'No priority', icon: Minus },
  { value: 1, label: 'Urgent', icon: null },
  { value: 2, label: 'High', icon: null },
  { value: 3, label: 'Medium', icon: null },
  { value: 4, label: 'Low', icon: null },
]

const currentStatus = computed(() => statuses.find(s => s.value === status.value) || statuses[0])
const currentPriority = computed(() => priorities.find(p => p.value === priority.value) || priorities[0])

const teams = computed(() => appStore.teams)
const currentTeam = computed(() => teams.value[0])
const users = computed(() => appStore.users || [])
const selectedLead = computed(() => users.value.find(u => u.id === leadId.value))

// Common emojis for quick selection
const commonEmojis = [
  ':rocket:', ':star:', ':fire:', ':zap:', ':sparkles:', ':tada:',
  ':checkmark:', ':bug:', ':gear:', ':book:', ':bulb:', ':target:',
]

watch(() => props.open, (open) => {
  if (open) {
    name.value = ''
    summary.value = ''
    description.value = ''
    icon.value = ''
    color.value = '#bec2c8'
    status.value = 'backlog'
    priority.value = 0
    leadId.value = null
    startDate.value = null
    targetDate.value = null
    error.value = ''
    showIconPicker.value = false
  }
})

function selectEmoji(emoji: string) {
  icon.value = emoji
  showIconPicker.value = false
}

async function handleSubmit() {
  if (!name.value.trim()) return

  creating.value = true
  error.value = ''

  try {
    const response = await api.post('/api/v1/projects', {
      project: {
        name: name.value.trim(),
        description: description.value || summary.value || undefined,
        icon: icon.value || undefined,
        color: color.value,
        state: status.value,
        leadId: leadId.value || undefined,
        startDate: startDate.value || undefined,
        targetDate: targetDate.value || undefined,
      }
    })

    if (response) {
      await appStore.fetchProjects()
      emit('created', response)
      emit('close')
    }
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to create project'
  } finally {
    creating.value = false
  }
}

function closeAllPickers() {
  showIconPicker.value = false
  showStatusPicker.value = false
  showPriorityPicker.value = false
  showLeadPicker.value = false
  showStartDatePicker.value = false
  showTargetDatePicker.value = false
}
</script>

<template>
  <Teleport to="body">
    <Transition
      enter-active-class="duration-200 ease-out"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="duration-150 ease-in"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="open"
        class="fixed inset-0 z-50 flex items-center justify-center p-4"
        @click.self="emit('close')"
      >
        <!-- Backdrop -->
        <div class="absolute inset-0 bg-black/70" @click="emit('close')" />

        <!-- Modal Panel -->
        <div class="relative w-full max-w-2xl bg-[#1a1a1a] rounded-xl shadow-2xl border border-[#333] overflow-hidden">
          <!-- Header -->
          <div class="flex items-center justify-between px-4 py-3 border-b border-[#333]">
            <div class="flex items-center gap-2">
              <!-- Team badge -->
              <div v-if="currentTeam" class="flex items-center gap-1.5 px-2 py-1 bg-[#222] rounded text-sm">
                <EmojiIcon :name="currentTeam.icon" :fallback="currentTeam.key.substring(0, 2)" size="sm" />
                <span class="text-white font-medium">{{ currentTeam.key }}</span>
              </div>
              
              <!-- Template button -->
              <button class="flex items-center gap-1.5 px-2 py-1 text-sm text-gray-400 hover:text-white hover:bg-[#222] rounded transition-colors">
                <svg class="w-4 h-4" viewBox="0 0 16 16" fill="currentColor">
                  <path d="M14 4.5V14a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V2a2 2 0 0 1 2-2h5.5L14 4.5zm-3 0A1.5 1.5 0 0 1 9.5 3V1H4a1 1 0 0 0-1 1v12a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1V4.5h-2z"/>
                </svg>
                Template
              </button>
            </div>
            
            <button 
              @click="emit('close')"
              class="p-1.5 text-gray-400 hover:text-white hover:bg-[#333] rounded transition-colors"
            >
              <X class="w-5 h-5" />
            </button>
          </div>

          <!-- Content -->
          <div class="p-6">
            <!-- Icon selector -->
            <div class="relative mb-4">
              <button
                @click="showIconPicker = !showIconPicker"
                class="w-10 h-10 rounded-lg bg-[#222] hover:bg-[#333] flex items-center justify-center transition-colors border border-[#333]"
              >
                <EmojiIcon v-if="icon" :name="icon" fallback="" size="lg" />
                <Smile v-else class="w-5 h-5 text-gray-500" />
              </button>
              
              <!-- Emoji picker dropdown -->
              <div 
                v-if="showIconPicker"
                class="absolute top-12 left-0 z-10 p-3 bg-[#222] rounded-lg border border-[#333] shadow-xl"
              >
                <div class="grid grid-cols-6 gap-2">
                  <button
                    v-for="emoji in commonEmojis"
                    :key="emoji"
                    @click="selectEmoji(emoji)"
                    class="w-8 h-8 flex items-center justify-center hover:bg-[#333] rounded transition-colors"
                  >
                    <EmojiIcon :name="emoji" fallback="" size="md" />
                  </button>
                </div>
                <button
                  @click="icon = ''; showIconPicker = false"
                  class="mt-2 w-full text-xs text-gray-500 hover:text-white py-1"
                >
                  Remove icon
                </button>
              </div>
            </div>

            <!-- Project name -->
            <input
              v-model="name"
              type="text"
              placeholder="Project name"
              class="w-full text-2xl font-medium bg-transparent border-none outline-none text-white placeholder-gray-600 mb-2"
              autofocus
            />

            <!-- Summary -->
            <input
              v-model="summary"
              type="text"
              placeholder="Add a short summary..."
              class="w-full text-sm bg-transparent border-none outline-none text-gray-400 placeholder-gray-600 mb-4"
            />

            <!-- Metadata buttons row -->
            <div class="flex flex-wrap items-center gap-2 mb-6">
              <!-- Status -->
              <div class="relative">
                <button
                  @click="showStatusPicker = !showStatusPicker; showPriorityPicker = false; showLeadPicker = false"
                  class="flex items-center gap-1.5 px-2.5 py-1.5 text-sm rounded-md border border-[#333] hover:bg-[#222] transition-colors"
                >
                  <Circle class="w-3.5 h-3.5" :style="{ color: currentStatus.color }" />
                  <span class="text-gray-300">{{ currentStatus.label }}</span>
                </button>
                <div 
                  v-if="showStatusPicker"
                  class="absolute top-full left-0 mt-1 z-20 py-1 bg-[#222] rounded-lg border border-[#333] shadow-xl min-w-[140px]"
                >
                  <button
                    v-for="s in statuses"
                    :key="s.value"
                    @click="status = s.value; showStatusPicker = false"
                    class="w-full flex items-center gap-2 px-3 py-1.5 text-sm text-gray-300 hover:bg-[#333] transition-colors"
                  >
                    <Circle class="w-3.5 h-3.5" :style="{ color: s.color }" />
                    {{ s.label }}
                  </button>
                </div>
              </div>

              <!-- Priority -->
              <div class="relative">
                <button
                  @click="showPriorityPicker = !showPriorityPicker; showStatusPicker = false; showLeadPicker = false"
                  class="flex items-center gap-1.5 px-2.5 py-1.5 text-sm rounded-md border border-[#333] hover:bg-[#222] transition-colors"
                >
                  <Minus class="w-3.5 h-3.5 text-gray-500" />
                  <span class="text-gray-300">{{ currentPriority.label }}</span>
                </button>
                <div 
                  v-if="showPriorityPicker"
                  class="absolute top-full left-0 mt-1 z-20 py-1 bg-[#222] rounded-lg border border-[#333] shadow-xl min-w-[140px]"
                >
                  <button
                    v-for="p in priorities"
                    :key="p.value"
                    @click="priority = p.value; showPriorityPicker = false"
                    class="w-full flex items-center gap-2 px-3 py-1.5 text-sm text-gray-300 hover:bg-[#333] transition-colors"
                  >
                    <Minus class="w-3.5 h-3.5 text-gray-500" />
                    {{ p.label }}
                  </button>
                </div>
              </div>

              <!-- Lead -->
              <div class="relative">
                <button
                  @click="showLeadPicker = !showLeadPicker; showStatusPicker = false; showPriorityPicker = false"
                  class="flex items-center gap-1.5 px-2.5 py-1.5 text-sm rounded-md border border-[#333] hover:bg-[#222] transition-colors"
                >
                  <Users class="w-3.5 h-3.5 text-gray-500" />
                  <span class="text-gray-300">{{ selectedLead?.name || 'Lead' }}</span>
                </button>
                <div 
                  v-if="showLeadPicker"
                  class="absolute top-full left-0 mt-1 z-20 py-1 bg-[#222] rounded-lg border border-[#333] shadow-xl min-w-[180px] max-h-60 overflow-auto"
                >
                  <button
                    @click="leadId = null; showLeadPicker = false"
                    class="w-full flex items-center gap-2 px-3 py-1.5 text-sm text-gray-400 hover:bg-[#333] transition-colors"
                  >
                    No lead
                  </button>
                  <button
                    v-for="user in users"
                    :key="user.id"
                    @click="leadId = user.id; showLeadPicker = false"
                    class="w-full flex items-center gap-2 px-3 py-1.5 text-sm text-gray-300 hover:bg-[#333] transition-colors"
                  >
                    <img v-if="user.avatarUrl" :src="user.avatarUrl" class="w-5 h-5 rounded-full" />
                    <div v-else class="w-5 h-5 rounded-full bg-indigo-600 flex items-center justify-center text-xs text-white">
                      {{ user.name?.charAt(0) }}
                    </div>
                    {{ user.name }}
                  </button>
                </div>
              </div>

              <!-- Members -->
              <button class="flex items-center gap-1.5 px-2.5 py-1.5 text-sm rounded-md border border-[#333] hover:bg-[#222] transition-colors text-gray-400">
                <Users class="w-3.5 h-3.5" />
                Members
              </button>

              <!-- Start date -->
              <div class="relative">
                <button
                  @click="showStartDatePicker = !showStartDatePicker"
                  class="flex items-center gap-1.5 px-2.5 py-1.5 text-sm rounded-md border border-[#333] hover:bg-[#222] transition-colors"
                >
                  <Calendar class="w-3.5 h-3.5 text-gray-500" />
                  <span class="text-gray-300">{{ startDate || 'Start' }}</span>
                </button>
                <input
                  v-if="showStartDatePicker"
                  type="date"
                  v-model="startDate"
                  @change="showStartDatePicker = false"
                  class="absolute top-full left-0 mt-1 z-20 bg-[#222] border border-[#333] rounded-lg p-2 text-sm text-white"
                />
              </div>

              <!-- Target date -->
              <div class="relative">
                <button
                  @click="showTargetDatePicker = !showTargetDatePicker"
                  class="flex items-center gap-1.5 px-2.5 py-1.5 text-sm rounded-md border border-[#333] hover:bg-[#222] transition-colors"
                >
                  <Target class="w-3.5 h-3.5 text-gray-500" />
                  <span class="text-gray-300">{{ targetDate || 'Target' }}</span>
                </button>
                <input
                  v-if="showTargetDatePicker"
                  type="date"
                  v-model="targetDate"
                  @change="showTargetDatePicker = false"
                  class="absolute top-full left-0 mt-1 z-20 bg-[#222] border border-[#333] rounded-lg p-2 text-sm text-white"
                />
              </div>

              <!-- Initiatives -->
              <button class="flex items-center gap-1.5 px-2.5 py-1.5 text-sm rounded-md border border-[#333] hover:bg-[#222] transition-colors text-gray-400">
                <Lightbulb class="w-3.5 h-3.5" />
                Initiatives
              </button>

              <!-- Labels -->
              <button class="flex items-center gap-1.5 px-2.5 py-1.5 text-sm rounded-md border border-[#333] hover:bg-[#222] transition-colors text-gray-400">
                <Tag class="w-3.5 h-3.5" />
                Labels
              </button>

              <!-- Dependencies -->
              <button class="flex items-center gap-1.5 px-2.5 py-1.5 text-sm rounded-md border border-[#333] hover:bg-[#222] transition-colors text-gray-400">
                <GitBranch class="w-3.5 h-3.5" />
                Dependencies
              </button>
            </div>

            <!-- Description -->
            <textarea
              v-model="description"
              rows="6"
              placeholder="Write a description, a project brief, or collect ideas..."
              class="w-full px-0 py-2 text-sm bg-transparent border-none outline-none text-gray-300 placeholder-gray-600 resize-none"
            />

            <!-- Error message -->
            <div v-if="error" class="mt-4 p-3 bg-red-900/20 border border-red-800 rounded-lg text-sm text-red-400">
              {{ error }}
            </div>
          </div>

          <!-- Milestones section -->
          <div class="border-t border-[#333]">
            <button
              @click="milestonesExpanded = !milestonesExpanded"
              class="w-full flex items-center justify-between px-6 py-3 text-sm text-gray-300 hover:bg-[#222] transition-colors"
            >
              <span>Milestones</span>
              <Plus class="w-4 h-4 text-gray-500" />
            </button>
          </div>

          <!-- Footer -->
          <div class="flex items-center justify-end gap-3 px-6 py-4 border-t border-[#333] bg-[#111]">
            <button
              @click="emit('close')"
              class="px-4 py-2 text-sm text-gray-300 hover:text-white hover:bg-[#222] rounded-lg transition-colors"
            >
              Cancel
            </button>
            <button
              @click="handleSubmit"
              :disabled="!name.trim() || creating"
              class="px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed rounded-lg transition-colors"
            >
              {{ creating ? 'Creating...' : 'Create project' }}
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>
