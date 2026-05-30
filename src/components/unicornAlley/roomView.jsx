import React, { useState, useRef, useEffect, useMemo, useCallback } from "react";
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
  getBagItemsForRoom,
  filterByCategory,
  snapToGrid,
  sortByZIndex,
  getNextZIndex,
} from "../../utils/furnitureUtils";
import { UnicornAvatar } from "../assets/gameAssets";
import GlobalHeader from "../shared/globalHeader";
import { useRoomDrag } from "../../hooks/useRoomDrag";

function PlacedRoomItem({
  item,
  def,
  isSelected,
  isDragging,
  onSelect,
  onStartDrag,
  onRotate,
  onResizeStart,
  onRemove,
  onLayerBack,
  onLayerFront,
}) {
  const dragging = isDragging(item.instanceId);

  return (
    <div
      role="button"
      tabIndex={-1}
      data-room-item
      className={`absolute select-none touch-none ${
        dragging ? "cursor-grabbing z-[80]" : "cursor-grab z-[10]"
      } ${isSelected && !dragging ? "z-[70]" : ""}`}
      style={{
        left: `${item.x}%`,
        top: `${item.y}%`,
        transform: `translate3d(-50%, -50%, 0) rotate(${item.rotation ?? 0}deg) scale(${item.scale ?? 1})`,
        zIndex: dragging ? 80 : item.zIndex ?? 10,
        transition: dragging ? "none" : "box-shadow 0.15s ease",
        willChange: dragging ? "left, top, transform" : "auto",
      }}
      onPointerDown={(e) => {
        if (e.button !== 0) return;
        e.stopPropagation();
        onSelect(item.instanceId);
        onStartDrag(e, item.instanceId, "move");
      }}
      onClick={(e) => e.stopPropagation()}
    >
      {isSelected && (
        <div
          className="absolute -top-12 left-1/2 -translate-x-1/2 flex gap-1 z-50 bg-slate-900/95 rounded-full px-2 py-1 border border-slate-600 shadow-lg pointer-events-auto"
          onPointerDown={(e) => e.stopPropagation()}
        >
          <ToolbarBtn color="bg-rose-500" onClick={onRemove}>
            <X size={12} />
          </ToolbarBtn>
          <ToolbarBtn color="bg-blue-500" onClick={onRotate}>
            <RotateCw size={12} />
          </ToolbarBtn>
          <ToolbarBtn
            color="bg-emerald-500"
            onPointerDown={(e) => onResizeStart(e, item.instanceId)}
          >
            <Scaling size={12} />
          </ToolbarBtn>
          <ToolbarBtn color="bg-violet-600" onClick={onLayerBack}>
            <ChevronDown size={12} />
          </ToolbarBtn>
          <ToolbarBtn color="bg-violet-600" onClick={onLayerFront}>
            <ChevronUp size={12} />
          </ToolbarBtn>
        </div>
      )}

      <div
        className={`relative flex items-center justify-center ${
          def?.isCompanion ? "w-24 h-24" : "w-16 h-16"
        }`}
      >
        {def?.isCompanion && def.image ? (
          <UnicornAvatar
            image={def.image}
            className="w-full h-full pointer-events-none"
            style={{ transform: `scale(${def.scale ?? 1})` }}
          />
        ) : (
          <span className="text-5xl leading-none pointer-events-none drop-shadow-lg">
            {def?.icon}
          </span>
        )}
        {isSelected && (
          <div className="absolute inset-[-6px] border-2 border-cyan-400/90 rounded-xl pointer-events-none" />
        )}
      </div>
    </div>
  );
}

