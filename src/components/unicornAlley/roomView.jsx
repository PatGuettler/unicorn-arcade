// components/unicornAlley/roomView.jsx
import React, { useState, useRef, useEffect } from "react";
import { Briefcase, X, RotateCw, Scaling } from "lucide-react";
import { UNICORNS, FURNITURE } from "../../utils/storage";
import GlobalHeader from "../shared/globalHeader";

const RoomView = ({
  unicornId,
  userData,
  onPlaceItem,
  onRemoveItem,
  onBack,
  onHome,
}) => {
  const [isBagOpen, setIsBagOpen] = useState(false);
  const unicorn = UNICORNS.find((u) => u.id === unicornId);

  const roomContainerRef = useRef(null);
  const placedItems = userData.furniture.placements[unicornId] || [];

  const getAvailableCount = (itemId) => {
    const totalPurchased = userData.furniture.inventory[itemId] || 0;
    let totalPlaced = 0;
    Object.values(userData.furniture.placements).forEach((roomItems) => {
      roomItems.forEach((i) => {
        if (i.itemId === itemId) totalPlaced++;
      });
    });
    return Math.max(0, totalPurchased - totalPlaced);
  };

  const spawnItem = (itemId) => {
    if (getAvailableCount(itemId) > 0) {
      const instanceId = Date.now().toString();
      onPlaceItem(unicornId, {
        instanceId,
        itemId,
        x: 50,
        y: 50,
        rotation: 0,
        scale: 1,
      });
      setIsBagOpen(false);
    }
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

      <div className="flex-1 flex items-center justify-center p-1 overflow-hidden w-full h-full relative">
        {/* GAME BOARD WRAPPER */}
        <div
          ref={roomContainerRef}
          className={`
                relative shadow-2xl 
                ${
                  unicorn?.bgImage
                    ? "rounded-2xl border border-slate-800 bg-slate-900"
                    : "w-full h-full"
                }
            `}
        >
          {/* 1. BACKGROUND LAYER */}
          {unicorn?.bgImage ? (
            <img
              src={unicorn.bgImage}
              alt="Room"
              style={{ backgroundColor: "#0f172a" }}
              className="max-w-full max-h-[calc(100vh-6rem)] w-auto h-auto block rounded-2xl object-contain pointer-events-none select-none"
            />
          ) : (
            // CSS MODE
            <div className={`absolute inset-0 ${unicorn?.style} opacity-100`}>
              <div className="absolute bottom-0 w-full h-1/3 bg-white/5 backdrop-blur-sm border-t border-white/10" />
            </div>
          )}

          {/* 2. FURNITURE OVERLAY LAYER */}
          <div className="absolute inset-0 overflow-hidden rounded-2xl">
            {placedItems.map((item) => {
              const def = FURNITURE.find((f) => f.id === item.itemId);
              return (
                <DraggableItem
                  key={item.instanceId}
                  def={def}
                  data={item}
                  containerRef={roomContainerRef}
                  onSave={(updates) =>
                    onPlaceItem(unicornId, { ...item, ...updates })
                  }
                  onRemove={() => onRemoveItem(unicornId, item.instanceId)}
                />
              );
            })}
          </div>
        </div>
      </div>

      <div className="absolute bottom-safe right-4 z-50">
        <button
          onClick={() => setIsBagOpen(true)}
          className="w-16 h-16 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-full shadow-lg border-4 border-white/20 flex items-center justify-center text-yellow-950 animate-bounce"
        >
          <Briefcase size={28} />
        </button>
      </div>

      {isBagOpen && (
        <div className="absolute inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-end animate-fade-in">
          <div className="w-full bg-slate-900 rounded-t-3xl p-6 border-t border-slate-700 h-[60vh] flex flex-col">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-white font-bold text-xl">Furniture Bag</h2>
              <button
                onClick={() => setIsBagOpen(false)}
                className="p-2 bg-slate-800 rounded-full text-white"
              >
                <X />
              </button>
            </div>

            <div className="grid grid-cols-3 gap-4 overflow-y-auto pb-8">
              {FURNITURE.map((f) => {
                const available = getAvailableCount(f.id);
                return (
                  <button
                    key={f.id}
                    onClick={() => spawnItem(f.id)}
                    disabled={available <= 0}
                    className={`p-4 rounded-xl border-2 flex flex-col items-center gap-2 relative ${
                      available > 0
                        ? "bg-slate-800 border-slate-700 active:border-cyan-500"
                        : "bg-slate-900 border-slate-800 opacity-50 cursor-not-allowed"
                    }`}
                  >
                    <div className="text-3xl">{f.icon}</div>
                    <div className="text-xs text-slate-400 font-bold">
                      {f.name}
                    </div>
                    <div
                      className={`absolute top-2 right-2 text-[10px] font-black px-2 py-0.5 rounded-full ${
                        available > 0
                          ? "bg-emerald-500 text-emerald-950"
                          : "bg-slate-700 text-slate-500"
                      }`}
                    >
                      x{available}
                    </div>
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

const DraggableItem = ({ def, data, onSave, onRemove, containerRef }) => {
  const [pos, setPos] = useState({ x: data.x, y: data.y });
  const [rotation, setRotation] = useState(data.rotation || 0);
  const [scale, setScale] = useState(data.scale || 1);
  const [mode, setMode] = useState("none"); // 'none', 'moving', 'resizing'

  const startRef = useRef({ x: 0, y: 0, valX: 0, valY: 0, initialScale: 1 });

  useEffect(() => {
    setPos({ x: data.x, y: data.y });
    setRotation(data.rotation || 0);
    setScale(data.scale || 1);
  }, [data]);

  const handleStart = (e, interactionMode = "moving") => {
    e.stopPropagation();
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

      setPos({
        x: Math.max(0, Math.min(95, startRef.current.valX + dXPercent)),
        y: Math.max(0, Math.min(95, startRef.current.valY + dYPercent)),
      });
    } else if (mode === "resizing") {
      const dX = clientX - startRef.current.x;
      // Simple scaling based on horizontal drag distance
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
      onSave({ x: pos.x, y: pos.y, rotation, scale });
    }
  };

  const handleRotate = (e) => {
    e.stopPropagation();
    const newRotation = (rotation + 45) % 360;
    setRotation(newRotation);
    onSave({ x: pos.x, y: pos.y, rotation: newRotation, scale });
  };

  return (
    <div
      className={`absolute flex flex-col items-center justify-center w-16 h-16 select-none z-20 transition-all cursor-move group
      ${mode !== "none" ? "z-50" : ""}`}
      style={{
        left: `${pos.x}%`,
        top: `${pos.y}%`,
        transform: `translate(-50%, -50%) rotate(${rotation}deg) scale(${scale})`,
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
        {def.icon}

        {/* Border indicating selection/interaction */}
        <div className="absolute inset-[-10px] border-2 border-white/0 group-hover:border-white/30 rounded-lg pointer-events-none transition-colors" />
      </div>

      {/* CONTROLS */}
      {/* 1. Remove (Top Right) */}
      <button
        className="absolute -top-6 -right-6 bg-rose-500 text-white rounded-full p-1.5 shadow-md scale-0 group-hover:scale-100 transition-transform z-30 cursor-pointer"
        onMouseDown={(e) => {
          e.stopPropagation();
          onRemove();
        }}
        onTouchStart={(e) => {
          e.stopPropagation();
          onRemove();
        }}
      >
        <X size={14} />
      </button>

      {/* 2. Rotate (Top Left) */}
      <button
        className="absolute -top-6 -left-6 bg-blue-500 text-white rounded-full p-1.5 shadow-md scale-0 group-hover:scale-100 transition-transform z-30 cursor-pointer"
        onMouseDown={handleRotate}
        onTouchStart={handleRotate}
      >
        <RotateCw size={14} />
      </button>

      {/* 3. Resize Handle (Bottom Right) */}
      <div
        className="absolute -bottom-6 -right-6 bg-emerald-500 text-white rounded-full p-1.5 shadow-md scale-0 group-hover:scale-100 transition-transform z-30 cursor-ew-resize flex items-center justify-center"
        onMouseDown={(e) => handleStart(e, "resizing")}
        onTouchStart={(e) => handleStart(e, "resizing")}
      >
        <Scaling size={14} />
      </div>
    </div>
  );
};

export default RoomView;
