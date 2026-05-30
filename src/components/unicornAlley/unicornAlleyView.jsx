import React, { useState } from "react";
import { Lock, ShoppingBag } from "lucide-react";
import { UNICORNS } from "../../utils/storage";
import { getRoomDecorCount } from "../../utils/furnitureUtils";
import { UnicornAvatar } from "../assets/gameAssets";
import GlobalHeader from "../shared/globalHeader";
import alleyMap from "./unicornAlleyMap.jpeg";

const HOUSE_POSITIONS = [
  { top: "65%", left: "60%" },
  { top: "80%", left: "82%" },
  { top: "75%", left: "18%" },
  { top: "15%", left: "55%" },
  { top: "50%", left: "30%" },
  { top: "80%", left: "45%" },
];

const UnicornAlleyView = ({
  userData,
  onEnterRoom,
  onShop,
  onBack,
  onHome,
}) => {
  const [lockedPrompt, setLockedPrompt] = useState(null);

  const handleHouseClick = (unicorn) => {
    if (userData.ownedUnicorns.includes(unicorn.id)) {
      onEnterRoom(unicorn.id);
    } else {
      setLockedPrompt(unicorn);
    }
  };

  return (
    <div className="w-full h-app bg-slate-950 flex flex-col relative overflow-hidden">
      <GlobalHeader
        coins={userData.coins}
        onBack={onBack}
        onHome={onHome}
        isSubScreen={true}
        title="Unicorn Alley"
      />

      <div className="flex-1 flex items-center justify-center p-4 overflow-hidden w-full h-full">
        <div className="relative shadow-2xl rounded-2xl border border-slate-800 bg-slate-900">
          <img
            src={alleyMap}
            alt="Unicorn Alley Map"
            className="max-w-full max-h-[calc(100vh-8rem)] w-auto h-auto block rounded-2xl object-contain pointer-events-none select-none"
          />

          <div className="absolute inset-0">
            {UNICORNS.map((u, index) => {
              const isOwned = userData.ownedUnicorns.includes(u.id);
              const decorCount = getRoomDecorCount(
                userData.furniture.placements,
                u.id
              );
              const pos = HOUSE_POSITIONS[index] || { top: "50%", left: "50%" };

              return (
                <div
                  key={u.id}
                  onClick={() => handleHouseClick(u)}
                  style={{ top: pos.top, left: pos.left }}
                  className="absolute w-24 h-24 -translate-x-1/2 -translate-y-1/2 flex flex-col items-center justify-center cursor-pointer group z-10"
                >
                  <div className="relative transition-transform duration-300 active:scale-95 group-hover:scale-110">
                    <div
                      className={`flex flex-col items-center transition-all duration-300 ${
                        isOwned ? "" : "grayscale opacity-70"
                      }`}
                    >
                      <div
                        className={`
                        mb-1 px-2 py-0.5 rounded-full backdrop-blur border text-[10px] font-bold uppercase tracking-wider shadow-lg whitespace-nowrap
                        ${
                          isOwned
                            ? `bg-slate-900/80 border-white/20 ${u.accent}`
                            : "bg-slate-900/90 border-slate-700 text-slate-500"
                        }
                      `}
                      >
                        {u.name}
                      </div>

                      <div
                        className={`w-32 h-32 filter drop-shadow-2xl overflow-visible ${
                          isOwned ? "animate-float" : ""
                        }`}
                      >
                        <UnicornAvatar
                          image={u.image}
                          className="w-full h-full"
                          style={{
                            transform: `scale(${u.scale ?? 1})`,
                          }}
                        />
                      </div>

                      {!isOwned && (
                        <div className="absolute bottom-6 -right-2 bg-slate-900 p-1.5 rounded-full border border-slate-600 shadow-lg z-20">
                          <Lock size={12} className="text-slate-400" />
                        </div>
                      )}

                      {isOwned && decorCount > 0 && (
                        <div className="absolute -top-1 -right-1 bg-cyan-600 text-white text-[10px] font-black min-w-[1.25rem] h-5 px-1 rounded-full flex items-center justify-center border-2 border-slate-900 z-20">
                          {decorCount}
                        </div>
                      )}

                      {isOwned && (
                        <div className="absolute -bottom-6 opacity-0 group-hover:opacity-100 transition-opacity bg-white text-slate-900 text-[10px] font-black px-2 py-1 rounded-full whitespace-nowrap shadow-lg z-20">
                          ENTER HOUSE
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {lockedPrompt && (
        <div
          className="absolute inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-6"
          onClick={() => setLockedPrompt(null)}
        >
          <div
            className="bg-slate-900 border border-slate-700 rounded-3xl p-6 max-w-sm w-full shadow-2xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex justify-center mb-4">
              <div className="w-20 h-20 grayscale opacity-80">
                <UnicornAvatar
                  image={lockedPrompt.image}
                  className="w-full h-full"
                />
              </div>
            </div>
            <h3 className="text-white font-bold text-xl text-center">
              {lockedPrompt.name}&apos;s House
            </h3>
            <p className="text-slate-400 text-sm text-center mt-2">
              Adopt {lockedPrompt.name} in the Marketplace to unlock this room
              and start decorating!
            </p>
            <p className="text-center text-yellow-400 font-black text-lg mt-3">
              {lockedPrompt.price.toLocaleString()} coins
            </p>
            <div className="flex gap-3 mt-6">
              <button
                onClick={() => setLockedPrompt(null)}
                className="flex-1 py-3 rounded-xl bg-slate-800 text-slate-300 font-bold text-sm"
              >
                Close
              </button>
              <button
                onClick={() => {
                  onShop?.(lockedPrompt.id);
                  setLockedPrompt(null);
                }}
                className="flex-1 py-3 rounded-xl bg-yellow-500 text-yellow-950 font-bold text-sm flex items-center justify-center gap-2"
              >
                <ShoppingBag size={16} />
                Shop
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default UnicornAlleyView;
