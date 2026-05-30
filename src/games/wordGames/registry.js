import UnicornBlastGame from "./unicornBlast";
import RhymeRallyGame from "./rhymeRally";
import SentenceSproutGame from "./sentenceSprout";
import MissingMagicGame from "./missingMagic";
import SightSparkGame from "./sightSpark";
import PrefixPotionGame from "./prefixPotion";
import VowelVinesGame from "./vowelVines";
import LetterLiftGame from "./letterLift";
import SyllableStampGame from "./syllableStamp";
import CaptionQuestGame from "./captionQuest";
import OppositeOrbitGame from "./oppositeOrbit";
import ScrambleSpellGame from "./scrambleSpell";
import OddOneOutGame from "./oddOneOut";
import SizeLineUpGame from "./sizeLineUp";
import ChainLinkGame from "./chainLink";

export const WORD_GAMES = {
  unicornBlast: UnicornBlastGame,
  rhymeRally: RhymeRallyGame,
  sentenceSprout: SentenceSproutGame,
  missingMagic: MissingMagicGame,
  sightSpark: SightSparkGame,
  prefixPotion: PrefixPotionGame,
  vowelVines: VowelVinesGame,
  letterLift: LetterLiftGame,
  syllableStamp: SyllableStampGame,
  captionQuest: CaptionQuestGame,
  oppositeOrbit: OppositeOrbitGame,
  scrambleSpell: ScrambleSpellGame,
  oddOneOut: OddOneOutGame,
  sizeLineUp: SizeLineUpGame,
  chainLink: ChainLinkGame,
};

export const WORD_GAME_IDS = Object.keys(WORD_GAMES);

export const WORD_GAME_TITLES = {
  unicornBlast: "Unicorn Blast",
  rhymeRally: "Rhyme Rally",
  sentenceSprout: "Sentence Sprout",
  missingMagic: "Missing Magic",
  sightSpark: "Sight Spark",
  prefixPotion: "Prefix Potion",
  vowelVines: "Vowel Vines",
  letterLift: "Letter Lift",
  syllableStamp: "Syllable Stamp",
  captionQuest: "Caption Quest",
  oppositeOrbit: "Opposite Orbit",
  scrambleSpell: "Scramble Spell",
  oddOneOut: "Odd One Out",
  sizeLineUp: "Size Line-Up",
  chainLink: "Chain Link",
};

export const MYSTERY_GAME_IDS = [
  "oppositeOrbit",
  "scrambleSpell",
  "oddOneOut",
  "sizeLineUp",
  "chainLink",
];

export const CLASSIC_WORD_GAME_IDS = WORD_GAME_IDS.filter(
  (id) => !MYSTERY_GAME_IDS.includes(id)
);

export function isWordGameId(id) {
  return id in WORD_GAMES;
}

export function isMysteryGameId(id) {
  return MYSTERY_GAME_IDS.includes(id);
}
