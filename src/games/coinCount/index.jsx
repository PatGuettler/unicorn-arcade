import React, { useState, useEffect } from "react";
import VictoryModal from "../../components/shared/victoryModal";
import GlobalHeader from "../../components/shared/globalHeader";
import GameHUD from "../../components/shared/gameHUD";
import { useGameSystem } from "../../components/shared/useGameSystem";
import { Coin } from "../../components/assets/gameAssets";
import { formatTime } from "../../utils/useGameManager";

const CoinCountGame = ({
  onExit,
  lastCompletedLevel = 0,
  onSaveProgress,
  calcCoins,
  coins: userCoins,
  onSpendCoins,
  onHome,
}) => {
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
    initialLevel: lastCompletedLevel,
    onSaveProgress,
    onSpendCoins,
  });

  const [target, setTarget] = useState(0);
  const [current, setCurrent] = useState(0);

  const formatMoney = (c) => `$${(c / 100).toFixed(2)}`;

  const coinTypes = [
    { id: "p", v: 1, t: "penny" },
    { id: "n", v: 5, t: "nickel" },
    { id: "d", v: 10, t: "dime" },
    { id: "q", v: 25, t: "quarter" },
  ];

  useEffect(() => {
    let startLvl = lastCompletedLevel;
    if (startLvl === 0) startLvl = 1;
    launchLevel(startLvl);
  }, []);

  const launchLevel = (lvl) => {
    const tgt =
      lvl <= 3
        ? (Math.floor(Math.random() * 9) + 1) * 5
        : lvl <= 8
        ? Math.floor(Math.random() * 100) + 25
        : Math.floor(Math.random() * 400) + 100;

    setTarget(tgt);
    setCurrent(0);
    startGame(lvl);
  };

  const handleCoin = (v) => {
    if (gameState !== "playing") return;
    const next = current + v;
    setCurrent(next);

    registerMove(next <= target);

    if (next === target) {
      completeLevel();
    } else if (next > target) {
      failLevel("Overshot target!");
    }
  };

  const getBestCoin = () => {
    const remaining = target - current;
    const sorted = [...coinTypes].sort((a, b) => b.v - a.v);
    return sorted.find((c) => c.v <= remaining);
  };

  const suggestedCoin = showHint ? getBestCoin() : null;
  const pct = Math.min(100, (current / target) * 100);

  return (
    <div className="w-full h-screen bg-gradient-to-b from-slate-950 via-purple-950 to-slate-950 flex flex-col relative font-sans text-white overflow-hidden">
      <div className="absolute top-0 left-0 w-full z-30 pointer-events-none">
        <div className="pointer-events-auto">
          <GlobalHeader
            coins={userCoins}
            onBack={onExit}
            isSubScreen={true}
            onHome={onHome}
          />
        </div>
      </div>

      <GameHUD
        title="Coin Counter"
        level={level}
        elapsedTime={elapsedTime}
        gameState={gameState}
        coins={userCoins}
        onBuyHint={buyHint}
        showHint={showHint}
        hintCost={hintCost}
        isFreeHint={level === 1}
      />

      <div className="flex-1 flex flex-col items-center justify-center gap-12 pt-20">
        <div className="relative w-64 h-64 flex items-center justify-center">
          <svg
            className="absolute inset-0 w-full h-full rotate-[-90deg]"
            viewBox="0 0 100 100"
          >
            <circle
              cx="50"
              cy="50"
              r="45"
              fill="none"
              stroke="#1e293b"
              strokeWidth="10"
            />
            <circle
              cx="50"
              cy="50"
              r="45"
              fill="none"
              stroke={current > target ? "#ef4444" : "#10b981"}
              strokeWidth="10"
              strokeDasharray="283"
              strokeDashoffset={283 - (283 * pct) / 100}
              strokeLinecap="round"
              className="transition-all duration-300 ease-out"
            />
          </svg>
          <div className="text-center">
            <div className="bg-slate-900/80 backdrop-blur px-6 py-3 rounded-2xl border border-slate-700 shadow-xl pointer-events-auto mb-2">
              <div className="text-cyan-400 text-xs font-bold tracking-widest mb-1">
                TARGET
              </div>
              <div className="text-3xl font-black text-emerald-400 flex items-center justify-center gap-4">
                {formatMoney(target)}
              </div>
            </div>
            <div className="text-slate-400 text-sm font-bold uppercase mb-1">
              Current
            </div>
            <div
              className={`text-5xl font-black ${
                current > target ? "text-rose-500" : "text-white"
              }`}
            >
              {formatMoney(current)}
            </div>
          </div>
        </div>
        <div className="grid grid-cols-4 gap-6 w-full max-w-md justify-items-center">
          {coinTypes.map((c) => (
            <div
              key={c.id}
              className={`relative ${
                suggestedCoin?.id === c.id
                  ? "animate-bounce drop-shadow-[0_0_15px_rgba(234,179,8,0.8)]"
                  : ""
              }`}
            >
              <Coin
                type={c.t}
                disabled={gameState !== "playing"}
                onClick={() => handleCoin(c.v)}
              />
              {suggestedCoin?.id === c.id && (
                <div className="absolute -top-4 left-1/2 -translate-x-1/2 bg-yellow-500 text-black text-[10px] font-black px-2 py-0.5 rounded-full z-20">
                  PICK
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
      {(gameState === "levelComplete" || gameState === "failed") && (
        <VictoryModal
          state={gameState}
          failReason={gameState === "failed" ? "Overshot target!" : ""}
          time={formatTime(elapsedTime)}
          coinsEarned={
            gameState === "levelComplete" && calcCoins ? calcCoins(level) : 0
          }
          onAction={
            gameState === "failed"
              ? () => launchLevel(level)
              : () => launchLevel(level + 1)
          }
          isNext={gameState === "levelComplete"}
        />
      )}
    </div>
  );
};

export default CoinCountGame;
