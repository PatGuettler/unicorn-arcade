import React from "react";
import { Trophy, AlertTriangle, RotateCcw, CheckCircle } from "lucide-react";

const VictoryModal = ({
  state,
  failReason,
  time,
  coinsEarned,
  onAction,
  isNext,
}) => {
  return (
    <div className="absolute inset-0 bg-slate-950/90 backdrop-blur-sm flex flex-col items-center justify-center z-50 animate-in fade-in zoom-in">
      <div className="bg-slate-900 border border-slate-700 p-8 rounded-3xl shadow-2xl text-center max-w-sm w-full mx-4">
        {state === "failed" ? (
          <AlertTriangle className="w-16 h-16 text-rose-500 mx-auto mb-4" />
        ) : (
          <Trophy className="w-16 h-16 text-yellow-400 mx-auto mb-4 animate-bounce" />
        )}

        <h2 className="text-4xl font-black text-white mb-2">
          {state === "failed" ? "OOPS!" : "COMPLETE!"}
        </h2>

        {state !== "failed" && coinsEarned > 0 && (
          <div className="bg-slate-950/50 rounded-xl p-4 mb-6 border border-yellow-500/30">
            <div className="text-slate-400 text-xs font-bold uppercase tracking-wider mb-1">
              Rewards
            </div>
            <div className="text-3xl font-black text-yellow-400 flex items-center justify-center gap-2">
              <span>+ {coinsEarned}</span> 🪙
            </div>
          </div>
        )}

        <p className="text-slate-400 font-mono mb-8 text-sm">
          {state === "failed" ? failReason : `Time: ${time}s`}
        </p>

        <button
          onClick={onAction}
          className="w-full py-4 bg-white text-slate-900 font-black rounded-xl hover:scale-105 shadow-xl flex items-center justify-center gap-2 transition-transform"
        >
          {state === "failed" ? <RotateCcw /> : <CheckCircle />}{" "}
          {state === "failed" ? "TRY AGAIN" : isNext ? "NEXT LEVEL" : "FINISH"}
        </button>
      </div>
    </div>
  );
};

export default VictoryModal;
