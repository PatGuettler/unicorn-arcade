import { useState, useEffect, useRef } from "react";
import { useGameSystem } from "../../../components/shared/useGameSystem";
import WordGameShell from "../shared/WordGameShell";
import { UnicornAvatar } from "../../../components/assets/gameAssets";
import { wordsForLevel } from "../shared/wordLists";
import { targetForLevel } from "../shared/useWordLevel";

export default function SightSparkGame({
  onExit, onHome, lastCompletedLevel = 0, onSaveProgress, calcCoins, coins, unicornImage,
}) {
  const { gameState, level, elapsedTime, startGame, completeLevel, failLevel } =
    useGameSystem({ initialLevel: lastCompletedLevel || 1, onSaveProgress });

  const [round, setRound] = useState(0);
  const [target, setTarget] = useState(5);
  const [flash, setFlash] = useState("");
  const [phase, setPhase] = useState("ready");
  const [input, setInput] = useState("");
  const timerRef = useRef(null);

  const launch = (lvl) => {
    setRound(0);
    setTarget(targetForLevel(lvl));
    setInput("");
    startGame(lvl);
    showFlash(lvl, 0);
  };

  const showFlash = (lvl, r) => {
    const list = wordsForLevel(lvl);
    const word = list[(r + lvl) % list.length];
    setPhase("flash");
    setFlash(word);
    const ms = Math.max(800, 2200 - lvl * 80);
    if (timerRef.current) clearTimeout(timerRef.current);
    timerRef.current = setTimeout(() => {
      setPhase("type");
      setFlash("");
    }, ms);
  };

  useEffect(() => {
    launch(lastCompletedLevel || 1);
    return () => clearTimeout(timerRef.current);
  }, []);

  const submit = (e) => {
    e.preventDefault();
    if (phase !== "type" || gameState !== "playing") return;
    const list = wordsForLevel(level);
    const expected = list[(round + level) % list.length];
    if (input.trim().toLowerCase() === expected) {
      const nr = round + 1;
      setInput("");
      if (nr >= target) completeLevel();
      else {
        setRound(nr);
        showFlash(level, nr);
      }
    } else failLevel();
  };

  return (
    <WordGameShell
      title="Sight Spark"
      coins={coins}
      onExit={onExit}
      onHome={onHome}
      gameState={gameState}
      level={level}
      elapsedTime={elapsedTime}
      unicornImage={unicornImage}
      footer={
        phase === "type" ? (
          <form onSubmit={submit} className="px-4 pb-6">
            <input
              value={input}
              onChange={(e) => setInput(e.target.value)}
              className="w-full max-w-md mx-auto block bg-slate-900 border-2 border-amber-500/50 rounded-xl px-4 py-3 text-center text-lg font-bold outline-none"
              placeholder="What did you see?"
              autoFocus
              autoCapitalize="off"
              spellCheck={false}
            />
          </form>
        ) : null
      }
      victory={{
        failReason: "Spell the spark word from memory!",
        coinsEarned: gameState === "levelComplete" && calcCoins ? calcCoins(level) : 0,
        onAction: gameState === "failed" ? () => launch(level) : () => launch(level + 1),
      }}
    >
      <div className="flex flex-col items-center justify-center h-full gap-4">
        {unicornImage && (
          <div className={`w-20 h-20 ${phase === "flash" ? "animate-pulse" : "opacity-50"}`}>
            <UnicornAvatar image={unicornImage} className="w-full h-full" />
          </div>
        )}
        <p className="text-sm text-slate-400">
          {phase === "flash" ? "Unicorn flashes the word…" : "Now type it!"}
        </p>
        <div className="text-5xl font-black min-h-[4rem] text-yellow-300">
          {phase === "flash" ? flash : "?"}
        </div>
        <p className="text-xs text-slate-500">{round + 1}/{target}</p>
      </div>
    </WordGameShell>
  );
}
