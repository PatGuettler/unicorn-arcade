import React, { useState } from "react";
import { Lock } from "lucide-react";
import { UNICORNS } from "../../utils/storage";
import { UnicornAvatar } from "../assets/gameAssets";
import GlobalHeader from "../shared/globalHeader";
import alleyMap from "./unicornAlleyMap.jpeg";

const HOUSE_POSITIONS = [
  { top: "65%", left: "60%" }, // Sparkle
  { top: "80%", left: "82%" }, // Rainbow
  { top: "75%", left: "18%" }, // Star
  { top: "15%", left: "55%" }, // Cloud
  { top: "50%", left: "30%" }, // Dream
  { top: "80%", left: "45%" }, // Mystic
];

const UnicornAlleyView = ({ userData, onEnterRoom, onBack, onHome }) => {
  const handleHouseClick = (unicornId) => {
    if (userData.ownedUnicorns.includes(unicornId)) {
      onEnterRoom(unicornId);
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
              const pos = HOUSE_POSITIONS[index] || { top: "50%", left: "50%" };

              return (
                <div
                  key={u.id}
                  onClick={() => handleHouseClick(u.id)}
                  style={{ top: pos.top, left: pos.left }}
                  className="absolute w-24 h-24 -translate-x-1/2 -translate-y-1/2 flex flex-col items-center justify-center cursor-pointer group z-10"
                >
                  <div className="relative transition-transform duration-300 active:scale-95 group-hover:scale-110">
                    <div
                      className={`flex flex-col items-center transition-all duration-300 ${
                        isOwned ? "" : "grayscale opacity-70"
                      }`}
                    >
                      {/* Name Tag */}
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

                      {/* Avatar - Using the unicorn's actual image */}
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

                      {/* Locked Badge Overlay */}
                      {!isOwned && (
                        <div className="absolute bottom-6 -right-2 bg-slate-900 p-1.5 rounded-full border border-slate-600 shadow-lg z-20">
                          <Lock size={12} className="text-slate-400" />
                        </div>
                      )}

                      {/* "Enter" hint on hover (Only for owned) */}
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
    </div>
  );
};

export default UnicornAlleyView;
