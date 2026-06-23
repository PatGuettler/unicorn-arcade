export const CATEGORIES = [
  { id: "number", title: "Number Games" },
  { id: "word", title: "Word Games" },
  { id: "wordMysteries", title: "Word Mysteries" },
  { id: "future", title: "Future" },
];

export const GAMES = {
  number: [
    { id: "unicorn", title: "Unicorn Jump" },
    { id: "sliding", title: "Sliding Window" },
    { id: "coin", title: "Coin Count" },
    { id: "cash", title: "Cash Counter" },
    { id: "mathSwipe", title: "Math Swipe" },
    { id: "mathtris", title: "Mathtris" },
  ],
  word: [
    { id: "unicornBlast", title: "Unicorn Blast" },
    { id: "rhymeRally", title: "Rhyme Rally" },
    { id: "sentenceSprout", title: "Sentence Sprout" },
    { id: "missingMagic", title: "Missing Magic" },
    { id: "sightSpark", title: "Sight Spark" },
    { id: "prefixPotion", title: "Prefix Potion" },
    { id: "vowelVines", title: "Vowel Vines" },
    { id: "letterLift", title: "Letter Lift" },
    { id: "syllableStamp", title: "Syllable Stamp" },
    { id: "captionQuest", title: "Caption Quest" },
  ],
  wordMysteries: [
    { id: "oppositeOrbit", title: "Opposite Orbit" },
    { id: "scrambleSpell", title: "Scramble Spell" },
    { id: "oddOneOut", title: "Odd One Out" },
    { id: "sizeLineUp", title: "Size Line-Up" },
    { id: "chainLink", title: "Chain Link" },
  ],
  future: [{ id: "spaceUnicorn", title: "Galaxy Unicorn" }],
};

export const WORD_GAME_IDS = [
  ...GAMES.word.map((g) => g.id),
  ...GAMES.wordMysteries.map((g) => g.id),
];
