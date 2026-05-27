import { Calculator, Type, Rocket } from "lucide-react";

export const CATEGORIES = [
  {
    id: "number",
    title: "Number Games",
    icon: Calculator,
    color: "bg-cyan-500",
    desc: "Logic & Arithmetic",
  },
  {
    id: "word",
    title: "Word Games",
    icon: Type,
    color: "bg-purple-500",
    desc: "Vocab & Spelling",
  },
  {
    id: "future",
    title: "Future",
    icon: Rocket,
    color: "bg-emerald-500",
    desc: "Experimental",
  },
];

export const GAMES = {
  number: [
    {
      id: "unicorn",
      title: "Unicorn Jump",
      icon: "🦄",
      desc: "Exact Jump Pathfinding",
    },
    {
      id: "sliding",
      title: "Sliding Window",
      icon: "🪟",
      desc: "Array Logic Puzzle",
    },
    { id: "coin", title: "Coin Count", icon: "🪙", desc: "Cents & Change" },
    {
      id: "cash",
      title: "Cash Counter",
      icon: "💵",
      desc: "High Value Math",
    },
    {
      id: "mathSwipe",
      title: "Math Swipe",
      icon: "🎯",
      desc: "Swipe the Right Answer",
    },
    {
      id: "mathtris",
      title: "Mathtris",
      icon: "🔢",
      desc: "Tetris-style math equations",
    },
  ],
  word: [
    {
      id: "unicornBlast",
      title: "Unicorn Blast",
      icon: "🎯",
      desc: "Type words — cannon fires your unicorn!",
    },
    {
      id: "rhymeRally",
      title: "Rhyme Rally",
      icon: "🎵",
      desc: "Hop with rhymes",
    },
    {
      id: "sentenceSprout",
      title: "Sentence Sprout",
      icon: "🌱",
      desc: "Grow sentences word by word",
    },
    {
      id: "missingMagic",
      title: "Missing Magic",
      icon: "✨",
      desc: "Fill the story blank",
    },
    {
      id: "sightSpark",
      title: "Sight Spark",
      icon: "⚡",
      desc: "Flash words — type from memory",
    },
    {
      id: "prefixPotion",
      title: "Prefix Potion",
      icon: "🧪",
      desc: "Brew prefix + root words",
    },
    {
      id: "vowelVines",
      title: "Vowel Vines",
      icon: "🌿",
      desc: "Climb the right vowel vines",
    },
    {
      id: "letterLift",
      title: "Letter Lift",
      icon: "🪜",
      desc: "Type letters — unicorn climbs",
    },
    {
      id: "syllableStamp",
      title: "Syllable Stamp",
      icon: "🦄",
      desc: "Stamp syllables in order",
    },
    {
      id: "captionQuest",
      title: "Caption Quest",
      icon: "📸",
      desc: "Caption emoji scenes",
    },
  ],
  future: [
    {
      id: "spaceUnicorn",
      title: "Space Unicorn",
      icon: "🚀",
      desc: "Type words to blast asteroids",
    },
  ],
};

/** Profile: games grouped by category (single source of truth) */
export function getProfileGameSections() {
  return CATEGORIES.map((category) => ({
    ...category,
    games: GAMES[category.id] || [],
  })).filter((section) => section.games.length > 0);
}

/** Best time per completed level from saved runs */
export function getGameLevelSummary(gameData) {
  if (!gameData) return { maxLevel: 0, levels: [] };

  const maxLevel = gameData.maxLevel || 0;
  const bestByLevel = new Map();

  (gameData.times || []).forEach(({ level, time }) => {
    if (level == null) return;
    const prev = bestByLevel.get(level);
    if (prev == null || time < prev) bestByLevel.set(level, time);
  });

  const levels = [...bestByLevel.entries()]
    .sort(([a], [b]) => a - b)
    .map(([level, time]) => ({ level, time }));

  return { maxLevel, levels };
}
