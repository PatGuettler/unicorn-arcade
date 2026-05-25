import React from "react";
import { Timer, HelpCircle } from "lucide-react";

const GameHUD = ({
  title,
  level,
  elapsedTime,
  gameState,
  coins,
  onBuyHint,
  showHint,
  hintCost,
  isFreeHint = false,
  progress,
  target,
  progressLabel = "PROGRESS",
  lives,
  layout = "floating",
}) => {
  const formatTime = (ms) => (ms / 1000).toFixed(2);
  const stacked = layout === "stacked";

  return (
    <div
      className={
        stacked
          ? "relative z-20 flex flex-wrap items-center justify-center gap-2 w-full px-3 py-2 pointer-events-none shrink-0"
          : "absolute top-24 left-1/2 -translate-x-1/2 z-20 flex items-center gap-3 pointer-events-none w-full justify-center px-4"
      }
    >
      {/* Main Info Pill */}
      <div
        className={`bg-slate-900/80 backdrop-blur px-4 sm:px-6 py-2 rounded-2xl border border-slate-700 shadow-xl pointer-events-auto flex items-center gap-3 sm:gap-4 ${
          stacked ? "max-w-full" : ""
        }`}
      >
        <div className="min-w-0">
          <div className="text-cyan-400 text-[10px] font-bold tracking-widest uppercase leading-none mb-1 truncate">
            {title}
          </div>
          <div className="text-lg sm:text-xl font-bold flex flex-wrap items-center gap-2 sm:gap-4 leading-none text-white">
            <span>Lvl {level}</span>
            <div className="flex items-center gap-2 text-slate-400 font-mono text-sm sm:text-base sm:border-l sm:border-slate-700 sm:pl-4 sm:ml-2">
              <Timer size={16} className="shrink-0" /> {formatTime(elapsedTime)}s
            </div>
          </div>
        </div>

        {typeof progress !== "undefined" && typeof target !== "undefined" && (
          <>
            <div className="w-px h-8 bg-slate-700" /> {/* Vertical Divider */}
            <div>
              <div className="text-cyan-400 text-[10px] font-bold tracking-widest uppercase leading-none mb-1">
                {progressLabel}
              </div>
              <div className="text-xl font-bold text-white leading-none">
                {progress} / {target}
              </div>
            </div>
          </>
        )}

        {typeof lives === "number" && (
          <>
            <div className="w-px h-8 bg-slate-700 shrink-0" />
            <div className="flex items-center gap-0.5 text-lg leading-none">
              {[...Array(3)].map((_, i) => (
                <span key={i} className={i < lives ? "" : "opacity-25"}>
                  ❤️
                </span>
              ))}
            </div>
          </>
        )}
      </div>

      {/* Hint Button */}
      {gameState === "playing" && (
        <button
          onClick={onBuyHint}
          disabled={(!isFreeHint && coins < hintCost) || showHint}
          className={`
            pointer-events-auto px-4 py-2 rounded-xl font-bold flex items-center gap-2 border-2 transition-all shadow-xl h-[58px]
            ${
              isFreeHint || (coins >= hintCost && !showHint)
                ? "bg-slate-900/80 border-yellow-500 text-yellow-400 hover:bg-yellow-500 hover:text-slate-900 cursor-pointer"
                : "bg-slate-900/80 border-slate-700 text-slate-500 opacity-50 cursor-not-allowed"
            }
          `}
        >
          <HelpCircle size={20} />
          <div className="flex flex-col items-start leading-none">
            <span className="text-[10px] font-black uppercase">HINT</span>
            <span className="text-sm">
              {isFreeHint ? "FREE" : `${hintCost} 🪙`}
            </span>
          </div>
        </button>
      )}
    </div>
  );
};

export default GameHUD;
