import React, { useState, useMemo } from "react";
import {
  Lock,
  Check,
  ShoppingCart,
  Armchair,
  Ghost,
  Search,
  Sparkles,
  Coins,
} from "lucide-react";
import { UNICORNS } from "../../utils/storage";
import {
  FURNITURE,
  FURNITURE_CATEGORIES,
  filterByCategory,
  searchFurniture,
  getAvailableCount,
  getPlacedCount,
  RARITY_STYLES,
  SELL_BACK_RATIO,
} from "../../utils/furnitureUtils";
import { UnicornAvatar } from "../assets/gameAssets";
import GlobalHeader from "./globalHeader";

const ShopView = ({
  userData,
  onBuy,
  onBuyFurniture,
  onSellFurniture,
  onEquip,
  onBack,
  onHome,
  onGoAlley,
}) => {
  const [tab, setTab] = useState("unicorns");
  const [decorCategory, setDecorCategory] = useState("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [toast, setToast] = useState(null);

  const filteredFurniture = useMemo(() => {
    let items = FURNITURE;
    items = filterByCategory(items, decorCategory);
    items = searchFurniture(items, searchQuery);
    return items;
  }, [decorCategory, searchQuery]);

  const showToast = (message, action) => {
    setToast({ message, action });
    setTimeout(() => setToast(null), 4000);
  };

  const handleBuyDecor = (item) => {
    if (userData.coins < item.price) return;
    onBuyFurniture(item.id, item.price);
    showToast(`You bought ${item.name}!`, "alley");
  };

  const handleSell = (item) => {
    const available = getAvailableCount(item.id, userData.furniture);
    if (available <= 0) return;
    onSellFurniture(item.id, Math.floor(item.price * SELL_BACK_RATIO));
  };

  return (
    <div className="w-full h-app bg-slate-950 flex flex-col relative">
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

      <div className="flex-1 min-h-0 overflow-y-auto p-6">
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
                  <p className="text-xs text-slate-500 text-center mb-2 px-1">
                    {item.desc}
                  </p>

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
          <div className="max-w-md mx-auto space-y-4">
            <div className="relative">
              <Search
                size={18}
                className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500"
              />
              <input
                type="search"
                placeholder="Search decor..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full bg-slate-900 border border-slate-800 rounded-xl py-3 pl-10 pr-4 text-white text-sm placeholder:text-slate-600"
              />
            </div>

            <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide">
              {FURNITURE_CATEGORIES.map((cat) => (
                <button
                  key={cat.id}
                  onClick={() => setDecorCategory(cat.id)}
                  className={`shrink-0 px-3 py-2 rounded-xl text-xs font-bold border transition-all ${
                    decorCategory === cat.id
                      ? "bg-cyan-600/20 border-cyan-500 text-cyan-300"
                      : "bg-slate-900 border-slate-800 text-slate-400"
                  }`}
                >
                  {cat.icon} {cat.label}
                </button>
              ))}
            </div>

            <div className="grid grid-cols-1 gap-4">
              {filteredFurniture.map((item) => {
                const canAfford = userData.coins >= item.price;
                const owned = userData.furniture.inventory[item.id] || 0;
                const placed = getPlacedCount(item.id, userData.furniture);
                const available = getAvailableCount(
                  item.id,
                  userData.furniture
                );
                const rarityClass =
                  RARITY_STYLES[item.rarity] || RARITY_STYLES.common;

                return (
                  <div
                    key={item.id}
                    className="bg-slate-900 rounded-3xl p-4 border-2 border-slate-800 flex gap-4"
                  >
                    <div className="text-5xl p-3 bg-slate-950 rounded-2xl border border-slate-800 shrink-0 self-start">
                      {item.icon}
                    </div>
                    <div className="flex-1 min-w-0 flex flex-col">
                      <div className="flex items-start gap-2 flex-wrap">
                        <h3 className="font-bold text-white">{item.name}</h3>
                        <span
                          className={`text-[10px] font-black uppercase px-2 py-0.5 rounded-full ${rarityClass}`}
                        >
                          {item.rarity || "common"}
                        </span>
                      </div>
                      <p className="text-xs text-slate-400 mt-1 leading-relaxed">
                        {item.desc}
                      </p>
                      <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mt-2 flex gap-3">
                        <span>
                          Owned:{" "}
                          <span className="text-cyan-400">{owned}</span>
                        </span>
                        <span>
                          Placed:{" "}
                          <span className="text-amber-400">{placed}</span>
                        </span>
                        <span>
                          Bag:{" "}
                          <span className="text-emerald-400">{available}</span>
                        </span>
                      </div>

                      <div className="flex gap-2 mt-3">
                        <button
                          onClick={() => handleBuyDecor(item)}
                          disabled={!canAfford}
                          className={`flex-1 py-2 rounded-xl font-bold flex items-center justify-center gap-2 text-sm ${
                            canAfford
                              ? "bg-yellow-500 text-yellow-950 hover:bg-yellow-400"
                              : "bg-slate-800 text-slate-500 cursor-not-allowed"
                          }`}
                        >
                          <ShoppingCart size={14} />
                          {item.price.toLocaleString()}
                        </button>
                        {available > 0 && (
                          <button
                            onClick={() => handleSell(item)}
                            className="px-3 py-2 rounded-xl font-bold text-sm bg-slate-800 text-slate-300 hover:bg-slate-700 flex items-center gap-1"
                            title={`Sell one for ${Math.floor(item.price * SELL_BACK_RATIO)} coins`}
                          >
                            <Coins size={14} />
                            Sell
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            {filteredFurniture.length === 0 && (
              <p className="text-center text-slate-500 py-8">
                No items match your search.
              </p>
            )}
          </div>
        )}
      </div>

      {toast && (
        <div className="absolute bottom-safe left-4 right-4 z-50 animate-fade-in">
          <div className="bg-slate-800 border border-cyan-500/40 rounded-2xl p-4 flex items-center justify-between gap-3 shadow-xl">
            <div className="flex items-center gap-2 text-white text-sm font-bold">
              <Sparkles size={18} className="text-cyan-400 shrink-0" />
              {toast.message}
            </div>
            {toast.action === "alley" && onGoAlley && (
              <button
                onClick={() => {
                  onGoAlley();
                  setToast(null);
                }}
                className="shrink-0 px-3 py-1.5 bg-cyan-600 text-white text-xs font-black rounded-lg"
              >
                Decorate
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default ShopView;
