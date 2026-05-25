import { useState, useEffect } from "react";
import { useGameSystem } from "../../../components/shared/useGameSystem";
import WordGameShell from "../shared/WordGameShell";
import { UnicornAvatar } from "../../../components/assets/gameAssets";
import { RHYME_CHALLENGES, pickForLevel, shuffle } from "../shared/wordLists";
import { targetForLevel } from "../shared/useWordLevel";

export default function RhymeRallyGame({
  onExit, onHome, lastCompletedLevel = 0, onSaveProgress, calcCoins, coins, unicornImage,
}) {
  const { gameState, level, elapsedTime, startGame, completeLevel, failLevel } =
    useGameSystem({ initialLevel: lastCompletedLevel || 1, onSaveProgress });

  const [round, setRound] = useState(0);
  const [target, setTarget] = useState(5);
  const [challenge, setChallenge] = useState(null);
  const [streak, setStreak] = useState(0);
  const [unicornHop, setUnicornHop] = useState(false);

  const nextRound = (lvl, r) => {
    const base = pickForLevel(RHYME_CHALLENGES, lvl + r);
    setChallenge({ ...base, options: shuffle(base.options) });
  };

  const launch = (lvl) => {
    setRound(0);
    setTarget(targetForLevel(lvl));
    setStreak(0);
    startGame(lvl);
    nextRound(lvl, 0);
  };

  useEffect(() => { launch(lastCompletedLevel || 1); }, []);

  const pick = (opt) => {
    if (gameState !== "playing" || !challenge) return;
    if (opt === challenge.answer) {
      setUnicornHop(true);
      setTimeout(() => setUnicornHop(false), 400);
      const nr = round + 1;
      if (nr >= target) completeLevel();
      else {
        setRound(nr);
        nextRound(level, nr);
      }
    } else {
      setStreak(0);
      failLevel();
    }
  };

  return (
    <WordGameShell
      title="Rhyme Rally"
      coins={coins}
      onExit={onExit}
      onHome={onHome}
      gameState={gameState}
      level={level}
      elapsedTime={elapsedTime}
      unicornImage={unicornImage}
      victory={{
        failReason: "Pick the word that rhymes!",
        coinsEarned: gameState === "levelComplete" && calcCoins ? calcCoins(level) : 0,
        onAction: gameState === "failed" ? () => launch(level) : () => launch(level + 1),
      }}
    >
      <div className="flex flex-col items-center justify-center h-full p-6 gap-6">
        {unicornImage && (
          <div className={`w-24 h-24 transition-transform ${unicornHop ? "-translate-y-8" : ""}`}>
            <UnicornAvatar image={unicornImage} className="w-full h-full" />
          </div>
        )}
        <p className="text-slate-400 text-sm">What rhymes with</p>
        <h2 className="text-4xl font-black text-pink-300">{challenge?.prompt}</h2>
        <p className="text-xs text-slate-500">{round}/{target} — unicorn hops on rhymes!</p>
        <div className="grid grid-cols-2 gap-3 w-full max-w-xs">
          {challenge?.options.map((o) => (
            <button
              key={o}
              type="button"
              onClick={() => pick(o)}
              className="py-4 rounded-2xl bg-slate-800 border-2 border-purple-500/40 font-bold hover:border-pink-400 active:scale-95"
            >
              {o}
            </button>
          ))}
        </div>
      </div>
    </WordGameShell>
  );
}
