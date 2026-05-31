import { useState, useEffect } from "react";
import { useGameSystem } from "../../../components/shared/useGameSystem";
import WordGameShell from "../shared/WordGameShell";
import { UnicornAvatar } from "../../../components/assets/gameAssets";
import { OPPOSITE_CHALLENGES, pickForLevel, shuffle } from "../wordMysteries/lists";
import { targetForLevel } from "../shared/useWordLevel";

export default function OppositeOrbitGame({
  onExit, onHome, lastCompletedLevel = 0, onSaveProgress, calcCoins, coins, onSpendCoins, unicornImage,
}) {
  const {
    gameState, level, elapsedTime, showHint, startGame, registerMove, buyHint, completeLevel, failLevel, hintCost,
  } = useGameSystem({ initialLevel: lastCompletedLevel || 1, onSaveProgress, onSpendCoins });

  const [round, setRound] = useState(0);
  const [target, setTarget] = useState(5);
  const [challenge, setChallenge] = useState(null);
  const [spin, setSpin] = useState(false);

  const nextRound = (lvl, r) => {
    const base = pickForLevel(OPPOSITE_CHALLENGES, lvl + r);
    setChallenge({ ...base, options: shuffle(base.options) });
  };

  const launch = (lvl) => {
    setRound(0);
    setTarget(targetForLevel(lvl));
    startGame(lvl);
    nextRound(lvl, 0);
  };

  useEffect(() => { launch(lastCompletedLevel || 1); }, []);

  const pick = (opt) => {
    if (gameState !== "playing" || !challenge) return;
    if (opt === challenge.answer) {
      registerMove(true);
      setSpin(true);
      setTimeout(() => setSpin(false), 500);
      const nr = round + 1;
      if (nr >= target) completeLevel();
      else {
        setRound(nr);
        nextRound(level, nr);
      }
    } else failLevel();
  };

  return (
    <WordGameShell
      title="Opposite Orbit"
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
      hudProgressLabel="Opposites"
      victory={{
        failReason: "Pick the word that means the OPPOSITE!",
        coinsEarned: gameState === "levelComplete" && calcCoins ? calcCoins(level) : 0,
        onAction: gameState === "failed" ? () => launch(level) : () => launch(level + 1),
      }}
    >
      <div className="flex flex-col items-center justify-center h-full p-6 gap-6">
        {unicornImage && (
          <div className={`w-24 h-24 transition-transform duration-500 ${spin ? "rotate-180" : ""}`}>
            <UnicornAvatar image={unicornImage} className="w-full h-full" />
          </div>
        )}
        <p className="text-indigo-300 text-sm font-bold uppercase tracking-wider">Opposite of</p>
        <h2 className="text-5xl font-black text-white">{challenge?.word}</h2>
        {showHint && (
          <p className="text-yellow-300 text-sm font-bold animate-pulse">Pick the opposite word!</p>
        )}
        <div className="grid grid-cols-2 gap-3 w-full max-w-xs">
          {challenge?.options.map((o) => {
            const highlight = showHint && o === challenge.answer;
            return (
              <button
                key={o}
                type="button"
                onClick={() => pick(o)}
                className={`py-4 rounded-2xl border-2 font-bold active:scale-95 ${
                  highlight
                    ? "bg-yellow-900/30 border-yellow-400 ring-2 ring-yellow-400/60"
                    : "bg-slate-800 border-indigo-500/50 hover:border-indigo-300"
                }`}
              >
                {o}
              </button>
            );
          })}
        </div>
      </div>
    </WordGameShell>
  );
}
