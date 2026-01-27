<script setup lang="ts">
import { computed } from 'vue'
import { useEmojiStore } from '@/stores/emoji'

const props = defineProps<{
  text: string
}>()

const emojiStore = useEmojiStore()

interface TextPart {
  type: 'text' | 'emoji'
  content: string
  url?: string
}

// Parse text and split into parts (text and emojis)
const parsedParts = computed((): TextPart[] => {
  const parts: TextPart[] = []
  const emojiRegex = /:([a-zA-Z0-9_+-]+):/g
  
  let lastIndex = 0
  let match: RegExpExecArray | null
  
  while ((match = emojiRegex.exec(props.text)) !== null) {
    // Add text before the emoji
    if (match.index > lastIndex) {
      parts.push({
        type: 'text',
        content: props.text.slice(lastIndex, match.index)
      })
    }
    
    // Check if this is a known emoji
    const emojiName = match[1]
    const emojiUrl = emojiStore.getEmojiUrl(emojiName)
    
    if (emojiUrl) {
      // It's a custom emoji with an image
      parts.push({
        type: 'emoji',
        content: emojiName,
        url: emojiUrl
      })
    } else {
      // Check if it's a standard emoji shortcode
      const standardEmoji = getStandardEmoji(emojiName)
      if (standardEmoji) {
        parts.push({
          type: 'emoji',
          content: standardEmoji
        })
      } else {
        // Not a known emoji, keep as text
        parts.push({
          type: 'text',
          content: match[0]
        })
      }
    }
    
    lastIndex = match.index + match[0].length
  }
  
  // Add remaining text
  if (lastIndex < props.text.length) {
    parts.push({
      type: 'text',
      content: props.text.slice(lastIndex)
    })
  }
  
  return parts
})

