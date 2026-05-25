import { useState, useEffect } from "react";
import { useGameSystem } from "../../../components/shared/useGameSystem";
import WordGameShell from "../shared/WordGameShell";
import { UnicornAvatar } from "../../../components/assets/gameAssets";
import { VOWEL_WORDS, shuffle } from "../shared/wordLists";
import { targetForLevel } from "../shared/useWordLevel";

const VOWELS = ["a", "e", "i", "o", "u"];

export default function VowelVinesGame({
  onExit,
  onHome,
  lastCompletedLevel = 0,
  onSaveProgress,
  calcCoins,
  coins,
  onSpendCoins,
  unicornImage,
}) {
  const {
    gameState,
    level,
    elapsedTime,
    showHint,
    startGame,
    registerMove,
    buyHint,
    completeLevel,
    failLevel,
    hintCost,
  } = useGameSystem({
    initialLevel: lastCompletedLevel || 1,
    onSaveProgress,
    onSpendCoins,
  });

  const [round, setRound] = useState(0);
  const [target, setTarget] = useState(5);
  const [vowel, setVowel] = useState("a");
  const [options, setOptions] = useState([]);

  const launch = (lvl) => {
    setRound(0);
    setTarget(targetForLevel(lvl));
    startGame(lvl);
    nextVine(lvl, 0);
  };

  const nextVine = (lvl, r) => {
    const v = VOWELS[(r + lvl) % VOWELS.length];
    setVowel(v);
    const good = VOWEL_WORDS[v].filter((w) => w[0] === v);
    const wrongPool = VOWELS.filter((x) => x !== v)
      .flatMap((k) => VOWEL_WORDS[k])
      .filter((w) => w[0] !== v);
    const correct = good[Math.floor(Math.random() * good.length)];
    const wrong = [];
    const pool = shuffle(wrongPool);
    for (const w of pool) {
      if (w !== correct && !wrong.includes(w) && wrong.length < 3) wrong.push(w);
    }
    setOptions(shuffle([correct, ...wrong]));
  };

  useEffect(() => { launch(lastCompletedLevel || 1); }, []);

  const isCorrectVine = (word) => word[0]?.toLowerCase() === vowel;

  const climb = (word) => {
    if (gameState !== "playing") return;
    if (isCorrectVine(word)) {
      registerMove(true);
      const nr = round + 1;
      if (nr >= target) completeLevel();
      else {
        setRound(nr);
        nextVine(level, nr);
      }
    } else failLevel();
  };

  return (
    <WordGameShell
      title="Vowel Vines"
      onExit={onExit}
      onHome={onHome}
      gameState={gameState}
      level={level}
      elapsedTime={elapsedTime}
      unicornImage={unicornImage}
      hudProgress={round + 1}
      hudTarget={target}
      hudProgressLabel="Vines"
      coins={coins}
      onBuyHint={buyHint}
      showHint={showHint}
      hintCost={hintCost}
      isFreeHint={level === 1}
      victory={{
        failReason: "Only grab vines with the right vowel sound!",
        coinsEarned: gameState === "levelComplete" && calcCoins ? calcCoins(level) : 0,
        onAction: gameState === "failed" ? () => launch(level) : () => launch(level + 1),
      }}
    >
      <div className="flex flex-col items-center justify-center h-full p-6 gap-5">
        {unicornImage && (
          <div className="w-20 h-20">
            <UnicornAvatar image={unicornImage} className="w-full h-full" />
          </div>
        )}
        <p className="text-lg text-emerald-300 font-bold">Climb words that start with</p>
        <span className="text-6xl font-black text-lime-400 uppercase">{vowel}</span>
        {showHint && (
          <p className="text-yellow-300 text-sm font-bold text-center px-4 animate-pulse">
            Grab the vine that starts with &quot;{vowel}&quot;!
          </p>
        )}
        <div className="grid grid-cols-2 gap-3 w-full max-w-xs">
          {options.map((w, i) => {
            const highlight = showHint && isCorrectVine(w);
            return (
            <button
              key={`${w}-${i}`}
              type="button"
              onClick={() => climb(w)}
              className={`py-4 rounded-2xl bg-green-950/80 border-2 font-bold text-lg transition-all ${
                highlight
                  ? "border-yellow-400 ring-4 ring-yellow-400/60 shadow-[0_0_24px_rgba(250,204,21,0.5)] animate-pulse"
                  : "border-green-600/40"
              }`}
            >
              🌿 {w}
              {highlight && (
                <span className="block text-[10px] text-yellow-300 mt-1 uppercase tracking-wide">
                  This vine!
                </span>
              )}
            </button>
            );
          })}
        </div>
      </div>
    </WordGameShell>
  );
}
