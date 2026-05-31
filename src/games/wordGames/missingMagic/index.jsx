import { useState, useEffect } from "react";
import { useGameSystem } from "../../../components/shared/useGameSystem";
import WordGameShell from "../shared/WordGameShell";
import { UnicornAvatar } from "../../../components/assets/gameAssets";
import { MISSING_WORD, pickForLevel, shuffle } from "../shared/wordLists";
import { targetForLevel } from "../shared/useWordLevel";

export default function MissingMagicGame({
  onExit, onHome, lastCompletedLevel = 0, onSaveProgress, calcCoins, coins, onSpendCoins, unicornImage,
}) {
  const {
    gameState, level, elapsedTime, showHint, startGame, registerMove, buyHint, completeLevel, failLevel, hintCost,
  } = useGameSystem({ initialLevel: lastCompletedLevel || 1, onSaveProgress, onSpendCoins });

  const [round, setRound] = useState(0);
  const [target, setTarget] = useState(5);
  const [puzzle, setPuzzle] = useState(null);

  const launch = (lvl) => {
    setRound(0);
    setTarget(targetForLevel(lvl));
    startGame(lvl);
    loadPuzzle(lvl, 0);
  };

  const loadPuzzle = (lvl, r) => {
    const p = pickForLevel(MISSING_WORD, lvl + r);
    setPuzzle({ ...p, options: shuffle(p.options) });
  };

  useEffect(() => { launch(lastCompletedLevel || 1); }, []);

  const choose = (word) => {
    if (gameState !== "playing" || !puzzle) return;
    if (word === puzzle.answer) {
      registerMove(true);
      const nr = round + 1;
      if (nr >= target) completeLevel();
      else {
        setRound(nr);
        loadPuzzle(level, nr);
      }
    } else failLevel();
  };

  return (
    <WordGameShell
      title="Missing Magic"
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
      victory={{
        failReason: "Fill the magic blank!",
        coinsEarned: gameState === "levelComplete" && calcCoins ? calcCoins(level) : 0,
        onAction: gameState === "failed" ? () => launch(level) : () => launch(level + 1),
      }}
    >
      <div className="flex flex-col items-center justify-center h-full p-6 gap-6">
        {unicornImage && (
          <div className="w-20 h-20">
            <UnicornAvatar image={unicornImage} className="w-full h-full" />
          </div>
        )}
        <div className="text-xl font-bold text-center leading-relaxed max-w-sm">
          {puzzle?.text.map((part, i) =>
            part === null ? (
              <span key={i} className="inline-block mx-1 px-3 py-1 border-2 border-dashed border-pink-400 rounded-lg text-pink-300">
                {showHint ? puzzle.answer : "???"}
              </span>
            ) : (
              <span key={i}> {part} </span>
            )
          )}
        </div>
        <p className="text-xs text-slate-500">{round + 1}/{target}</p>
        <div className="flex flex-col gap-2 w-full max-w-xs">
          {puzzle?.options.map((o) => {
            const highlight = showHint && o === puzzle.answer;
            return (
              <button
                key={o}
                type="button"
                onClick={() => choose(o)}
                className={`py-3 rounded-xl border font-bold ${
                  highlight
                    ? "bg-yellow-900/30 border-yellow-400 ring-2 ring-yellow-400/60"
                    : "bg-slate-800 border-cyan-500/30 hover:border-cyan-400"
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
