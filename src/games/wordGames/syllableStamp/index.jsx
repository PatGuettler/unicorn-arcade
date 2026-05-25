import { useState, useEffect } from "react";
import { useGameSystem } from "../../../components/shared/useGameSystem";
import WordGameShell from "../shared/WordGameShell";
import { UnicornAvatar } from "../../../components/assets/gameAssets";
import { SYLLABLE_WORDS, pickForLevel } from "../shared/wordLists";
import { targetForLevel } from "../shared/useWordLevel";

export default function SyllableStampGame({
  onExit, onHome, lastCompletedLevel = 0, onSaveProgress, calcCoins, coins, unicornImage,
}) {
  const { gameState, level, elapsedTime, startGame, completeLevel, failLevel } =
    useGameSystem({ initialLevel: lastCompletedLevel || 1, onSaveProgress });

  const [round, setRound] = useState(0);
  const [target, setTarget] = useState(5);
  const [item, setItem] = useState(null);
  const [stamped, setStamped] = useState([]);
  const [pool, setPool] = useState([]);

  const launch = (lvl) => {
    setRound(0);
    setTarget(targetForLevel(lvl));
    startGame(lvl);
    loadWord(lvl, 0);
  };

  const loadWord = (lvl, r) => {
    const w = pickForLevel(SYLLABLE_WORDS, lvl + r);
    setItem(w);
    setStamped([]);
    setPool([...w.parts].sort(() => Math.random() - 0.5));
  };

  useEffect(() => { launch(lastCompletedLevel || 1); }, []);

  const stamp = (part, idx) => {
    if (gameState !== "playing" || !item) return;
    if (part !== item.parts[stamped.length]) {
      failLevel();
      return;
    }
    const ns = [...stamped, part];
    setStamped(ns);
    setPool((p) => p.filter((_, i) => i !== idx));
    if (ns.length === item.parts.length) {
      const nr = round + 1;
      if (nr >= target) completeLevel();
      else {
        setRound(nr);
        loadWord(level, nr);
      }
    }
  };

  return (
    <WordGameShell
      title="Syllable Stamp"
      coins={coins}
      onExit={onExit}
      onHome={onHome}
      gameState={gameState}
      level={level}
      elapsedTime={elapsedTime}
      unicornImage={unicornImage}
      victory={{
        failReason: "Stamp syllables in order!",
        coinsEarned: gameState === "levelComplete" && calcCoins ? calcCoins(level) : 0,
        onAction: gameState === "failed" ? () => launch(level) : () => launch(level + 1),
      }}
    >
      <div className="flex flex-col items-center h-full p-6 gap-5">
        {unicornImage && (
          <div className="w-16 h-16">
            <UnicornAvatar image={unicornImage} className="w-full h-full" />
          </div>
        )}
        <p className="text-slate-400">Build: {item?.word}</p>
        <div className="flex gap-2 min-h-[3rem]">
          {stamped.map((s, i) => (
            <span key={i} className="px-4 py-2 rounded-full bg-amber-900/60 border-2 border-amber-400 font-bold">
              {s}
            </span>
          ))}
        </div>
        <p className="text-xs text-slate-500">{round + 1}/{target}</p>
        <div className="flex flex-wrap gap-2 justify-center max-w-sm">
          {pool.map((p, i) => (
            <button
              key={`${p}-${i}`}
              type="button"
              onClick={() => stamp(p, i)}
              className="px-5 py-3 rounded-2xl bg-orange-950/70 border border-orange-400/50 font-bold text-lg"
            >
              🦄 {p}
            </button>
          ))}
        </div>
      </div>
    </WordGameShell>
  );
}
