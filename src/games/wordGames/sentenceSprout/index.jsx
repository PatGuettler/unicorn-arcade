import { useState, useEffect } from "react";
import { useGameSystem } from "../../../components/shared/useGameSystem";
import WordGameShell from "../shared/WordGameShell";
import { UnicornAvatar } from "../../../components/assets/gameAssets";
import { SENTENCE_BUILD, pickForLevel } from "../shared/wordLists";
import { targetForLevel } from "../shared/useWordLevel";

export default function SentenceSproutGame({
  onExit, onHome, lastCompletedLevel = 0, onSaveProgress, calcCoins, coins, unicornImage,
}) {
  const { gameState, level, elapsedTime, startGame, completeLevel, failLevel } =
    useGameSystem({ initialLevel: lastCompletedLevel || 1, onSaveProgress });

  const [round, setRound] = useState(0);
  const [target, setTarget] = useState(5);
  const [sentence, setSentence] = useState(null);
  const [built, setBuilt] = useState([]);
  const [pool, setPool] = useState([]);

  const launch = (lvl) => {
    setRound(0);
    setTarget(targetForLevel(lvl));
    setBuilt([]);
    startGame(lvl);
    loadSentence(lvl, 0);
  };

  const loadSentence = (lvl, r) => {
    const s = pickForLevel(SENTENCE_BUILD, lvl + r);
    setSentence(s);
    setBuilt([]);
    setPool([...s.words].sort(() => Math.random() - 0.5));
  };

  useEffect(() => { launch(lastCompletedLevel || 1); }, []);

  const tapWord = (word, idx) => {
    if (gameState !== "playing" || !sentence) return;
    const expect = sentence.words[built.length];
    if (word !== expect) {
      failLevel();
      return;
    }
    const nb = [...built, word];
    setBuilt(nb);
    setPool((p) => p.filter((_, i) => i !== idx));
    if (nb.length === sentence.words.length) {
      const nr = round + 1;
      if (nr >= target) completeLevel();
      else {
        setRound(nr);
        loadSentence(level, nr);
      }
    }
  };

  return (
    <WordGameShell
      title="Sentence Sprout"
      coins={coins}
      onExit={onExit}
      onHome={onHome}
      gameState={gameState}
      level={level}
      elapsedTime={elapsedTime}
      unicornImage={unicornImage}
      hudProgress={round + 1}
      hudTarget={target}
      hudProgressLabel="Sentences"
      victory={{
        failReason: "Tap words in the right order!",
        coinsEarned: gameState === "levelComplete" && calcCoins ? calcCoins(level) : 0,
        onAction: gameState === "failed" ? () => launch(level) : () => launch(level + 1),
      }}
    >
      <div className="flex flex-col items-center h-full p-4 pt-2 gap-4 overflow-y-auto">
        {unicornImage && (
          <div
            className="w-16 h-16 shrink-0 transition-transform duration-300"
            style={{ transform: `translateY(${built.length * 6}px)` }}
          >
            <UnicornAvatar image={unicornImage} className="w-full h-full" />
          </div>
        )}
        <div className="min-h-[3rem] flex flex-wrap gap-2 justify-center max-w-md">
          {built.map((w, i) => (
            <span key={i} className="px-3 py-1 bg-emerald-900/50 border border-emerald-500/50 rounded-lg font-bold">
              {w}
            </span>
          ))}
        </div>
        <div className="flex flex-wrap gap-2 justify-center max-w-md">
          {pool.map((w, i) => (
            <button
              key={`${w}-${i}`}
              type="button"
              onClick={() => tapWord(w, i)}
              className="px-4 py-3 rounded-xl bg-purple-900/60 border border-purple-400/40 font-bold active:scale-95"
            >
              {w}
            </button>
          ))}
        </div>
      </div>
    </WordGameShell>
  );
}
