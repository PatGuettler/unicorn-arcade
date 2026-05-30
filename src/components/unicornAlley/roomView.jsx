import React, { useState, useRef, useEffect, useMemo } from "react";
import {
  Briefcase,
  X,
  RotateCw,
  Scaling,
  Grid3x3,
  Trash2,
  ChevronUp,
  ChevronDown,
} from "lucide-react";
import { UNICORNS } from "../../utils/storage";
import {
  FURNITURE_CATEGORIES,
  getFurnitureDef,
  getAvailableCount,
  getOwnedFurniture,
  filterByCategory,
  snapToGrid,
  sortByZIndex,
  getNextZIndex,
} from "../../utils/furnitureUtils";
import { UnicornAvatar } from "../assets/gameAssets";
import GlobalHeader from "../shared/globalHeader";

const RoomView = ({
  unicornId,
  userData,
  onPlaceItem,
  onRemoveItem,
  onReorderItem,
  onResetRoom,
  onBack,
  onHome,
}) => {
  const [isBagOpen, setIsBagOpen] = useState(false);
  const [bagCategory, setBagCategory] = useState("all");
  const [gridSnap, setGridSnap] = useState(true);
  const [selectedId, setSelectedId] = useState(null);
  const [confirmReset, setConfirmReset] = useState(false);

  const unicorn = UNICORNS.find((u) => u.id === unicornId);
  const roomContainerRef = useRef(null);

  const placedItems = useMemo(
    () => sortByZIndex(userData.furniture.placements[unicornId] || []),
    [userData.furniture.placements, unicornId]
  );

  const ownedInBag = useMemo(() => {
    const owned = getOwnedFurniture(userData.furniture);
    return filterByCategory(owned, bagCategory).filter(
      (f) => getAvailableCount(f.id, userData.furniture) > 0
    );
  }, [userData.furniture, bagCategory]);

  const spawnItem = (itemId) => {
    if (getAvailableCount(itemId, userData.furniture) <= 0) return;
    const instanceId = Date.now().toString();
    const x = snapToGrid(50, gridSnap);
    const y = snapToGrid(50, gridSnap);
    onPlaceItem(unicornId, {
      instanceId,
      itemId,
      x,
      y,
      rotation: 0,
      scale: 1,
      zIndex: getNextZIndex(placedItems),
    });
    setSelectedId(instanceId);
    setIsBagOpen(false);
  };

  const handleReset = () => {
    if (!confirmReset) {
      setConfirmReset(true);
      return;
    }
    onResetRoom(unicornId);
    setConfirmReset(false);
    setSelectedId(null);
  };

  return (
    <div
      className="w-full h-app bg-slate-950 flex flex-col overflow-hidden"
      onClick={() => setSelectedId(null)}
    >
      <GlobalHeader
        coins={userData.coins}
        onBack={onBack}
        onHome={onHome}
        isSubScreen={true}
        title={`${unicorn?.name}'s Room`}
      />

      <div className="px-4 py-2 flex items-center justify-between gap-2 border-b border-slate-800/80">
        <button
          onClick={(e) => {
            e.stopPropagation();
            setGridSnap((v) => !v);
          }}
          className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold border ${
            gridSnap
              ? "bg-cyan-600/20 border-cyan-500 text-cyan-300"
              : "bg-slate-900 border-slate-700 text-slate-400"
          }`}
        >
          <Grid3x3 size={14} /> Grid Snap
        </button>
        <button
          onClick={(e) => {
            e.stopPropagation();
            handleReset();
          }}
          className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold border ${
            confirmReset
              ? "bg-rose-600/30 border-rose-500 text-rose-300"
              : "bg-slate-900 border-slate-700 text-slate-400"
          }`}
        >
          <Trash2 size={14} />
          {confirmReset ? "Confirm Reset?" : "Reset Room"}
        </button>
      </div>

      <div className="flex-1 flex items-center justify-center p-1 overflow-hidden w-full h-full relative">
        <div
          ref={roomContainerRef}
          className={`relative shadow-2xl ${
            unicorn?.bgImage
              ? "rounded-2xl border border-slate-800 bg-slate-900"
              : "w-full h-full"
          }`}
          onClick={(e) => e.stopPropagation()}
        >
          {unicorn?.bgImage ? (
            <img
              src={unicorn.bgImage}
              alt="Room"
              style={{ backgroundColor: "#0f172a" }}
              className="max-w-full max-h-[calc(100vh-8rem)] w-auto h-auto block rounded-2xl object-contain pointer-events-none select-none"
            />
          ) : (
            <div className={`absolute inset-0 ${unicorn?.style} opacity-100`}>
              <div className="absolute bottom-0 w-full h-1/3 bg-white/5 backdrop-blur-sm border-t border-white/10" />
            </div>
          )}

          {unicorn?.image && (
            <div
              className="absolute bottom-[12%] left-1/2 -translate-x-1/2 w-28 h-28 z-[5] pointer-events-none drop-shadow-2xl"
              style={{ transform: "translateX(-50%)" }}
            >
              <UnicornAvatar
                image={unicorn.image}
                className="w-full h-full animate-float"
                style={{ transform: `scale(${unicorn.scale ?? 1})` }}
              />
            </div>
          )}

          <div className="absolute inset-0 overflow-hidden rounded-2xl">
            {placedItems.map((item) => {
              const def = getFurnitureDef(item.itemId);
              const isSelected = selectedId === item.instanceId;
              return (
                <DraggableItem
                  key={item.instanceId}
                  def={def}
                  data={item}
                  isSelected={isSelected}
                  gridSnap={gridSnap}
                  containerRef={roomContainerRef}
                  onSelect={() => setSelectedId(item.instanceId)}
                  onSave={(updates) =>
                    onPlaceItem(unicornId, { ...item, ...updates })
                  }
                  onRemove={() => {
                    onRemoveItem(unicornId, item.instanceId);
                    if (selectedId === item.instanceId) setSelectedId(null);
                  }}
                  onSendBack={() =>
                    onReorderItem(unicornId, item.instanceId, "back")
                  }
                  onBringFront={() =>
                    onReorderItem(unicornId, item.instanceId, "front")
                  }
                />
              );
            })}
          </div>
        </div>
      </div>

      <div className="absolute bottom-safe right-4 z-50">
        <button
          onClick={(e) => {
            e.stopPropagation();
            setIsBagOpen(true);
          }}
          className="w-16 h-16 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-full shadow-lg border-4 border-white/20 flex items-center justify-center text-yellow-950 animate-bounce"
        >
          <Briefcase size={28} />
        </button>
      </div>

      {isBagOpen && (
        <div
          className="absolute inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-end animate-fade-in"
          onClick={() => setIsBagOpen(false)}
        >
          <div
            className="w-full bg-slate-900 rounded-t-3xl p-6 border-t border-slate-700 h-[65vh] flex flex-col"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-white font-bold text-xl">Furniture Bag</h2>
              <button
                onClick={() => setIsBagOpen(false)}
                className="p-2 bg-slate-800 rounded-full text-white"
              >
                <X />
              </button>
            </div>

            <div className="flex gap-2 overflow-x-auto pb-3 mb-2">
              {FURNITURE_CATEGORIES.filter((c) => c.id !== "all").map((cat) => (
                <button
                  key={cat.id}
                  onClick={() => setBagCategory(cat.id)}
                  className={`shrink-0 px-2.5 py-1.5 rounded-lg text-[10px] font-bold border ${
                    bagCategory === cat.id
                      ? "bg-cyan-600/20 border-cyan-500 text-cyan-300"
                      : "bg-slate-800 border-slate-700 text-slate-400"
                  }`}
                >
                  {cat.icon} {cat.label}
                </button>
              ))}
              <button
                onClick={() => setBagCategory("all")}
                className={`shrink-0 px-2.5 py-1.5 rounded-lg text-[10px] font-bold border ${
                  bagCategory === "all"
                    ? "bg-cyan-600/20 border-cyan-500 text-cyan-300"
                    : "bg-slate-800 border-slate-700 text-slate-400"
                }`}
              >
                ✨ All
              </button>
            </div>

            <div className="grid grid-cols-3 gap-3 overflow-y-auto pb-8">
              {ownedInBag.length === 0 ? (
                <p className="col-span-3 text-center text-slate-500 py-8 text-sm">
                  No items in this category. Visit the Marketplace Decor tab!
                </p>
              ) : (
                ownedInBag.map((f) => {
                  const available = getAvailableCount(
                    f.id,
                    userData.furniture
                  );
                  return (
                    <button
                      key={f.id}
                      onClick={() => spawnItem(f.id)}
                      className="p-3 rounded-xl border-2 bg-slate-800 border-slate-700 active:border-cyan-500 flex flex-col items-center gap-1 relative"
                    >
                      <div className="text-3xl">{f.icon}</div>
                      <div className="text-[10px] text-slate-400 font-bold text-center leading-tight">
                        {f.name}
                      </div>
                      <div className="absolute top-1 right-1 text-[10px] font-black px-1.5 py-0.5 rounded-full bg-emerald-500 text-emerald-950">
                        x{available}
                      </div>
                    </button>
                  );
                })
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

const DraggableItem = ({
  def,
  data,
  isSelected,
  gridSnap,
  onSelect,
  onSave,
  onRemove,
  onSendBack,
  onBringFront,
  containerRef,
}) => {
  const [pos, setPos] = useState({ x: data.x, y: data.y });
  const [rotation, setRotation] = useState(data.rotation || 0);
  const [scale, setScale] = useState(data.scale || 1);
  const [mode, setMode] = useState("none");

  const startRef = useRef({ x: 0, y: 0, valX: 0, valY: 0, initialScale: 1 });

  useEffect(() => {
    setPos({ x: data.x, y: data.y });
    setRotation(data.rotation || 0);
    setScale(data.scale || 1);
  }, [data]);

  const handleStart = (e, interactionMode = "moving") => {
    e.stopPropagation();
    onSelect();
    const clientX = e.touches ? e.touches[0].clientX : e.clientX;
    const clientY = e.touches ? e.touches[0].clientY : e.clientY;

    setMode(interactionMode);
    startRef.current = {
      x: clientX,
      y: clientY,
      valX: pos.x,
      valY: pos.y,
      initialScale: scale,
    };
  };

  const handleMove = (e) => {
    if (mode === "none" || !containerRef.current) return;
    e.stopPropagation();

    const clientX = e.touches ? e.touches[0].clientX : e.clientX;
    const clientY = e.touches ? e.touches[0].clientY : e.clientY;
    const rect = containerRef.current.getBoundingClientRect();

    if (mode === "moving") {
      const dX = clientX - startRef.current.x;
      const dY = clientY - startRef.current.y;
      const dXPercent = (dX / rect.width) * 100;
      const dYPercent = (dY / rect.height) * 100;

      let newX = Math.max(0, Math.min(95, startRef.current.valX + dXPercent));
      let newY = Math.max(0, Math.min(95, startRef.current.valY + dYPercent));
      newX = snapToGrid(newX, gridSnap);
      newY = snapToGrid(newY, gridSnap);

      setPos({ x: newX, y: newY });
    } else if (mode === "resizing") {
      const dX = clientX - startRef.current.x;
      const scaleDelta = dX * 0.005;
      const newScale = Math.max(
        0.5,
        Math.min(3, startRef.current.initialScale + scaleDelta)
      );
      setScale(newScale);
    }
  };

  const handleEnd = () => {
    if (mode !== "none") {
      setMode("none");
      onSave({ x: pos.x, y: pos.y, rotation, scale, zIndex: data.zIndex });
    }
  };

  const handleRotate = (e) => {
    e.stopPropagation();
    const newRotation = (rotation + 45) % 360;
    setRotation(newRotation);
    onSave({ x: pos.x, y: pos.y, rotation: newRotation, scale, zIndex: data.zIndex });
  };

  const showControls = isSelected;

  return (
    <div
      className={`absolute flex flex-col items-center justify-center w-16 h-16 select-none cursor-move transition-all
      ${mode !== "none" ? "z-[60]" : ""}`}
      style={{
        left: `${pos.x}%`,
        top: `${pos.y}%`,
        transform: `translate(-50%, -50%) rotate(${rotation}deg) scale(${scale})`,
        zIndex: data.zIndex ?? 10,
      }}
      onClick={(e) => {
        e.stopPropagation();
        onSelect();
      }}
      onTouchStart={(e) => handleStart(e, "moving")}
      onMouseDown={(e) => handleStart(e, "moving")}
      onTouchMove={handleMove}
      onMouseMove={handleMove}
      onTouchEnd={handleEnd}
      onMouseUp={handleEnd}
      onMouseLeave={handleEnd}
    >
      <div className="text-5xl drop-shadow-xl filter relative">
        {def?.icon}
        <div
          className={`absolute inset-[-10px] border-2 rounded-lg pointer-events-none transition-colors ${
            showControls ? "border-cyan-400/80" : "border-white/0"
          }`}
        />
      </div>

      {showControls && (
        <div className="absolute -top-14 left-1/2 -translate-x-1/2 flex gap-1 z-40 bg-slate-900/95 rounded-full px-2 py-1 border border-slate-600 shadow-lg">
          <button
            type="button"
            className="bg-rose-500 text-white rounded-full p-1.5"
            onMouseDown={(e) => {
              e.stopPropagation();
              onRemove();
            }}
            onTouchStart={(e) => {
              e.stopPropagation();
              onRemove();
            }}
          >
            <X size={12} />
          </button>
          <button
            type="button"
            className="bg-blue-500 text-white rounded-full p-1.5"
            onMouseDown={handleRotate}
            onTouchStart={handleRotate}
          >
            <RotateCw size={12} />
          </button>
          <button
            type="button"
            className="bg-emerald-500 text-white rounded-full p-1.5"
            onMouseDown={(e) => handleStart(e, "resizing")}
            onTouchStart={(e) => handleStart(e, "resizing")}
          >
            <Scaling size={12} />
          </button>
          <button
            type="button"
            className="bg-violet-600 text-white rounded-full p-1.5"
            onMouseDown={(e) => {
              e.stopPropagation();
              onSendBack();
            }}
            onTouchStart={(e) => {
              e.stopPropagation();
              onSendBack();
            }}
            title="Send to back"
          >
            <ChevronDown size={12} />
          </button>
          <button
            type="button"
            className="bg-violet-600 text-white rounded-full p-1.5"
            onMouseDown={(e) => {
              e.stopPropagation();
              onBringFront();
            }}
            onTouchStart={(e) => {
              e.stopPropagation();
              onBringFront();
            }}
            title="Bring to front"
          >
            <ChevronUp size={12} />
          </button>
        </div>
      )}
    </div>
  );
};

export default RoomView;
