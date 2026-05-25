import { useState, useEffect } from "react";
import { useGameSystem } from "../../../components/shared/useGameSystem";
import WordGameShell from "../shared/WordGameShell";
import { UnicornAvatar } from "../../../components/assets/gameAssets";
import { PREFIX_MIX, pickForLevel, shuffle } from "../shared/wordLists";
import { targetForLevel } from "../shared/useWordLevel";

export default function PrefixPotionGame({
  onExit, onHome, lastCompletedLevel = 0, onSaveProgress, calcCoins, coins, unicornImage,
}) {
  const { gameState, level, elapsedTime, startGame, completeLevel, failLevel } =
    useGameSystem({ initialLevel: lastCompletedLevel || 1, onSaveProgress });

  const [round, setRound] = useState(0);
  const [target, setTarget] = useState(5);
  const [mix, setMix] = useState(null);

  const launch = (lvl) => {
    setRound(0);
    setTarget(targetForLevel(lvl));
    startGame(lvl);
    loadMix(lvl, 0);
  };

  const loadMix = (lvl, r) => {
    const m = pickForLevel(PREFIX_MIX, lvl + r);
    setMix({
      ...m,
      choices: shuffle([m.answer, ...m.wrong]),
    });
  };

  useEffect(() => { launch(lastCompletedLevel || 1); }, []);

  const brew = (word) => {
    if (gameState !== "playing" || !mix) return;
    if (word === mix.answer) {
      const nr = round + 1;
      if (nr >= target) completeLevel();
      else {
        setRound(nr);
        loadMix(level, nr);
      }
    } else failLevel();
  };

  return (
    <WordGameShell
      title="Prefix Potion"
      coins={coins}
      onExit={onExit}
      onHome={onHome}
      gameState={gameState}
      level={level}
      elapsedTime={elapsedTime}
      unicornImage={unicornImage}
      victory={{
        failReason: "Brew the real word!",
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
        <p className="text-slate-400 text-sm">Stir the potion: prefix + root</p>
        <div className="flex items-center gap-2 text-2xl font-black">
          <span className="px-3 py-2 bg-violet-800 rounded-lg">{mix?.prefix}</span>
          <span>+</span>
          <span className="px-3 py-2 bg-fuchsia-800 rounded-lg">{mix?.root}</span>
          <span>=</span>
          <span className="text-pink-300">?</span>
        </div>
        <p className="text-xs text-slate-500">{round + 1}/{target}</p>
        <div className="grid gap-2 w-full max-w-xs">
          {mix?.choices.map((c) => (
            <button
              key={c}
              type="button"
              onClick={() => brew(c)}
              className="py-3 rounded-xl bg-slate-800/90 border-2 border-violet-500/40 font-bold"
            >
              {c}
            </button>
          ))}
        </div>
      </div>
    </WordGameShell>
  );
}
