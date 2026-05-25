import { useState, useEffect } from "react";
import { useGameSystem } from "../../../components/shared/useGameSystem";
import WordGameShell from "../shared/WordGameShell";
import { UnicornAvatar } from "../../../components/assets/gameAssets";
import { CAPTION_SCENES, pickForLevel, shuffle } from "../shared/wordLists";
import { targetForLevel } from "../shared/useWordLevel";

export default function CaptionQuestGame({
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
  const [target, setTarget] = useState(4);
  const [scene, setScene] = useState(null);
  const [lives, setLives] = useState(3);
  const [shake, setShake] = useState(false);

  const loadScene = (lvl, r) => {
    const base = pickForLevel(CAPTION_SCENES, lvl + r);
    setScene({ ...base, options: shuffle(base.options) });
  };

  const launch = (lvl) => {
    setRound(0);
    setTarget(Math.min(4, targetForLevel(lvl)));
    setLives(3);
    setShake(false);
    startGame(lvl);
    loadScene(lvl, 0);
  };

  useEffect(() => {
    launch(lastCompletedLevel || 1);
  }, []);

  const pickWord = (word) => {
    if (gameState !== "playing" || !scene) return;
    if (word === scene.answer) {
      registerMove(true);
      const nr = round + 1;
      if (nr >= target) completeLevel();
      else {
        setRound(nr);
        loadScene(level, nr);
      }
    } else {
      setShake(true);
      setTimeout(() => setShake(false), 450);
      setLives((l) => {
        const n = l - 1;
        if (n <= 0) failLevel();
        return n;
      });
    }
  };

  return (
    <WordGameShell
      title="Caption Quest"
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
      hudProgressLabel="Scenes"
      lives={lives}
      victory={{
        failReason: "Out of hearts — tap the best word!",
        coinsEarned: gameState === "levelComplete" && calcCoins ? calcCoins(level) : 0,
        onAction: gameState === "failed" ? () => launch(level) : () => launch(level + 1),
      }}
    >
      <div
        className={`flex flex-col items-center justify-center h-full gap-4 p-4 pb-2 overflow-y-auto ${
          shake ? "animate-[shake_0.4s_ease-in-out]" : ""
        }`}
      >
        {unicornImage && (
          <div className="w-14 h-14 shrink-0">
            <UnicornAvatar image={unicornImage} className="w-full h-full" />
          </div>
        )}
        <div className="text-6xl sm:text-7xl">{scene?.emoji}</div>
        <p className="text-white text-center text-base sm:text-lg font-bold max-w-xs leading-snug px-2">
          {scene?.prompt}
        </p>
        <p className="text-slate-400 text-center text-xs max-w-xs">
          Tap one word — your unicorn agrees!
        </p>
        {showHint && scene && (
          <p className="text-yellow-300 text-sm font-bold text-center animate-pulse px-4">
            Try: <span className="uppercase">{scene.answer}</span>
          </p>
        )}
        <div className="grid grid-cols-2 gap-3 w-full max-w-xs mt-2">
          {scene?.options.map((w) => {
            const isAnswer = w === scene.answer;
            const highlight = showHint && isAnswer;
            return (
              <button
                key={w}
                type="button"
                onClick={() => pickWord(w)}
                className={`py-4 px-2 rounded-2xl font-bold text-lg border-2 transition-all active:scale-95 ${
                  highlight
                    ? "bg-sky-900/80 border-yellow-400 ring-4 ring-yellow-400/50 animate-pulse"
                    : "bg-slate-800/90 border-sky-500/40 hover:border-sky-400"
                }`}
              >
                {w}
              </button>
            );
          })}
        </div>
      </div>
      <style>{`
        @keyframes shake {
          0%, 100% { transform: translateX(0); }
          25% { transform: translateX(-6px); }
          75% { transform: translateX(6px); }
        }
      `}</style>
    </WordGameShell>
  );
}
