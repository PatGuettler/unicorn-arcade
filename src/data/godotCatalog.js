/**
 * Plain JSON-serializable catalog for Godot export (no React / asset imports).
 * Keep in sync with gameConfig.js and storage.js UNICORNS.
 */

export const CATEGORIES = [
  { id: "number", title: "Number Games", color: "#06b6d4", desc: "Logic & Arithmetic" },
  { id: "word", title: "Word Games", color: "#a855f7", desc: "Vocab, spelling & rhymes" },
  {
    id: "wordMysteries",
    title: "Word Mysteries",
    color: "#6366f1",
    desc: "Detective word puzzles",
  },
  { id: "future", title: "Future", color: "#10b981", desc: "Experimental" },
];

export const GAMES = {
  number: [
    { id: "unicorn", title: "Unicorn Jump", icon: "🦄", desc: "Exact Jump Pathfinding", parity_ok: false },
    { id: "sliding", title: "Sliding Window", icon: "🪟", desc: "Array Logic Puzzle", parity_ok: false },
    { id: "coin", title: "Coin Count", icon: "🪙", desc: "Cents & Change", parity_ok: true },
    { id: "cash", title: "Cash Counter", icon: "💵", desc: "High Value Math", parity_ok: false },
    { id: "mathSwipe", title: "Math Swipe", icon: "🎯", desc: "Swipe the Right Answer", parity_ok: false },
    { id: "mathtris", title: "Mathtris", icon: "🔢", desc: "Tetris-style math equations", parity_ok: false },
  ],
  word: [
    { id: "unicornBlast", title: "Unicorn Blast", icon: "🎯", desc: "Type words — cannon fires your unicorn!", parity_ok: false },
    { id: "rhymeRally", title: "Rhyme Rally", icon: "🎵", desc: "Hop with rhymes", parity_ok: false },
    { id: "sentenceSprout", title: "Sentence Sprout", icon: "🌱", desc: "Grow sentences word by word", parity_ok: false },
    { id: "missingMagic", title: "Missing Magic", icon: "✨", desc: "Fill the story blank", parity_ok: false },
    { id: "sightSpark", title: "Sight Spark", icon: "⚡", desc: "Flash words — type from memory", parity_ok: false },
    { id: "prefixPotion", title: "Prefix Potion", icon: "🧪", desc: "Brew prefix + root words", parity_ok: false },
    { id: "vowelVines", title: "Vowel Vines", icon: "🌿", desc: "Climb the right vowel vines", parity_ok: false },
    { id: "letterLift", title: "Letter Lift", icon: "🪜", desc: "Type letters — unicorn climbs", parity_ok: false },
    { id: "syllableStamp", title: "Syllable Stamp", icon: "🦄", desc: "Stamp syllables in order", parity_ok: false },
    { id: "captionQuest", title: "Caption Quest", icon: "📸", desc: "Caption emoji scenes", parity_ok: false },
  ],
  wordMysteries: [
    { id: "oppositeOrbit", title: "Opposite Orbit", icon: "🌓", desc: "Spin to the word that means the opposite", parity_ok: false },
    { id: "scrambleSpell", title: "Scramble Spell", icon: "🔤", desc: "Tap scrambled letters in the right order", parity_ok: false },
    { id: "oddOneOut", title: "Odd One Out", icon: "🕵️", desc: "Find the item that does not belong", parity_ok: false },
    { id: "sizeLineUp", title: "Size Line-Up", icon: "📏", desc: "Tap words shortest → longest", parity_ok: false },
    { id: "chainLink", title: "Chain Link", icon: "🔗", desc: "Pick the word that continues the letter chain", parity_ok: false },
  ],
  future: [
    { id: "spaceUnicorn", title: "Galaxy Unicorn", icon: "🚀", desc: "Fly & blast — Galaxy Attack style space shooter", parity_ok: false },
  ],
};

export const UNICORNS = [
  { id: "sparkle", name: "Sparkle", price: 0, desc: "The classic pink companion.", accent: "#f472b6", room_theme: "sparkle" },
  { id: "rainbow", name: "Rainbow", price: 500, desc: "Leaves a trail of colors.", accent: "#22d3ee", room_theme: "rainbow" },
  { id: "star", name: "Star", price: 1200, desc: "Shines brighter than the sun.", accent: "#facc15", room_theme: "star" },
  { id: "cloud", name: "Cloud", price: 2500, desc: "Float above the competition.", accent: "#7dd3fc", room_theme: "cloud" },
  { id: "dream", name: "Dreamer", price: 5000, desc: "Straight out of a fantasy.", accent: "#c084fc", room_theme: "dream" },
  { id: "mystic", name: "Mystic", price: 10000, desc: "Pure magical energy.", accent: "#34d399", room_theme: "mystic", scale: 1.6 },
];

export const WORD_GAME_IDS = [
  "unicornBlast",
  "rhymeRally",
  "sentenceSprout",
  "missingMagic",
  "sightSpark",
  "prefixPotion",
  "vowelVines",
  "letterLift",
  "syllableStamp",
  "captionQuest",
  "oppositeOrbit",
  "scrambleSpell",
  "oddOneOut",
  "sizeLineUp",
  "chainLink",
];

export const NUMBER_GAME_IDS = ["unicorn", "sliding", "coin", "cash", "mathSwipe", "mathtris"];

export const ALL_GAME_IDS = [
  ...NUMBER_GAME_IDS,
  ...WORD_GAME_IDS,
  "spaceUnicorn",
];
