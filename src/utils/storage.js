//unicorn room images
import sparkleRoomBg from "../components/assets/sparkleRoom.png";
import rainbowRoom from "../components/assets/rainbowRoom.png";
import starRoom from "../components/assets/starRoom.png";
import cloudRoom from "../components/assets/cloudRoom.png";
import dreamRoom from "../components/assets/dreamRoom.png";
import mysticRoom from "../components/assets/mysticRoom.png";

//unicorn images
import sparkleImg from "../components/assets/sparkle.png";
import rainbowImg from "../components/assets/rainbow.png";
import starImg from "../components/assets/star.png";
import cloudImg from "../components/assets/cloud.png";
import dreamImg from "../components/assets/dreamer.png";
import mysticImg from "../components/assets/mystic.png";

const DB_KEY = "unicorn_arcade_v1";

export const UNICORNS = [
  {
    id: "sparkle",
    name: "Sparkle",
    price: 0,
    desc: "The classic pink companion.",
    style: "bg-pink-950",
    bgImage: sparkleRoomBg,
    image: sparkleImg,
    accent: "text-pink-400",
  },
  {
    id: "rainbow",
    name: "Rainbow",
    price: 500,
    desc: "Leaves a trail of colors.",
    style: "bg-slate-900",
    image: rainbowImg,
    bgImage: rainbowRoom,
    accent: "text-cyan-400",
  },
  {
    id: "star",
    name: "Star",
    price: 1200,
    desc: "Shines brighter than the sun.",
    style: "bg-indigo-950",
    image: starImg,
    bgImage: starRoom,
    accent: "text-yellow-400",
  },
  {
    id: "cloud",
    name: "Cloud",
    price: 2500,
    desc: "Float above the competition.",
    style: "bg-sky-950",
    image: cloudImg,
    bgImage: cloudRoom,
    accent: "text-sky-300",
  },
  {
    id: "dream",
    name: "Dreamer",
    price: 5000,
    desc: "Straight out of a fantasy.",
    style: "bg-purple-950",
    image: dreamImg,
    bgImage: dreamRoom,
    accent: "text-purple-400",
  },
  {
    id: "mystic",
    name: "Mystic",
    price: 10000,
    desc: "Pure magical energy.",
    style: "bg-emerald-950",
    image: mysticImg,
    bgImage: mysticRoom,
    accent: "text-emerald-400",
    scale: 1.6,
  },
];

export { FURNITURE } from "../data/furnitureCatalog";

export const getDB = () => {
  const stored = localStorage.getItem(DB_KEY);
  if (!stored) return { users: {}, lastUser: "" };
  return JSON.parse(stored);
};

export const saveDB = (db) => {
  localStorage.setItem(DB_KEY, JSON.stringify(db));
};

// export const getBestTimes = (timesArray) => {
//   const bests = {};
//   if (!timesArray) return bests;
//   timesArray.forEach((entry) => {
//     if (!bests[entry.level] || entry.time < bests[entry.level]) {
//       bests[entry.level] = entry.time;
//     }
//   });
//   return bests;
// };