// Map common emoji shortcodes to Unicode emojis
function getStandardEmoji(name: string): string | null {
  const emojiMap: Record<string, string> = {
    // Faces
    'smile': '😊',
    'smiley': '😃',
    'grinning': '😀',
    'grin': '😁',
    'joy': '😂',
    'laughing': '😆',
    'satisfied': '😆',
    'sweat_smile': '😅',
    'rolling_on_the_floor_laughing': '🤣',
    'rofl': '🤣',
    'slightly_smiling_face': '🙂',
    'upside_down_face': '🙃',
    'wink': '😉',
    'blush': '😊',
    'innocent': '😇',
    'heart_eyes': '😍',
    'smiling_face_with_3_hearts': '🥰',
    'star_struck': '🤩',
    'kissing_heart': '😘',
    'kissing': '😗',
    'relaxed': '☺️',
    'kissing_closed_eyes': '😚',
    'kissing_smiling_eyes': '😙',
    'yum': '😋',
    'stuck_out_tongue': '😛',
    'stuck_out_tongue_winking_eye': '😜',
    'stuck_out_tongue_closed_eyes': '😝',
    'money_mouth_face': '🤑',
    'hugs': '🤗',
    'hugging_face': '🤗',
    'thinking_face': '🤔',
    'thinking': '🤔',
    'shushing_face': '🤫',
    'zipper_mouth_face': '🤐',
    'raised_eyebrow': '🤨',
    'neutral_face': '😐',
    'expressionless': '😑',
    'no_mouth': '😶',
    'smirk': '😏',
    'unamused': '😒',
    'roll_eyes': '🙄',
    'grimacing': '😬',
    'lying_face': '🤥',
    'relieved': '😌',
    'pensive': '😔',
    'sleepy': '😪',
    'drooling_face': '🤤',
    'sleeping': '😴',
    'mask': '😷',
    'face_with_thermometer': '🤒',
    'face_with_head_bandage': '🤕',
    'nauseated_face': '🤢',
    'sneezing_face': '🤧',
    'hot_face': '🥵',
    'cold_face': '🥶',
    'woozy_face': '🥴',
    'dizzy_face': '😵',
    'exploding_head': '🤯',
    'cowboy_hat_face': '🤠',
    'partying_face': '🥳',
    'sunglasses': '😎',
    'nerd_face': '🤓',
    'monocle_face': '🧐',
    'confused': '😕',
    'worried': '😟',
    'slightly_frowning_face': '🙁',
    'frowning_face': '☹️',
    'open_mouth': '😮',
    'hushed': '😯',
    'astonished': '😲',
    'flushed': '😳',
    'pleading_face': '🥺',
    'frowning': '😦',
    'anguished': '😧',
    'fearful': '😨',
    'cold_sweat': '😰',
    'disappointed_relieved': '😥',
    'cry': '😢',
    'sob': '😭',
    'scream': '😱',
    'confounded': '😖',
    'persevere': '😣',
    'disappointed': '😞',
    'sweat': '😓',
    'weary': '😩',
    'tired_face': '😫',
    'yawning_face': '🥱',
    'triumph': '😤',
    'rage': '😡',
    'angry': '😠',
    'face_with_symbols_on_mouth': '🤬',
    'smiling_imp': '😈',
    'imp': '👿',
    'skull': '💀',
    'skull_and_crossbones': '☠️',
    'poop': '💩',
    'hankey': '💩',
    'clown_face': '🤡',
    'japanese_ogre': '👹',
    'japanese_goblin': '👺',
    'ghost': '👻',
    'alien': '👽',
    'space_invader': '👾',
    'robot_face': '🤖',
    
    // Sad/negative
    'sad': '😢',
    'cry': '😢',
    'crying': '😢',
    'frown': '☹️',
    'worried': '😟',
    'disappointed': '😞',
    
    // Hands
    'thumbsup': '👍',
    '+1': '👍',
    'thumbsdown': '👎',
    '-1': '👎',
    'ok_hand': '👌',
    'pinched_fingers': '🤌',
    'pinching_hand': '🤏',
    'v': '✌️',
    'crossed_fingers': '🤞',
    'love_you_gesture': '🤟',
    'metal': '🤘',
    'call_me_hand': '🤙',
    'point_left': '👈',
    'point_right': '👉',
    'point_up_2': '👆',
    'point_down': '👇',
    'point_up': '☝️',
    'raised_hand': '✋',
    'raised_back_of_hand': '🤚',
    'hand_with_fingers_splayed': '🖐️',
    'vulcan_salute': '🖖',
    'wave': '👋',
    'clap': '👏',
    'open_hands': '👐',
    'raised_hands': '🙌',
    'palms_up_together': '🤲',
    'pray': '🙏',
    'handshake': '🤝',
    'nail_care': '💅',
    'muscle': '💪',
    'mechanical_arm': '🦾',
    'mechanical_leg': '🦿',
    'leg': '🦵',
    'foot': '🦶',
    
    // Hearts
    'heart': '❤️',
    'red_heart': '❤️',
    'orange_heart': '🧡',
    'yellow_heart': '💛',
    'green_heart': '💚',
    'blue_heart': '💙',
    'purple_heart': '💜',
    'black_heart': '🖤',
    'brown_heart': '🤎',
    'white_heart': '🤍',
    'broken_heart': '💔',
    'heart_exclamation': '❣️',
    'two_hearts': '💕',
    'revolving_hearts': '💞',
    'heartbeat': '💓',
    'heartpulse': '💗',
    'sparkling_heart': '💖',
    'cupid': '💘',
    'gift_heart': '💝',
    'heart_decoration': '💟',
    
    // Objects
    'fire': '🔥',
    'star': '⭐',
    'sparkles': '✨',
    'zap': '⚡',
    'boom': '💥',
    'tada': '🎉',
    'confetti_ball': '🎊',
    'balloon': '🎈',
    'trophy': '🏆',
    'medal': '🏅',
    'first_place_medal': '🥇',
    'second_place_medal': '🥈',
    'third_place_medal': '🥉',
    'rocket': '🚀',
    'airplane': '✈️',
    'bullseye': '🎯',
    'dart': '🎯',
    'checkered_flag': '🏁',
    'white_check_mark': '✅',
    'check': '✔️',
    'heavy_check_mark': '✔️',
    'x': '❌',
    'cross_mark': '❌',
    'warning': '⚠️',
    'question': '❓',
    'grey_question': '❔',
    'exclamation': '❗',
    'grey_exclamation': '❕',
    'bulb': '💡',
    'light_bulb': '💡',
    'speech_balloon': '💬',
    'thought_balloon': '💭',
    'eye': '👁️',
    'eyes': '👀',
    'brain': '🧠',
    'gear': '⚙️',
    'wrench': '🔧',
    'hammer': '🔨',
    'hammer_and_wrench': '🛠️',
    'tools': '🛠️',
    'lock': '🔒',
    'unlock': '🔓',
    'key': '🔑',
    'bell': '🔔',
    'no_bell': '🔕',
    'bookmark': '🔖',
    'link': '🔗',
    'paperclip': '📎',
    'pushpin': '📌',
    'round_pushpin': '📍',
    'scissors': '✂️',
    'pen': '🖊️',
    'pencil2': '✏️',
    'memo': '📝',
    'page_facing_up': '📄',
    'page_with_curl': '📃',
    'bookmark_tabs': '📑',
    'file_folder': '📁',
    'open_file_folder': '📂',
    'card_index_dividers': '🗂️',
    'date': '📅',
    'calendar': '📆',
    'card_index': '📇',
    'chart_with_upwards_trend': '📈',
    'chart_with_downwards_trend': '📉',
    'bar_chart': '📊',
    'clipboard': '📋',
    'inbox_tray': '📥',
    'outbox_tray': '📤',
    'package': '📦',
    'mailbox': '📫',
    'mailbox_closed': '📪',
    'mailbox_with_mail': '📬',
    'mailbox_with_no_mail': '📭',
    'email': '📧',
    'e-mail': '📧',
    
    // Nature
    'sun': '☀️',
    'sunny': '☀️',
    'moon': '🌙',
    'star2': '🌟',
    'cloud': '☁️',
    'partly_sunny': '⛅',
    'rainbow': '🌈',
    'snowflake': '❄️',
    'snowman': '⛄',
    'umbrella': '☂️',
    'ocean': '🌊',
    'seedling': '🌱',
    'evergreen_tree': '🌲',
    'deciduous_tree': '🌳',
    'palm_tree': '🌴',
    'cactus': '🌵',
    'four_leaf_clover': '🍀',
    'rose': '🌹',
    'sunflower': '🌻',
    'cherry_blossom': '🌸',
    
    // Animals
    'dog': '🐕',
    'cat': '🐈',
    'mouse': '🐁',
    'rabbit': '🐇',
    'fox_face': '🦊',
    'bear': '🐻',
    'panda_face': '🐼',
    'koala': '🐨',
    'tiger': '🐯',
    'lion_face': '🦁',
    'cow': '🐄',
    'pig': '🐷',
    'frog': '🐸',
    'monkey_face': '🐵',
    'see_no_evil': '🙈',
    'hear_no_evil': '🙉',
    'speak_no_evil': '🙊',
    'chicken': '🐔',
    'penguin': '🐧',
    'bird': '🐦',
    'eagle': '🦅',
    'duck': '🦆',
    'owl': '🦉',
    'bat': '🦇',
    'shark': '🦈',
    'dolphin': '🐬',
    'whale': '🐳',
    'octopus': '🐙',
    'snail': '🐌',
    'butterfly': '🦋',
    'bug': '🐛',
    'ant': '🐜',
    'bee': '🐝',
    'honeybee': '🐝',
    'lady_beetle': '🐞',
    'spider': '🕷️',
    'spider_web': '🕸️',
    'turtle': '🐢',
    'snake': '🐍',
    'lizard': '🦎',
    'scorpion': '🦂',
    'crab': '🦀',
    'squid': '🦑',
    'shrimp': '🦐',
    
    // Food
    'apple': '🍎',
    'green_apple': '🍏',
    'pear': '🍐',
    'tangerine': '🍊',
    'lemon': '🍋',
    'banana': '🍌',
    'watermelon': '🍉',
    'grapes': '🍇',
    'strawberry': '🍓',
    'peach': '🍑',
    'cherries': '🍒',
    'mango': '🥭',
    'pineapple': '🍍',
    'coconut': '🥥',
    'avocado': '🥑',
    'eggplant': '🍆',
    'potato': '🥔',
    'carrot': '🥕',
    'corn': '🌽',
    'hot_pepper': '🌶️',
    'cucumber': '🥒',
    'broccoli': '🥦',
    'mushroom': '🍄',
    'pizza': '🍕',
    'hamburger': '🍔',
    'fries': '🍟',
    'hotdog': '🌭',
    'sandwich': '🥪',
    'taco': '🌮',
    'burrito': '🌯',
    'sushi': '🍣',
    'ramen': '🍜',
    'spaghetti': '🍝',
    'curry': '🍛',
    'cake': '🍰',
    'birthday': '🎂',
    'cookie': '🍪',
    'chocolate_bar': '🍫',
    'candy': '🍬',
    'lollipop': '🍭',
    'doughnut': '🍩',
    'ice_cream': '🍨',
    'icecream': '🍦',
    'coffee': '☕',
    'tea': '🍵',
    'beer': '🍺',
    'beers': '🍻',
    'wine_glass': '🍷',
    'cocktail': '🍸',
    'tropical_drink': '🍹',
    'champagne': '🍾',
  }
  
  return emojiMap[name.toLowerCase()] || null
}
</script>

<template>
  <span class="emoji-text">
    <template v-for="(part, index) in parsedParts" :key="index">
      <span v-if="part.type === 'text'" class="whitespace-pre-wrap">{{ part.content }}</span>
      <img 
        v-else-if="part.url" 
        :src="part.url" 
        :alt="`:${part.content}:`"
        :title="`:${part.content}:`"
        class="inline-block h-[1.2em] w-[1.2em] align-text-bottom mx-0.5"
      />
      <span v-else class="emoji">{{ part.content }}</span>
    </template>
  </span>
</template>

<style scoped>
.emoji-text {
  word-break: break-word;
}
.emoji {
  font-family: "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji", sans-serif;
}
</style>