function ToolbarBtn({ color, onClick, onPointerDown, children }) {
  return (
    <button
      type="button"
      className={`${color} text-white rounded-full p-1.5 pointer-events-auto`}
      onClick={(e) => {
        e.stopPropagation();
        onClick?.(e);
      }}
      onPointerDown={(e) => {
        e.stopPropagation();
        onPointerDown?.(e);
      }}
    >
      {children}
    </button>
  );
}

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
  const canvasRef = useRef(null);

  const sortedPlacements = useMemo(
    () => sortByZIndex(userData.furniture.placements[unicornId] || []),
    [userData.furniture.placements, unicornId]
  );

  const commitItem = useCallback(
    (item) => onPlaceItem(unicornId, item),
    [unicornId, onPlaceItem]
  );

  const {
    items,
    setCanvasRect,
    startDrag,
    updateItemLocal,
    removeItem,
    isDragging,
  } = useRoomDrag({
    placements: sortedPlacements,
    gridSnap,
    onCommit: commitItem,
  });

  useEffect(() => {
    const el = canvasRef.current;
    if (!el) return;

    const measure = () => setCanvasRect(el.getBoundingClientRect());

    measure();
    const ro = new ResizeObserver(measure);
    ro.observe(el);
    window.addEventListener("resize", measure);

    return () => {
      ro.disconnect();
      window.removeEventListener("resize", measure);
    };
  }, [setCanvasRect, unicorn?.bgImage]);

  const bagItems = useMemo(() => {
    const all = getBagItemsForRoom(unicornId, userData.furniture);
    return filterByCategory(all, bagCategory === "all" ? "all" : bagCategory);
  }, [unicornId, userData.furniture, bagCategory]);

  const spawnItem = (itemId) => {
    if (getAvailableCount(itemId, userData.furniture) <= 0) return;
    const instanceId = `${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
    const instance = {
      instanceId,
      itemId,
      x: snapToGrid(50, gridSnap),
      y: snapToGrid(50, gridSnap),
      rotation: 0,
      scale: itemId.startsWith("companion_") ? 1.2 : 1,
      zIndex: getNextZIndex(items),
    };
    onPlaceItem(unicornId, instance);
    setSelectedId(instanceId);
    setIsBagOpen(false);
  };

  const handleRemove = (instanceId) => {
    removeItem(instanceId);
    onRemoveItem(unicornId, instanceId);
    if (selectedId === instanceId) setSelectedId(null);
  };

  const handleRotate = (instanceId) => {
    const item = items.find((i) => i.instanceId === instanceId);
    if (!item) return;
    const rotation = ((item.rotation ?? 0) + 45) % 360;
    updateItemLocal(instanceId, { rotation });
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
    <div className="w-full h-app bg-slate-950 flex flex-col overflow-hidden">
      <GlobalHeader
        coins={userData.coins}
        onBack={onBack}
        onHome={onHome}
        isSubScreen={true}
        title={`${unicorn?.name}'s Room`}
      />

      <div className="px-4 py-2 flex items-center justify-between gap-2 border-b border-slate-800/80 shrink-0">
        <button
          type="button"
          onPointerDown={(e) => e.stopPropagation()}
          onClick={() => setGridSnap((v) => !v)}
          className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold border ${
            gridSnap
              ? "bg-cyan-600/20 border-cyan-500 text-cyan-300"
              : "bg-slate-900 border-slate-700 text-slate-400"
          }`}
        >
          <Grid3x3 size={14} /> Grid Snap
        </button>
        <button
          type="button"
          onPointerDown={(e) => e.stopPropagation()}
          onClick={handleReset}
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

      <div className="flex-1 flex items-center justify-center p-2 min-h-0 overflow-hidden">
        <div
          className={`relative max-w-full max-h-full ${
            unicorn?.bgImage ? "rounded-2xl border border-slate-800 shadow-2xl" : "w-full h-full"
          }`}
          onPointerDown={(e) => e.stopPropagation()}
        >
          {unicorn?.bgImage ? (
            <img
              src={unicorn.bgImage}
              alt=""
              className="max-w-full max-h-[calc(100dvh-9rem)] w-auto h-auto block rounded-2xl object-contain pointer-events-none select-none"
              draggable={false}
            />
          ) : (
            <div
              className={`w-full h-full min-h-[280px] rounded-2xl ${unicorn?.style}`}
            />
          )}

          {/* Placement canvas — matches visible room bounds */}
          <div
            ref={canvasRef}
            className="absolute inset-0 overflow-hidden rounded-2xl touch-none"
            style={{ touchAction: "none" }}
            onPointerDown={(e) => {
              if (e.target === e.currentTarget) setSelectedId(null);
            }}
          >
            {items.map((item) => {
              const def = getFurnitureDef(item.itemId);
              return (
                <PlacedRoomItem
                  key={item.instanceId}
                  item={item}
                  def={def}
                  isSelected={selectedId === item.instanceId}
                  isDragging={isDragging}
                  onSelect={setSelectedId}
                  onStartDrag={startDrag}
                  onRotate={() => handleRotate(item.instanceId)}
                  onResizeStart={startDrag}
                  onRemove={() => handleRemove(item.instanceId)}
                  onLayerBack={() =>
                    onReorderItem(unicornId, item.instanceId, "back")
                  }
                  onLayerFront={() =>
                    onReorderItem(unicornId, item.instanceId, "front")
                  }
                />
              );
            })}
          </div>
        </div>
      </div>

      <div className="absolute bottom-safe right-4 z-50 pointer-events-auto">
        <button
          type="button"
          onPointerDown={(e) => e.stopPropagation()}
          onClick={() => setIsBagOpen(true)}
          className="w-16 h-16 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-full shadow-lg border-4 border-white/20 flex items-center justify-center text-yellow-950"
        >
          <Briefcase size={28} />
        </button>
      </div>

      {isBagOpen && (
        <div
          className="absolute inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-end"
          onPointerDown={() => setIsBagOpen(false)}
        >
          <div
            className="w-full bg-slate-900 rounded-t-3xl p-6 border-t border-slate-700 h-[65vh] flex flex-col"
            onPointerDown={(e) => e.stopPropagation()}
          >
            <div className="flex justify-between items-center mb-3">
              <div>
                <h2 className="text-white font-bold text-xl">Furniture Bag</h2>
                <p className="text-xs text-slate-500 mt-0.5">
                  {unicorn?.name} is a special item — place from your bag
                </p>
              </div>
              <button
                type="button"
                onClick={() => setIsBagOpen(false)}
                className="p-2 bg-slate-800 rounded-full text-white"
              >
                <X />
              </button>
            </div>

            <div className="flex gap-2 overflow-x-auto pb-3 mb-2 shrink-0">
              <button
                type="button"
                onClick={() => setBagCategory("all")}
                className={`shrink-0 px-2.5 py-1.5 rounded-lg text-[10px] font-bold border ${
                  bagCategory === "all"
                    ? "bg-cyan-600/20 border-cyan-500 text-cyan-300"
                    : "bg-slate-800 border-slate-700 text-slate-400"
                }`}
              >
                ✨ All
              </button>
              <button
                type="button"
                onClick={() => setBagCategory("companions")}
                className={`shrink-0 px-2.5 py-1.5 rounded-lg text-[10px] font-bold border ${
                  bagCategory === "companions"
                    ? "bg-cyan-600/20 border-cyan-500 text-cyan-300"
                    : "bg-slate-800 border-slate-700 text-slate-400"
                }`}
              >
                🦄 Companion
              </button>
              {FURNITURE_CATEGORIES.filter((c) => c.id !== "all").map((cat) => (
                <button
                  key={cat.id}
                  type="button"
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
            </div>

            <div className="grid grid-cols-3 gap-3 overflow-y-auto pb-8 flex-1 min-h-0">
              {bagItems.length === 0 ? (
                <p className="col-span-3 text-center text-slate-500 py-8 text-sm">
                  Nothing to place here. Buy decor in the Marketplace!
                </p>
              ) : (
                bagItems.map((f) => {
                  const available = getAvailableCount(f.id, userData.furniture);
                  return (
                    <button
                      key={f.id}
                      type="button"
                      onClick={() => spawnItem(f.id)}
                      className="p-3 rounded-xl border-2 bg-slate-800 border-slate-700 active:border-cyan-500 flex flex-col items-center gap-1 relative"
                    >
                      {f.isCompanion && f.image ? (
                        <div className="w-12 h-12">
                          <UnicornAvatar image={f.image} className="w-full h-full" />
                        </div>
                      ) : (
                        <div className="text-3xl">{f.icon}</div>
                      )}
                      <div className="text-[10px] text-slate-400 font-bold text-center leading-tight">
                        {f.name}
                      </div>
                      {f.isCompanion && (
                        <span className="text-[8px] text-pink-400 font-bold uppercase">
                          House gift
                        </span>
                      )}
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

export default RoomView;
