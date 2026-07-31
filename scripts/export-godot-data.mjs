#!/usr/bin/env node
/**
 * Export React app data to godot/data/*.json for the Godot client.
 */
import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import {
  CATEGORIES,
  GAMES,
  UNICORNS,
  WORD_GAME_IDS,
  ALL_GAME_IDS,
} from "../src/data/godotCatalog.js";
import { FURNITURE, FURNITURE_CATEGORIES } from "../src/data/furnitureCatalog.js";
import * as wordLists from "../src/games/wordGames/shared/wordLists.js";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const outDir = join(root, "godot", "data");
mkdirSync(outDir, { recursive: true });

const catalog = {
  categories: CATEGORIES,
  games: GAMES,
  unicorns: UNICORNS,
  furniture: FURNITURE,
  furniture_categories: FURNITURE_CATEGORIES,
  word_game_ids: WORD_GAME_IDS,
  all_game_ids: ALL_GAME_IDS,
  economy: {
    hint_cost: 5,
    coin_formula_base: 10,
    coin_formula_per_level: 5,
    sell_back_ratio: 0.5,
    grid_snap_percent: 8,
  },
  save: {
    db_key: "unicorn_arcade_v1",
    default_owned_unicorns: ["sparkle"],
    default_equipped: "sparkle",
  },
};

writeFileSync(join(outDir, "catalog.json"), JSON.stringify(catalog, null, 2));

const wordExport = {};
for (const [key, value] of Object.entries(wordLists)) {
  if (typeof value === "function") continue;
  wordExport[key] = value;
}
writeFileSync(join(outDir, "word_lists.json"), JSON.stringify(wordExport, null, 2));

try {
  const mysteries = await import("../src/games/wordGames/wordMysteries/lists.js");
  const mysteryExport = {};
  for (const [key, value] of Object.entries(mysteries)) {
    if (typeof value === "function") continue;
    mysteryExport[key] = value;
  }
  writeFileSync(join(outDir, "word_mysteries.json"), JSON.stringify(mysteryExport, null, 2));
} catch (err) {
  console.warn("word_mysteries export skipped:", err.message);
}

console.log(`Wrote ${outDir}/catalog.json (${FURNITURE.length} furniture items)`);
console.log(`Wrote ${outDir}/word_lists.json`);
