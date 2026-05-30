import { useState, useEffect } from "react";
import { useGameSystem } from "../../../components/shared/useGameSystem";
import WordGameShell from "../shared/WordGameShell";
import { UnicornAvatar } from "../../../components/assets/gameAssets";
import { ODD_ONE_OUT, pickForLevel, shuffle } from "../wordMysteries/lists";
import { targetForLevel } from "../shared/useWordLevel";

export default function OddOneOutGame({
  onExit,
  onHome,
  lastCompletedLevel = 0,
  onSaveProgress,
  calcCoins,
  coins,
  onSpendCoins,
  unicornImage,
}) {
  const {
    gameState,
    level,
    elapsedTime,
    showHint,
    startGame,
    registerMove,
    buyHint,
    completeLevel,
    failLevel,
    hintCost,
  } = useGameSystem({
    initialLevel: lastCompletedLevel || 1,
    onSaveProgress,
    onSpendCoins,
  });

  const [round, setRound] = useState(0);
  const [target, setTarget] = useState(5);
  const [caseFile, setCaseFile] = useState(null);
  const [lives, setLives] = useState(3);

  const loadCase = (lvl, r) => {
    const c = pickForLevel(ODD_ONE_OUT, lvl + r);
    setCaseFile({ ...c, items: shuffle(c.items) });
  };

  const launch = (lvl) => {
    setRound(0);
    setTarget(Math.min(6, targetForLevel(lvl)));
    setLives(3);
    startGame(lvl);
    loadCase(lvl, 0);
  };

  useEffect(() => { launch(lastCompletedLevel || 1); }, []);

  const investigate = (label) => {
    if (gameState !== "playing" || !caseFile) return;
    if (label === caseFile.odd) {
      registerMove(true);
      const nr = round + 1;
      if (nr >= target) completeLevel();
      else {
        setRound(nr);
        loadCase(level, nr);
      }
    } else {
      setLives((l) => {
        const n = l - 1;
        if (n <= 0) failLevel();
        return n;
      });
    }
  };

  return (
    <WordGameShell
      title="Odd One Out"
      onExit={onExit}
      onHome={onHome}
      gameState={gameState}
      level={level}
      elapsedTime={elapsedTime}
      unicornImage={unicornImage}
      coins={coins}
      onBuyHint={buyHint}
      showHint={showHint}
      hintCost={hintCost}
      isFreeHint={level === 1}
      hudProgress={round + 1}
      hudTarget={target}
      hudProgressLabel="Cases"
      lives={lives}
      victory={{
        failReason: "Find the one that does not belong!",
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
        <p className="text-amber-400/90 text-xs font-bold uppercase tracking-wider">Case file</p>
        <p className="text-white text-center font-bold max-w-xs">{caseFile?.theme}</p>
        {showHint && (
          <p className="text-yellow-300 text-sm animate-pulse font-bold">
            One item is NOT like the others!
          </p>
        )}
        <div className="grid grid-cols-2 gap-3 w-full max-w-xs">
          {caseFile?.items.map((item) => {
            const highlight = showHint && item.label === caseFile.odd;
            return (
              <button
                key={item.label}
                type="button"
                onClick={() => investigate(item.label)}
                className={`py-5 rounded-2xl border-2 flex flex-col items-center gap-2 font-bold active:scale-95 ${
                  highlight
                    ? "border-yellow-400 bg-yellow-900/30"
                    : "border-slate-600 bg-slate-800 hover:border-indigo-400"
                }`}
              >
                <span className="text-4xl">{item.emoji}</span>
                <span className="text-sm capitalize">{item.label}</span>
              </button>
            );
          })}
        </div>
      </div>
    </WordGameShell>
  );
}
