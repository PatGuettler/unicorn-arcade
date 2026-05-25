import GlobalHeader from "./globalHeader";
import { User, Armchair } from "lucide-react";
import { FURNITURE } from "../../utils/storage";
import { LogOut } from "lucide-react";

const ProfileView = ({ user, data, onBack, onHome, handleLogout }) => {
  return (
    <div className="w-full h-screen bg-slate-950 flex flex-col animate-fade-in">
      <GlobalHeader
        coins={data?.coins || 0}
        onBack={onBack}
        onHome={onHome}
        isSubScreen={true}
        title="Profile"
      />

      <div className="flex-1 overflow-y-auto p-6">
        <div className="max-w-md mx-auto">
          {/* User Card */}
          <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 mb-8 shadow-xl">
            <div className="flex items-center gap-4 mb-6">
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
            onClick={handleLogout}
            className="w-full py-4 bg-slate-900 border border-slate-800 rounded-2xl text-rose-400 font-bold uppercase tracking-widest hover:bg-slate-800 hover:text-rose-300 transition-all flex items-center justify-center gap-2 mb-4"
          >
            <LogOut size={18} />
            Log Out
          </button>

          {/* Game Stats */}
          <h3 className="text-slate-400 font-bold uppercase text-sm mb-4 pl-2">
            Game Stats
          </h3>
          <div className="space-y-4 mb-8">
            {[
              "unicorn",
              "sliding",
              "coin",
              "cash",
              "spaceUnicorn",
              "mathSwipe",
              "mathtris",
            ].map((g) => (
              <div
                key={g}
                className="bg-slate-900 border border-slate-800 rounded-2xl p-6 flex justify-between items-center"
              >
                <h4 className="font-bold text-white capitalize">
                  {g === "unicorn"
                    ? "Unicorn Jump"
                    : g === "sliding"
                    ? "Sliding Window"
                    : g === "coin"
                    ? "Coin Count"
                    : g === "cash"
                    ? "Cash Counter"
                    : // : g === "spaceUnicorn"
                    // ? "Space Unicorn"
                    g === "mathSwipe"
                    ? "Math Swipe"
                    : g === "mathtris"
                    ? "Mathtris"
                    : "Unknown"}
                </h4>
                <div className="bg-slate-800 px-3 py-1 rounded-lg border border-slate-700">
                  <span className="text-slate-400 text-xs">MAX LVL</span>{" "}
                  <span className="text-white font-bold ml-1">
                    {data[g]?.maxLevel || 0}
                  </span>
                </div>
              </div>
            ))}
          </div>

          {/* Furniture Inventory */}
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
