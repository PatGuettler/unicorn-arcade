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
    // {
    //   id: "spaceUnicorn",
    //   title: "Space Unicorn",
    //   icon: "✨",
    //   desc: "Type to Cast Magic",
    // },
  ],
  future: [],
};
