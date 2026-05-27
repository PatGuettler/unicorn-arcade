import { useState } from "react";
import GlobalHeader from "./globalHeader";
import { User, Armchair, LogOut, ChevronDown } from "lucide-react";
import { FURNITURE } from "../../utils/storage";
import {
  getProfileGameSections,
  getGameLevelSummary,
} from "../../games/gameConfig";

function formatTime(seconds) {
  if (seconds == null) return "—";
  return `${Number(seconds).toFixed(1)}s`;
}

function GameStatRow({ game, gameData }) {
  const { maxLevel, levels } = getGameLevelSummary(gameData);
  const [open, setOpen] = useState(false);
  const hasLevels = maxLevel > 0 || levels.length > 0;

  return (
    <div className="border border-slate-800 rounded-xl overflow-hidden bg-slate-950/50">
      <button
        type="button"
        onClick={() => hasLevels && setOpen((v) => !v)}
        className={`w-full flex items-center gap-3 px-4 py-3 text-left transition-colors ${
          hasLevels ? "hover:bg-slate-800/60 cursor-pointer" : "cursor-default"
        }`}
      >
        <span className="text-2xl shrink-0" aria-hidden>
          {game.icon}
        </span>
        <div className="flex-1 min-w-0">
          <div className="font-bold text-white truncate">{game.title}</div>
          {maxLevel > 0 && (
            <div className="text-xs text-slate-500 mt-0.5">
              {levels.length} run{levels.length === 1 ? "" : "s"} recorded
            </div>
          )}
        </div>
        <div className="flex items-center gap-2 shrink-0">
          <div className="bg-slate-800 px-2.5 py-1 rounded-lg border border-slate-700 text-center min-w-[4.5rem]">
            <div className="text-[10px] text-slate-500 uppercase tracking-wide">
              Max
            </div>
            <div className="text-white font-black text-lg leading-none">
              {maxLevel}
            </div>
          </div>
          {hasLevels && (
            <ChevronDown
              size={18}
              className={`text-slate-500 transition-transform ${
                open ? "rotate-180" : ""
              }`}
            />
          )}
        </div>
      </button>

      {open && hasLevels && (
        <div className="px-4 pb-3 pt-1 border-t border-slate-800/80">
          {maxLevel > 0 ? (
            <div className="flex flex-wrap gap-1.5 mb-2">
              {Array.from({ length: maxLevel }, (_, i) => i + 1).map((lvl) => {
                const run = levels.find((l) => l.level === lvl);
                return (
                  <span
                    key={lvl}
                    className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-xs font-bold ${
                      run
                        ? "bg-emerald-950/80 text-emerald-300 border border-emerald-800/60"
                        : "bg-slate-800 text-slate-400 border border-slate-700"
                    }`}
                  >
                    L{lvl}
                    {run && (
                      <span className="font-normal opacity-80">
                        {formatTime(run.time)}
                      </span>
                    )}
                  </span>
                );
              })}
            </div>
          ) : (
            <p className="text-xs text-slate-500">No levels completed yet.</p>
          )}

          {levels.length > 0 && (
            <div className="space-y-1 max-h-36 overflow-y-auto no-scrollbar">
              {[...levels].reverse().slice(0, 8).map((run) => (
                <div
                  key={`${run.level}-${run.time}`}
                  className="flex justify-between text-xs text-slate-400 px-1"
                >
                  <span>Level {run.level}</span>
                  <span className="font-mono text-slate-500">
                    {formatTime(run.time)}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function CategorySection({ section, data, defaultOpen }) {
  const [open, setOpen] = useState(defaultOpen);
  const gamesWithProgress = section.games.filter(
    (g) => (data?.[g.id]?.maxLevel || 0) > 0
  ).length;
  const totalMaxLevels = section.games.reduce(
    (sum, g) => sum + (data?.[g.id]?.maxLevel || 0),
    0
  );

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="w-full flex items-center gap-3 px-4 py-4 text-left hover:bg-slate-800/40 transition-colors"
      >
        <div
          className={`w-10 h-10 ${section.color} rounded-xl flex items-center justify-center text-slate-900 shrink-0`}
        >
          <section.icon size={22} />
        </div>
        <div className="flex-1 min-w-0">
          <div className="font-black text-white">{section.title}</div>
          <div className="text-xs text-slate-500 mt-0.5">
            {section.games.length} game{section.games.length === 1 ? "" : "s"}
            {gamesWithProgress > 0 && (
              <span>
                {" "}
                · {gamesWithProgress} started · {totalMaxLevels} total levels
              </span>
            )}
          </div>
        </div>
        <ChevronDown
          size={20}
          className={`text-slate-400 shrink-0 transition-transform ${
            open ? "rotate-180" : ""
          }`}
        />
      </button>

      {open && (
        <div className="px-3 pb-3 space-y-2 border-t border-slate-800">
          {section.games.map((game) => (
            <GameStatRow key={game.id} game={game} gameData={data?.[game.id]} />
          ))}
        </div>
      )}
    </div>
  );
}

const ProfileView = ({ user, data, onBack, onHome, handleLogout }) => {
  const sections = getProfileGameSections();

  return (
    <div className="w-full h-app bg-slate-950 flex flex-col animate-fade-in">
      <GlobalHeader
        coins={data?.coins || 0}
        onBack={onBack}
        onHome={onHome}
        isSubScreen={true}
        title="Profile"
      />

      <div className="flex-1 overflow-y-auto p-6 pb-safe">
        <div className="max-w-md mx-auto">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 mb-6 shadow-xl">
            <div className="flex items-center gap-4">
              <div className="w-16 h-16 bg-slate-800 rounded-full flex items-center justify-center border-2 border-cyan-500/30">
                <User size={32} className="text-cyan-400" />
              </div>
              <div>
                <h2 className="text-2xl font-black text-white">{user}</h2>
                <p className="text-emerald-400 text-xs font-bold uppercase tracking-wider">
                  PRO MEMBER
                </p>
              </div>
            </div>
          </div>

          <button
            type="button"
            onClick={handleLogout}
            className="w-full py-4 bg-slate-900 border border-slate-800 rounded-2xl text-rose-400 font-bold uppercase tracking-widest hover:bg-slate-800 hover:text-rose-300 transition-all flex items-center justify-center gap-2 mb-8"
          >
            <LogOut size={18} />
            Log Out
          </button>

          <h3 className="text-slate-400 font-bold uppercase text-sm mb-4 pl-2">
            Game Progress
          </h3>
          <div className="space-y-3 mb-8">
            {sections.map((section, i) => (
              <CategorySection
                key={section.id}
                section={section}
                data={data}
                defaultOpen={i === 0}
              />
            ))}
          </div>

          <h3 className="text-slate-400 font-bold uppercase text-sm mb-4 pl-2 flex items-center gap-2">
            <Armchair size={16} /> Inventory
          </h3>
          <div className="bg-slate-900 border border-slate-800 rounded-2xl p-4">
            {Object.keys(data?.furniture?.inventory || {}).length === 0 ? (
              <div className="text-center text-slate-600 py-4">
                No items purchased yet.
              </div>
            ) : (
              <div className="grid grid-cols-4 gap-4">
                {Object.entries(data.furniture.inventory).map(([id, count]) => {
                  const item = FURNITURE.find((f) => f.id === id);
                  if (!item || count === 0) return null;
                  return (
                    <div key={id} className="flex flex-col items-center">
                      <div className="text-3xl mb-1">{item.icon}</div>
                      <div className="text-[10px] font-bold text-slate-500">
                        x{count}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProfileView;
