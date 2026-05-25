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
};

export function isWordGameId(id) {
  return id in WORD_GAMES;
}
