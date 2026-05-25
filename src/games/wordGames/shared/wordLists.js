/** Shared vocabulary & prompts for word games (ages 6–8) */

export const FALLING_WORDS = {
  easy: ["cat", "dog", "sun", "run", "hop", "big", "red", "sit", "cup", "map"],
  medium: [
    "cloud", "happy", "music", "spark", "light", "dream", "shine", "magic",
    "story", "plant", "friend", "smile", "water", "green", "sweet",
  ],
  hard: [
    "rainbow", "unicorn", "sparkle", "wonder", "garden", "castle", "adventure",
    "beautiful", "together", "morning", "butterfly", "chocolate",
  ],
};

export function wordsForLevel(level) {
  if (level <= 4) return FALLING_WORDS.easy;
  if (level <= 10) return FALLING_WORDS.medium;
  return FALLING_WORDS.hard;
}

export const RHYME_CHALLENGES = [
  { prompt: "cat", answer: "hat", options: ["hat", "dog", "cup", "pen"] },
  { prompt: "sun", answer: "fun", options: ["fun", "cat", "bed", "log"] },
  { prompt: "hop", answer: "top", options: ["top", "red", "sit", "map"] },
  { prompt: "light", answer: "night", options: ["night", "cloud", "tree", "fish"] },
  { prompt: "star", answer: "car", options: ["car", "moon", "blue", "rain"] },
  { prompt: "ring", answer: "sing", options: ["sing", "gold", "wing", "king"] },
  { prompt: "bee", answer: "tree", options: ["tree", "sky", "ant", "owl"] },
  { prompt: "boat", answer: "coat", options: ["coat", "ship", "lake", "sand"] },
];

export const SENTENCE_BUILD = [
  { words: ["The", "unicorn", "loves", "rainbows"], hint: "The unicorn loves rainbows" },
  { words: ["I", "can", "read", "books"], hint: "I can read books" },
  { words: ["We", "play", "in", "sun"], hint: "We play in sun" },
  { words: ["My", "friend", "is", "kind"], hint: "My friend is kind" },
  { words: ["She", "has", "a", "red", "hat"], hint: "She has a red hat" },
];

export const MISSING_WORD = [
  { text: ["The", null, "runs fast."], answer: "dog", options: ["dog", "blue", "happy"] },
  { text: ["I see a", null, "in the sky."], answer: "star", options: ["star", "chair", "jump"] },
  { text: ["We", null, "to school."], answer: "walk", options: ["walk", "apple", "cloud"] },
  { text: ["The", null, "is pink."], answer: "flower", options: ["flower", "run", "five"] },
  { text: ["My", null, "reads stories."], answer: "mom", options: ["mom", "fast", "green"] },
];

export const PREFIX_MIX = [
  { prefix: "un", root: "happy", answer: "unhappy", wrong: ["rehappy", "happyun"] },
  { prefix: "re", root: "play", answer: "replay", wrong: ["playre", "unplay"] },
  { prefix: "pre", root: "view", answer: "preview", wrong: ["viewpre", "review"] },
  { prefix: "dis", root: "like", answer: "dislike", wrong: ["likeun", "mislike"] },
  { prefix: "mis", root: "spell", answer: "misspell", wrong: ["spellre", "unspell"] },
];

/** Words that actually start with each vowel letter (matches Vowel Vines rules) */
export const VOWEL_WORDS = {
  a: ["ant", "and", "at", "am", "ask", "arm", "ash"],
  e: ["egg", "elf", "end", "eat", "eel", "ever"],
  i: ["it", "in", "is", "if", "ill", "ink", "into"],
  o: ["on", "ox", "off", "odd", "owl", "one", "open"],
  u: ["up", "us", "urn", "use", "upon", "under", "ugly"],
};

export const SYLLABLE_WORDS = [
  { word: "rain-bow", parts: ["rain", "bow"] },
  { word: "uni-corn", parts: ["uni", "corn"] },
  { word: "hap-py", parts: ["hap", "py"] },
  { word: "kit-ten", parts: ["kit", "ten"] },
  { word: "but-ter-fly", parts: ["but", "ter", "fly"] },
];

/** Tap-the-word captions (ages 6–8) — one clear answer per scene */
export const CAPTION_SCENES = [
  {
    emoji: "🦄🌈",
    prompt: "What is the colorful arc?",
    answer: "rainbow",
    options: ["rainbow", "pizza", "chair", "truck"],
  },
  {
    emoji: "📚😊",
    prompt: "What do you do with a book?",
    answer: "read",
    options: ["read", "sleep", "drive", "cook"],
  },
  {
    emoji: "🌸🐝",
    prompt: "What grows in the garden?",
    answer: "flower",
    options: ["flower", "rocket", "pencil", "hammer"],
  },
  {
    emoji: "🌙⭐",
    prompt: "When the moon is out, it is...",
    answer: "night",
    options: ["night", "lunch", "morning", "noon"],
  },
  {
    emoji: "🎵💃",
    prompt: "Move your body to music!",
    answer: "dance",
    options: ["dance", "sit", "nap", "hide"],
  },
  {
    emoji: "☀️🌻",
    prompt: "Bright sky in the day — the...",
    answer: "sun",
    options: ["sun", "moon", "rain", "snow"],
  },
  {
    emoji: "🐱😺",
    prompt: "Soft pet that says meow",
    answer: "cat",
    options: ["cat", "car", "cup", "cap"],
  },
  {
    emoji: "🦄💕",
    prompt: "How does your unicorn feel?",
    answer: "happy",
    options: ["happy", "angry", "table", "brick"],
  },
];

export function pickForLevel(arr, level) {
  const idx = (level - 1) % arr.length;
  return arr[idx];
}

export function shuffle(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}
