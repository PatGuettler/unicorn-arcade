import Mathtris from "./Mathtris";
import { ArrowLeft, Home } from "lucide-react";

export default function MathtrisGame({ onExit, onHome }) {
  return (
    <div className="relative">
      <div className="fixed top-0 left-0 right-0 z-[500] flex items-center gap-2 p-3 pointer-events-none">
        <button
          type="button"
          onClick={onExit}
          className="pointer-events-auto p-2 rounded-full bg-slate-900/80 border border-white/20 text-white hover:bg-slate-800 transition-colors"
          aria-label="Back to games"
        >
          <ArrowLeft size={22} />
        </button>
        {onHome && (
          <button
            type="button"
            onClick={onHome}
            className="pointer-events-auto p-2 rounded-full bg-slate-900/80 border border-white/20 text-white hover:bg-slate-800 transition-colors"
            aria-label="Home"
          >
            <Home size={22} />
          </button>
        )}
      </div>
      <Mathtris />
    </div>
  );
}
