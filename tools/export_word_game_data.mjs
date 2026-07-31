import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import {
  FALLING_WORDS,
  SENTENCE_BUILD,
  MISSING_WORD,
  PREFIX_MIX,
  VOWEL_WORDS,
  SYLLABLE_WORDS,
  CAPTION_SCENES,
} from "../src/games/wordGames/shared/wordLists.js";
import {
  OPPOSITE_CHALLENGES,
  SCRAMBLE_PUZZLES,
  ODD_ONE_OUT,
  SIZE_LINEUPS,
  CHAIN_LINKS,
} from "../src/games/wordGames/wordMysteries/lists.js";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const output = resolve(root, "godot/data/word_games.json");
const payload = {
  source: "React wordLists.js and wordMysteries/lists.js",
  falling_words: FALLING_WORDS,
  sentence_build: SENTENCE_BUILD,
  missing_word: MISSING_WORD,
  prefix_mix: PREFIX_MIX,
  vowel_words: VOWEL_WORDS,
  syllable_words: SYLLABLE_WORDS,
  caption_scenes: CAPTION_SCENES,
  opposite_challenges: OPPOSITE_CHALLENGES,
  scramble_puzzles: SCRAMBLE_PUZZLES,
  odd_one_out: ODD_ONE_OUT,
  size_lineups: SIZE_LINEUPS,
  chain_links: CHAIN_LINKS,
};

mkdirSync(dirname(output), { recursive: true });
writeFileSync(output, `${JSON.stringify(payload, null, 2)}\n`, "utf8");
console.log(`Wrote ${output}`);
