import { useState, useEffect } from "react";
import { useGameSystem } from "../../../components/shared/useGameSystem";
import WordGameShell from "../shared/WordGameShell";
import { UnicornAvatar } from "../../../components/assets/gameAssets";
import { wordsForLevel } from "../shared/wordLists";
import { targetForLevel } from "../shared/useWordLevel";

export default function LetterLiftGame({
  onExit, onHome, lastCompletedLevel = 0, onSaveProgress, calcCoins, coins, unicornImage,
}) {
  const { gameState, level, elapsedTime, startGame, completeLevel, failLevel } =
    useGameSystem({ initialLevel: lastCompletedLevel || 1, onSaveProgress });

  const [round, setRound] = useState(0);
  const [target, setTarget] = useState(5);
  const [word, setWord] = useState("");
  const [index, setIndex] = useState(0);
  const [typed, setTyped] = useState("");

  const launch = (lvl) => {
    setRound(0);
    setTarget(targetForLevel(lvl));
    startGame(lvl);
    startWord(lvl, 0);
  };

  const startWord = (lvl, r) => {
    const list = wordsForLevel(lvl);
    setWord(list[(r + lvl) % list.length]);
    setIndex(0);
    setTyped("");
  };

  useEffect(() => { launch(lastCompletedLevel || 1); }, []);

  const onKey = (e) => {
    if (gameState !== "playing" || index >= word.length) return;
    const ch = e.key.toLowerCase();
    if (ch.length !== 1 || !/[a-z]/.test(ch)) return;
    if (ch === word[index]) {
      const ni = index + 1;
      setIndex(ni);
      setTyped((t) => t + ch);
      if (ni >= word.length) {
        const nr = round + 1;
        if (nr >= target) completeLevel();
        else {
          setRound(nr);
          startWord(level, nr);
        }
      }
    } else failLevel();
  };

  useEffect(() => {
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [word, index, gameState, round, level, target]);

  const climbPct = word ? (index / word.length) * 100 : 0;

  return (
    <WordGameShell
      title="Letter Lift"
      coins={coins}
      onExit={onExit}
      onHome={onHome}
      gameState={gameState}
      level={level}
      elapsedTime={elapsedTime}
      unicornImage={unicornImage}
      victory={{
        failReason: "Type each letter to lift your unicorn!",
        coinsEarned: gameState === "levelComplete" && calcCoins ? calcCoins(level) : 0,
        onAction: gameState === "failed" ? () => launch(level) : () => launch(level + 1),
      }}
    >
      <div className="flex flex-col items-center h-full p-6 gap-4">
        <div className="relative w-16 h-48 bg-slate-800 rounded-full border-2 border-slate-600 overflow-hidden">
          <div
            className="absolute bottom-0 w-full bg-gradient-to-t from-pink-600/40 to-transparent transition-all duration-300"
            style={{ height: `${climbPct}%` }}
          />
          {unicornImage && (
            <div
              className="absolute left-1/2 -translate-x-1/2 w-12 h-12 transition-all duration-300"
              style={{ bottom: `calc(${climbPct}% - 8px)` }}
            >
              <UnicornAvatar image={unicornImage} className="w-full h-full" />
            </div>
          )}
        </div>
        <p className="text-3xl font-black tracking-[0.4em]">{typed}</p>
        <p className="text-slate-500 text-sm">
          Next letter: <span className="text-pink-300 font-bold">{word[index] || "✓"}</span>
        </p>
        <p className="text-xs text-slate-500">{round + 1}/{target} words</p>
      </div>
    </WordGameShell>
  );
}
