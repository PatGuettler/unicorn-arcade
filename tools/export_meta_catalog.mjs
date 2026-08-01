import { writeFile } from "node:fs/promises";
import { resolve } from "node:path";
import { FURNITURE, FURNITURE_CATEGORIES } from "../src/data/furnitureCatalog.js";

const companions = [
  { id: "sparkle", name: "Sparkle", price: 0, desc: "The classic pink companion.", color: "f26fa7" },
  { id: "rainbow", name: "Rainbow", price: 500, desc: "Leaves a trail of colors.", color: "58d6e8" },
  { id: "star", name: "Star", price: 1200, desc: "Shines brighter than the sun.", color: "ffd166" },
  { id: "cloud", name: "Cloud", price: 2500, desc: "Float above the competition.", color: "8dcde8" },
  { id: "dream", name: "Dreamer", price: 5000, desc: "Straight out of a fantasy.", color: "b18cff" },
  { id: "mystic", name: "Mystic", price: 10000, desc: "Pure magical energy.", color: "62e6a7" },
];

const payload = {
  companions,
  categories: FURNITURE_CATEGORIES.map(({ id, label, icon }) => ({ id, label, icon })),
  furniture: FURNITURE.map(({ id, name, price, icon, category, rarity, desc }) => ({
    id,
    name,
    price,
    icon,
    category,
    rarity,
    desc,
  })),
};

const destination = resolve("godot/data/meta_catalog.json");
await writeFile(destination, `${JSON.stringify(payload, null, 2)}\n`, "utf8");
console.log(`Wrote ${payload.furniture.length} decor items to ${destination}`);
