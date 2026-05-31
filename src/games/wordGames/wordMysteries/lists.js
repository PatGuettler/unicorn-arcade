/**
 * Word Mysteries vocabulary. Every list is ordered EASY -> HARD; `pickForLevel`
 * slides the selection window deeper as the level grows, while still picking
 * randomly inside the window for variety. All lists are static constants so
 * there is no runtime build cost.
 */

export function pickForLevel(arr, seed) {
  const len = arr.length;
  if (len === 0) return undefined;
  const s = Math.max(1, seed || 1);
  const ceil = Math.min(len, Math.max(4, Math.round(s * 1.5)));
  const floor = Math.max(0, ceil - Math.max(5, Math.round(ceil * 0.6)));
  const span = Math.max(1, ceil - floor);
  const idx = Math.min(len - 1, floor + Math.floor(Math.random() * span));
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

/** Opposite Orbit — one true opposite per row; distractors are never opposites. */
export const OPPOSITE_CHALLENGES = [
  { word: "hot", answer: "cold", options: ["cold", "wet", "big", "fast"] },
  { word: "up", answer: "down", options: ["down", "in", "on", "at"] },
  { word: "yes", answer: "no", options: ["no", "go", "so", "me"] },
  { word: "big", answer: "small", options: ["small", "tall", "long", "wide"] },
  { word: "day", answer: "night", options: ["night", "sun", "fun", "red"] },
  { word: "in", answer: "out", options: ["out", "up", "at", "on"] },
  { word: "fast", answer: "slow", options: ["slow", "quick", "rush", "zip"] },
  { word: "happy", answer: "sad", options: ["sad", "glad", "mad", "fun"] },
  { word: "wet", answer: "dry", options: ["dry", "hot", "cool", "warm"] },
  { word: "old", answer: "new", options: ["new", "gold", "bold", "cold"] },
  { word: "open", answer: "close", options: ["close", "jump", "read", "sing"] },
  { word: "light", answer: "dark", options: ["dark", "loud", "soft", "warm"] },
  { word: "loud", answer: "quiet", options: ["quiet", "big", "fast", "tall"] },
  { word: "full", answer: "empty", options: ["empty", "heavy", "round", "short"] },
  { word: "push", answer: "pull", options: ["pull", "lift", "drop", "hold"] },
  { word: "start", answer: "stop", options: ["stop", "walk", "jump", "skip"] },
  { word: "first", answer: "last", options: ["last", "next", "best", "most"] },
  { word: "above", answer: "below", options: ["below", "beside", "inside", "around"] },
  { word: "brave", answer: "scared", options: ["scared", "strong", "clever", "quiet"] },
  { word: "giant", answer: "tiny", options: ["tiny", "heavy", "shiny", "funny"] },
  { word: "ancient", answer: "modern", options: ["modern", "wooden", "golden", "hidden"] },
  { word: "generous", answer: "selfish", options: ["selfish", "joyful", "playful", "careful"] },
];

/** Scramble Spell — ordered by word length (easy -> hard). */
export const SCRAMBLE_PUZZLES = [
  { hint: "🐱 Furry pet that says meow", word: "cat", emoji: "🐱" },
  { hint: "☀️ Bright sky in the day", word: "sun", emoji: "☀️" },
  { hint: "🐶 Pet that says woof", word: "dog", emoji: "🐶" },
  { hint: "🐛 Tiny crawly creature", word: "bug", emoji: "🐛" },
  { hint: "🎩 You wear it on your head", word: "hat", emoji: "🎩" },
  { hint: "📚 You do this with pages", word: "read", emoji: "📚" },
  { hint: "⭐ It twinkles at night", word: "star", emoji: "⭐" },
  { hint: "🌙 Glows in the night sky", word: "moon", emoji: "🌙" },
  { hint: "🐸 Green hopping animal", word: "frog", emoji: "🐸" },
  { hint: "🐠 It swims in water", word: "fish", emoji: "🐠" },
  { hint: "🎂 Sweet birthday treat", word: "cake", emoji: "🎂" },
  { hint: "🎵 Move to the beats", word: "dance", emoji: "🎵" },
  { hint: "🌱 It grows in soil", word: "plant", emoji: "🌱" },
  { hint: "🌃 Time when stars shine", word: "night", emoji: "🌃" },
  { hint: "😊 A friendly face", word: "smile", emoji: "😊" },
  { hint: "🌸 Pretty plant that smells nice", word: "flower", emoji: "🌸" },
  { hint: "🏡 A place to grow plants", word: "garden", emoji: "🏡" },
  { hint: "🏰 Where a king lives", word: "castle", emoji: "🏰" },
  { hint: "🚀 It flies into space", word: "rocket", emoji: "🚀" },
  { hint: "🐉 A magic fire creature", word: "dragon", emoji: "🐉" },
  { hint: "🌈 Colors after the rain", word: "rainbow", emoji: "🌈" },
  { hint: "🦄 Magic horn horse", word: "unicorn", emoji: "🦄" },
  { hint: "🐬 Smart jumping sea animal", word: "dolphin", emoji: "🐬" },
  { hint: "🐧 Bird in a tuxedo", word: "penguin", emoji: "🐧" },
  { hint: "🎃 Orange fall vegetable", word: "pumpkin", emoji: "🎃" },
  { hint: "🦋 Insect with big wings", word: "butterfly", emoji: "🦋" },
  { hint: "🍫 Sweet brown treat", word: "chocolate", emoji: "🍫" },
];

/** Odd One Out — ordered easy -> hard. */
export const ODD_ONE_OUT = [
  {
    theme: "All are animals except one",
    items: [
      { label: "dog", emoji: "🐕" }, { label: "cat", emoji: "🐈" },
      { label: "fish", emoji: "🐠" }, { label: "car", emoji: "🚗" },
    ],
    odd: "car",
  },
  {
    theme: "All are fruits except one",
    items: [
      { label: "apple", emoji: "🍎" }, { label: "banana", emoji: "🍌" },
      { label: "grape", emoji: "🍇" }, { label: "chair", emoji: "🪑" },
    ],
    odd: "chair",
  },
  {
    theme: "All are colors except one",
    items: [
      { label: "red", emoji: "🔴" }, { label: "blue", emoji: "🔵" },
      { label: "green", emoji: "🟢" }, { label: "jump", emoji: "🦘" },
    ],
    odd: "jump",
  },
  {
    theme: "All are weather except one",
    items: [
      { label: "rain", emoji: "🌧️" }, { label: "snow", emoji: "❄️" },
      { label: "wind", emoji: "💨" }, { label: "pizza", emoji: "🍕" },
    ],
    odd: "pizza",
  },
  {
    theme: "All are school things except one",
    items: [
      { label: "book", emoji: "📖" }, { label: "pencil", emoji: "✏️" },
      { label: "desk", emoji: "🪑" }, { label: "moon", emoji: "🌙" },
    ],
    odd: "moon",
  },
  {
    theme: "All can fly except one",
    items: [
      { label: "bird", emoji: "🐦" }, { label: "plane", emoji: "✈️" },
      { label: "bee", emoji: "🐝" }, { label: "whale", emoji: "🐳" },
    ],
    odd: "whale",
  },
  {
    theme: "All live in the sea except one",
    items: [
      { label: "fish", emoji: "🐠" }, { label: "crab", emoji: "🦀" },
      { label: "shark", emoji: "🦈" }, { label: "lion", emoji: "🦁" },
    ],
    odd: "lion",
  },
  {
    theme: "All are things you eat except one",
    items: [
      { label: "bread", emoji: "🍞" }, { label: "cheese", emoji: "🧀" },
      { label: "apple", emoji: "🍎" }, { label: "shoe", emoji: "👟" },
    ],
    odd: "shoe",
  },
  {
    theme: "All are vehicles except one",
    items: [
      { label: "bus", emoji: "🚌" }, { label: "train", emoji: "🚆" },
      { label: "bike", emoji: "🚲" }, { label: "spoon", emoji: "🥄" },
    ],
    odd: "spoon",
  },
  {
    theme: "All are insects except one",
    items: [
      { label: "ant", emoji: "🐜" }, { label: "bee", emoji: "🐝" },
      { label: "moth", emoji: "🦋" }, { label: "frog", emoji: "🐸" },
    ],
    odd: "frog",
  },
  {
    theme: "All are musical things except one",
    items: [
      { label: "drum", emoji: "🥁" }, { label: "piano", emoji: "🎹" },
      { label: "guitar", emoji: "🎸" }, { label: "broom", emoji: "🧹" },
    ],
    odd: "broom",
  },
  {
    theme: "All grow on plants except one",
    items: [
      { label: "leaf", emoji: "🍃" }, { label: "petal", emoji: "🌸" },
      { label: "berry", emoji: "🫐" }, { label: "brick", emoji: "🧱" },
    ],
    odd: "brick",
  },
  {
    theme: "All are jobs people do except one",
    items: [
      { label: "doctor", emoji: "🩺" }, { label: "teacher", emoji: "🧑‍🏫" },
      { label: "pilot", emoji: "🧑‍✈️" }, { label: "puddle", emoji: "💧" },
    ],
    odd: "puddle",
  },
  {
    theme: "All belong in space except one",
    items: [
      { label: "planet", emoji: "🪐" }, { label: "comet", emoji: "☄️" },
      { label: "star", emoji: "⭐" }, { label: "carrot", emoji: "🥕" },
    ],
    odd: "carrot",
  },
];

/** Size Line-Up — words have DISTINCT lengths; order is shortest -> longest. */
export const SIZE_LINEUPS = [
  { words: ["I", "cat", "plant"], order: ["I", "cat", "plant"] },
  { words: ["a", "dog", "flower"], order: ["a", "dog", "flower"] },
  { words: ["at", "sun", "purple"], order: ["at", "sun", "purple"] },
  { words: ["we", "star", "unicorn"], order: ["we", "star", "unicorn"] },
  { words: ["go", "tree", "rainbow"], order: ["go", "tree", "rainbow"] },
  { words: ["it", "moon", "dolphin"], order: ["it", "moon", "dolphin"] },
  { words: ["my", "fish", "dragon"], order: ["my", "fish", "dragon"] },
  { words: ["up", "frog", "sparkle"], order: ["up", "frog", "sparkle"] },
  { words: ["he", "bird", "castle"], order: ["he", "bird", "castle"] },
  { words: ["ox", "lake", "pumpkin"], order: ["ox", "lake", "pumpkin"] },
  { words: ["I", "cat", "plant", "elephant"], order: ["I", "cat", "plant", "elephant"] },
  { words: ["go", "star", "garden", "butterfly"], order: ["go", "star", "garden", "butterfly"] },
  { words: ["at", "frog", "rocket", "chocolate"], order: ["at", "frog", "rocket", "chocolate"] },
  { words: ["we", "tree", "flower", "adventure"], order: ["we", "tree", "flower", "adventure"] },
  { words: ["up", "moon", "castle", "wonderful"], order: ["up", "moon", "castle", "wonderful"] },
  { words: ["my", "bird", "dragon", "watermelon"], order: ["my", "bird", "dragon", "watermelon"] },
];

/**
 * Chain Link — pick a word that starts with the LAST letter of `start`.
 * Any option starting with that letter is correct; distractors never do.
 * (No single seeded answer, so all valid links are accepted.)
 */
export const CHAIN_LINKS = [
  { start: "cat", options: ["top", "tag", "dog", "red"] },
  { start: "sun", options: ["nut", "nap", "cat", "big"] },
  { start: "dog", options: ["go", "gum", "red", "sit"] },
  { start: "pig", options: ["gas", "got", "ant", "mud"] },
  { start: "bed", options: ["dog", "dig", "sun", "hop"] },
  { start: "cup", options: ["pen", "pat", "fox", "run"] },
  { start: "ball", options: ["log", "leg", "cat", "sun"] },
  { start: "star", options: ["run", "rat", "dog", "ten"] },
  { start: "moon", options: ["net", "nap", "sun", "big"] },
  { start: "tree", options: ["egg", "eat", "dog", "run"] },
  { start: "frog", options: ["goat", "gold", "fish", "lake"] },
  { start: "snail", options: ["leaf", "lamp", "pond", "rock"] },
  { start: "cloud", options: ["dark", "drip", "wind", "sky"] },
  { start: "rocket", options: ["take", "tail", "moon", "star"] },
  { start: "dragon", options: ["nest", "night", "fire", "gold"] },
  { start: "castle", options: ["eagle", "earth", "king", "moat"] },
  { start: "planet", options: ["tiger", "track", "orbit", "space"] },
];
