export function pickForLevel(arr, level) {
  return arr[(level - 1) % arr.length];
}

export function shuffle(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

export const OPPOSITE_CHALLENGES = [
  { word: "hot", answer: "cold", options: ["cold", "wet", "big", "fast"] },
  { word: "day", answer: "night", options: ["night", "sun", "fun", "red"] },
  { word: "up", answer: "down", options: ["down", "in", "on", "at"] },
  { word: "happy", answer: "sad", options: ["sad", "glad", "mad", "bad"] },
  { word: "big", answer: "small", options: ["small", "tall", "long", "wide"] },
  { word: "fast", answer: "slow", options: ["slow", "quick", "rush", "zip"] },
  { word: "open", answer: "close", options: ["close", "shut", "lock", "snap"] },
  { word: "light", answer: "dark", options: ["dark", "dim", "gray", "pale"] },
  { word: "young", answer: "old", options: ["old", "new", "bold", "gold"] },
  { word: "loud", answer: "quiet", options: ["quiet", "soft", "calm", "still"] },
];

export const SCRAMBLE_PUZZLES = [
  { hint: "🐱 Furry pet that says meow", word: "cat", emoji: "🐱" },
  { hint: "☀️ Bright sky in the day", word: "sun", emoji: "☀️" },
  { hint: "🌈 Colors after rain", word: "rainbow", emoji: "🌈" },
  { hint: "📚 You do this with pages", word: "read", emoji: "📚" },
  { hint: "🦄 Magic horn horse", word: "unicorn", emoji: "🦄" },
  { hint: "🌙 Time when stars shine", word: "night", emoji: "🌙" },
  { hint: "🌸 Pretty plant smell", word: "flower", emoji: "🌸" },
  { hint: "🎵 Move to beats", word: "dance", emoji: "🎵" },
];

export const ODD_ONE_OUT = [
  {
    theme: "All are animals except one",
    items: [
      { label: "dog", emoji: "🐕" },
      { label: "cat", emoji: "🐈" },
      { label: "fish", emoji: "🐠" },
      { label: "car", emoji: "🚗" },
    ],
    odd: "car",
  },
  {
    theme: "All are fruits except one",
    items: [
      { label: "apple", emoji: "🍎" },
      { label: "banana", emoji: "🍌" },
      { label: "grape", emoji: "🍇" },
      { label: "chair", emoji: "🪑" },
    ],
    odd: "chair",
  },
  {
    theme: "All are colors except one",
    items: [
      { label: "red", emoji: "🔴" },
      { label: "blue", emoji: "🔵" },
      { label: "green", emoji: "🟢" },
      { label: "jump", emoji: "🦘" },
    ],
    odd: "jump",
  },
  {
    theme: "All are weather except one",
    items: [
      { label: "rain", emoji: "🌧️" },
      { label: "snow", emoji: "❄️" },
      { label: "wind", emoji: "💨" },
      { label: "pizza", emoji: "🍕" },
    ],
    odd: "pizza",
  },
  {
    theme: "All are school things except one",
    items: [
      { label: "book", emoji: "📖" },
      { label: "pencil", emoji: "✏️" },
      { label: "desk", emoji: "🪑" },
      { label: "moon", emoji: "🌙" },
    ],
    odd: "moon",
  },
];

export const SIZE_LINEUPS = [
  { words: ["I", "cat", "rainbow"], order: ["I", "cat", "rainbow"] },
  { words: ["go", "happy", "butterfly"], order: ["go", "happy", "butterfly"] },
  { words: ["at", "sun", "adventure"], order: ["at", "sun", "adventure"] },
  { words: ["a", "dog", "beautiful"], order: ["a", "dog", "beautiful"] },
  { words: ["we", "star", "together"], order: ["we", "star", "together"] },
  { words: ["it", "plant", "chocolate"], order: ["it", "plant", "chocolate"] },
];

export const CHAIN_LINKS = [
  { start: "cat", answer: "top", options: ["top", "dog", "sun", "red"] },
  { start: "sun", answer: "nut", options: ["nut", "nap", "cat", "big"] },
  { start: "dog", answer: "go", options: ["go", "dig", "run", "log"] },
  { start: "rain", answer: "night", options: ["night", "bow", "drop", "coat"] },
  { start: "star", answer: "run", options: ["run", "sky", "red", "art"] },
  { start: "fish", answer: "hop", options: ["hop", "fin", "sea", "net"] },
  { start: "book", answer: "kind", options: ["kind", "read", "page", "shelf"] },
  { start: "tree", answer: "eat", options: ["eat", "leaf", "oak", "bird"] },
];
