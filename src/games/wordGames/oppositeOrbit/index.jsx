import { useState, useEffect } from "react";
import { useGameSystem } from "../../../components/shared/useGameSystem";
import WordGameShell from "../shared/WordGameShell";
import { UnicornAvatar } from "../../../components/assets/gameAssets";
import { OPPOSITE_CHALLENGES, pickForLevel, shuffle } from "../wordMysteries/lists";
import { targetForLevel } from "../shared/useWordLevel";

export default function OppositeOrbitGame({
  onExit, onHome, lastCompletedLevel = 0, onSaveProgress, calcCoins, coins, unicornImage,
}) {
  const { gameState, level, elapsedTime, startGame, completeLevel, failLevel } =
    useGameSystem({ initialLevel: lastCompletedLevel || 1, onSaveProgress });

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
        <div className="grid grid-cols-2 gap-3 w-full max-w-xs">
          {challenge?.options.map((o) => (
            <button
              key={o}
              type="button"
              onClick={() => pick(o)}
              className="py-4 rounded-2xl bg-slate-800 border-2 border-indigo-500/50 font-bold hover:border-indigo-300 active:scale-95"
            >
              {o}
            </button>
          ))}
        </div>
      </div>
    </WordGameShell>
  );
}
