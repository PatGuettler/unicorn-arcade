import React, { useState } from "react";
import { Lock, Check, ShoppingCart, Armchair, Ghost } from "lucide-react";
import { UNICORNS, FURNITURE } from "../../utils/storage";
import { UnicornAvatar } from "../assets/gameAssets";
import GlobalHeader from "./globalHeader";

const ShopView = ({
  userData,
  onBuy,
  onBuyFurniture,
  onEquip,
  onBack,
  onHome,
}) => {
  const [tab, setTab] = useState("unicorns");

  return (
    <div className="w-full h-app bg-slate-950 flex flex-col">
      <GlobalHeader
        coins={userData.coins}
        onBack={onBack}
        onHome={onHome}
        isSubScreen={true}
        title="Marketplace"
      />

      <div className="px-6 pt-4">
        <div className="flex bg-slate-900 p-1 rounded-2xl border border-slate-800">
          <button
            onClick={() => setTab("unicorns")}
            className={`flex-1 py-3 rounded-xl font-bold text-sm flex items-center justify-center gap-2 transition-all ${
              tab === "unicorns"
                ? "bg-slate-800 text-white shadow-lg"
                : "text-slate-500 hover:text-slate-300"
            }`}
          >
            <Ghost size={16} /> Companions
          </button>
          <button
            onClick={() => setTab("furniture")}
            className={`flex-1 py-3 rounded-xl font-bold text-sm flex items-center justify-center gap-2 transition-all ${
              tab === "furniture"
                ? "bg-slate-800 text-white shadow-lg"
                : "text-slate-500 hover:text-slate-300"
            }`}
          >
            <Armchair size={16} /> Decor
          </button>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-6">
        {tab === "unicorns" && (
          <div className="grid grid-cols-2 gap-4 max-w-md mx-auto">
            {UNICORNS.map((item) => {
              const isOwned = userData.ownedUnicorns.includes(item.id);
              const isEquipped = userData.equippedUnicorn === item.id;
              const canAfford = userData.coins >= item.price;

              return (
                <div
                  key={item.id}
                  className={`relative bg-slate-900 rounded-3xl p-4 border-2 flex flex-col items-center transition-all ${
                    isEquipped
                      ? "border-emerald-500 shadow-[0_0_20px_rgba(16,185,129,0.2)]"
                      : "border-slate-800"
                  }`}
                >
                  <div className="w-24 h-24 mb-4">
                    <UnicornAvatar
                      image={item.image}
                      className="w-full h-full"
                      style={{
                        transform: `scale(${item.scale || 1})`,
                      }}
                    />
                  </div>
                  <h3 className="font-bold text-white mb-1">{item.name}</h3>

                  <div className="mt-auto w-full pt-4">
                    {isOwned ? (
                      <button
                        onClick={() => !isEquipped && onEquip(item.id)}
                        className={`w-full py-2 rounded-xl font-bold flex items-center justify-center gap-2 ${
                          isEquipped
                            ? "bg-emerald-500/10 text-emerald-400 cursor-default"
                            : "bg-slate-800 text-white hover:bg-slate-700"
                        }`}
                      >
                        {isEquipped ? (
                          <>
                            <Check size={16} /> EQUIPPED
                          </>
                        ) : (
                          "EQUIP"
                        )}
                      </button>
                    ) : (
                      <button
                        onClick={() => canAfford && onBuy(item.id, item.price)}
                        disabled={!canAfford}
                        className={`w-full py-2 rounded-xl font-bold flex items-center justify-center gap-2 ${
                          canAfford
                            ? "bg-yellow-500 text-yellow-950 hover:bg-yellow-400"
                            : "bg-slate-800 text-slate-500 cursor-not-allowed"
                        }`}
                      >
                        {canAfford ? (
                          <ShoppingCart size={16} />
                        ) : (
                          <Lock size={16} />
                        )}
                        {item.price > 0 ? item.price.toLocaleString() : "FREE"}
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {tab === "furniture" && (
          <div className="grid grid-cols-2 gap-4 max-w-md mx-auto">
            {FURNITURE.map((item) => {
              const canAfford = userData.coins >= item.price;
              const count = userData.furniture.inventory[item.id] || 0;

              return (
                <div
                  key={item.id}
                  className="bg-slate-900 rounded-3xl p-4 border-2 border-slate-800 flex flex-col items-center"
                >
                  <div className="text-6xl mb-4 p-4 bg-slate-950 rounded-2xl border border-slate-800">
                    {item.icon}
                  </div>
                  <h3 className="font-bold text-white mb-1">{item.name}</h3>
                  <div className="text-xs text-slate-500 font-bold uppercase tracking-wider mb-4">
                    Owned: <span className="text-cyan-400">{count}</span>
                  </div>

                  <button
                    onClick={() =>
                      canAfford && onBuyFurniture(item.id, item.price)
                    }
                    disabled={!canAfford}
                    className={`mt-auto w-full py-2 rounded-xl font-bold flex items-center justify-center gap-2 ${
                      canAfford
                        ? "bg-yellow-500 text-yellow-950 hover:bg-yellow-400"
                        : "bg-slate-800 text-slate-500 cursor-not-allowed"
                    }`}
                  >
                    <ShoppingCart size={16} />
                    {item.price.toLocaleString()}
                  </button>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};

export default ShopView;
