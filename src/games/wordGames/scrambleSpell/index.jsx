import { useState, useEffect } from "react";
import { useGameSystem } from "../../../components/shared/useGameSystem";
import WordGameShell from "../shared/WordGameShell";
import { UnicornAvatar } from "../../../components/assets/gameAssets";
import { SCRAMBLE_PUZZLES, pickForLevel, shuffle } from "../wordMysteries/lists";
import { targetForLevel } from "../shared/useWordLevel";

export default function ScrambleSpellGame({
  onExit, onHome, lastCompletedLevel = 0, onSaveProgress, calcCoins, coins, unicornImage,
}) {
  const { gameState, level, elapsedTime, startGame, completeLevel, failLevel } =
    useGameSystem({ initialLevel: lastCompletedLevel || 1, onSaveProgress });

  const [round, setRound] = useState(0);
  const [target, setTarget] = useState(5);
  const [puzzle, setPuzzle] = useState(null);
  const [pool, setPool] = useState([]);
  const [picked, setPicked] = useState([]);

  const loadPuzzle = (lvl, r) => {
    const p = pickForLevel(SCRAMBLE_PUZZLES, lvl + r);
    setPuzzle(p);
    setPicked([]);
    setPool(shuffle(p.word.split("")));
  };

  const launch = (lvl) => {
    setRound(0);
    setTarget(targetForLevel(lvl));
    startGame(lvl);
    loadPuzzle(lvl, 0);
  };

  useEffect(() => { launch(lastCompletedLevel || 1); }, []);

  const tapLetter = (letter, idx) => {
    if (gameState !== "playing" || !puzzle) return;
    const expect = puzzle.word[picked.length];
    if (letter !== expect) {
      failLevel();
      return;
    }
    const np = [...picked, letter];
    setPicked(np);
    setPool((prev) => prev.filter((_, i) => i !== idx));
    if (np.length === puzzle.word.length) {
      const nr = round + 1;
      if (nr >= target) completeLevel();
      else {
        setRound(nr);
        loadPuzzle(level, nr);
      }
    }
  };

  return (
    <WordGameShell
      title="Scramble Spell"
      coins={coins}
      onExit={onExit}
      onHome={onHome}
      gameState={gameState}
      level={level}
      elapsedTime={elapsedTime}
      unicornImage={unicornImage}
      hudProgress={round + 1}
      hudTarget={target}
      hudProgressLabel="Words"
      victory={{
        failReason: "Tap letters in order to spell the word!",
        coinsEarned: gameState === "levelComplete" && calcCoins ? calcCoins(level) : 0,
        onAction: gameState === "failed" ? () => launch(level) : () => launch(level + 1),
      }}
    >
      <div className="flex flex-col items-center h-full p-4 gap-4 overflow-y-auto">
        {unicornImage && (
          <div className="w-16 h-16 shrink-0">
            <UnicornAvatar image={unicornImage} className="w-full h-full" />
          </div>
        )}
        <p className="text-2xl">{puzzle?.emoji}</p>
        <p className="text-slate-300 text-center text-sm font-bold max-w-xs">{puzzle?.hint}</p>
        <div className="flex gap-1 min-h-[2.5rem] flex-wrap justify-center max-w-xs">
          {picked.map((l, i) => (
            <span key={i} className="w-9 h-9 flex items-center justify-center rounded-lg bg-indigo-900 border border-indigo-400 font-black text-lg uppercase">
              {l}
            </span>
          ))}
          {puzzle && Array.from({ length: puzzle.word.length - picked.length }).map((_, i) => (
            <span key={`e-${i}`} className="w-9 h-9 rounded-lg border-2 border-dashed border-slate-600" />
          ))}
        </div>
        <div className="flex flex-wrap gap-2 justify-center max-w-sm">
          {pool.map((l, i) => (
            <button
              key={`${l}-${i}`}
              type="button"
              onClick={() => tapLetter(l, i)}
              className="w-11 h-11 rounded-xl bg-violet-900/70 border-2 border-violet-400/50 font-black text-lg uppercase active:scale-95"
            >
              {l}
            </button>
          ))}
        </div>
      </div>
    </WordGameShell>
  );
}
