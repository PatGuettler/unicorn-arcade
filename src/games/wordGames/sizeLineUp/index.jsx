import { useState, useEffect } from "react";
import { useGameSystem } from "../../../components/shared/useGameSystem";
import WordGameShell from "../shared/WordGameShell";
import { UnicornAvatar } from "../../../components/assets/gameAssets";
import { SIZE_LINEUPS, pickForLevel, shuffle } from "../wordMysteries/lists";
import { targetForLevel } from "../shared/useWordLevel";

export default function SizeLineUpGame({
  onExit, onHome, lastCompletedLevel = 0, onSaveProgress, calcCoins, coins, onSpendCoins, unicornImage,
}) {
  const {
    gameState, level, elapsedTime, showHint, startGame, registerMove, buyHint, completeLevel, failLevel, hintCost,
  } = useGameSystem({ initialLevel: lastCompletedLevel || 1, onSaveProgress, onSpendCoins });

  const [round, setRound] = useState(0);
  const [target, setTarget] = useState(5);
  const [lineup, setLineup] = useState(null);
  const [pool, setPool] = useState([]);
  const [sorted, setSorted] = useState([]);

  const loadLineup = (lvl, r) => {
    const data = pickForLevel(SIZE_LINEUPS, lvl + r);
    setLineup(data);
    setSorted([]);
    setPool(shuffle(data.words));
  };

  const launch = (lvl) => {
    setRound(0);
    setTarget(targetForLevel(lvl));
    startGame(lvl);
    loadLineup(lvl, 0);
  };

  useEffect(() => { launch(lastCompletedLevel || 1); }, []);

  const nextWord = lineup?.order[sorted.length];

  const tapWord = (word, idx) => {
    if (gameState !== "playing" || !lineup) return;
    if (word !== nextWord) {
      failLevel();
      return;
    }
    registerMove(true);
    const ns = [...sorted, word];
    setSorted(ns);
    setPool((p) => p.filter((_, i) => i !== idx));
    if (ns.length === lineup.order.length) {
      const nr = round + 1;
      if (nr >= target) completeLevel();
      else {
        setRound(nr);
        loadLineup(level, nr);
      }
    }
  };

  return (
    <WordGameShell
      title="Size Line-Up"
      coins={coins}
      onExit={onExit}
      onHome={onHome}
      gameState={gameState}
      level={level}
      elapsedTime={elapsedTime}
      unicornImage={unicornImage}
      onBuyHint={buyHint}
      showHint={showHint}
      hintCost={hintCost}
      isFreeHint={level === 1}
      hudProgress={round + 1}
      hudTarget={target}
      hudProgressLabel="Line-ups"
      victory={{
        failReason: "Tap shortest word first, then longer ones!",
        coinsEarned: gameState === "levelComplete" && calcCoins ? calcCoins(level) : 0,
        onAction: gameState === "failed" ? () => launch(level) : () => launch(level + 1),
      }}
    >
      <div className="flex flex-col items-center h-full p-6 gap-5">
        {unicornImage && (
          <div
            className="w-16 h-16 transition-all duration-300"
            style={{ transform: `scale(${1 + sorted.length * 0.08})` }}
          >
            <UnicornAvatar image={unicornImage} className="w-full h-full" />
          </div>
        )}
        <p className="text-teal-300 text-sm font-bold">Tap from shortest → longest</p>
        {showHint && nextWord && (
          <p className="text-yellow-300 text-sm font-bold animate-pulse">Next: {nextWord}</p>
        )}
        <div className="flex gap-2 min-h-[3rem] flex-wrap justify-center max-w-sm">
          {sorted.map((w, i) => (
            <span
              key={i}
              className="px-4 py-2 rounded-xl bg-teal-900/50 border border-teal-400/60 font-bold"
              style={{ fontSize: `${0.75 + i * 0.15}rem` }}
            >
              {w}
            </span>
          ))}
        </div>
        <div className="flex flex-col gap-2 w-full max-w-xs">
          {pool.map((w, i) => {
            const highlight = showHint && w === nextWord;
            return (
              <button
                key={`${w}-${i}`}
                type="button"
                onClick={() => tapWord(w, i)}
                className={`py-3 rounded-xl border-2 font-bold active:scale-95 ${
                  highlight
                    ? "bg-yellow-900/30 border-yellow-400 ring-2 ring-yellow-400/60"
                    : "bg-slate-800 border-teal-500/40"
                }`}
              >
                {w} <span className="text-slate-500 text-xs">({w.length} letters)</span>
              </button>
            );
          })}
        </div>
      </div>
    </WordGameShell>
  );
}
