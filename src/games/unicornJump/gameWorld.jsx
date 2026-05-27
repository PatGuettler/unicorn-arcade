import React from "react";
import { CheckCircle } from "lucide-react";
import { UnicornAvatar } from "../../components/assets/gameAssets";
import UnicornTutorial from "./unicornTutorial";

const GameWorld = ({
  viewport,
  nodePositions,
  levelData,
  currentIndex,
  visitedIndices,
  showHint,
  onNodeClick,
  level,
  unicornImage,
}) => {
  const shouldShowOverlay = level === 1 || showHint;

  let tutorialProps = null;
  if (shouldShowOverlay && nodePositions.length > 0) {
    const jumpDist = levelData[currentIndex];
    const targetIdx = currentIndex + jumpDist;

    if (nodePositions[currentIndex] && nodePositions[targetIdx]) {
      tutorialProps = {
        fromNode: nodePositions[currentIndex],
        toNode: nodePositions[targetIdx],
        jumpDistance: jumpDist,
      };
    }
  }

  return (
    <div
      className="absolute inset-0 origin-center will-change-transform"
      style={{
        transform: `translate(${viewport.pan.x}px, ${viewport.pan.y}px) scale(${viewport.zoom})`,
        transition: viewport.isDragging ? "none" : "transform 0.3s ease-out",
      }}
    >
      <div className="relative">
        <svg className="absolute top-0 left-0 w-full h-[90000px] overflow-visible pointer-events-none">
          <defs>
            <linearGradient
              id="rainbowGradient"
              x1="0%"
              y1="0%"
              x2="0%"
              y2="100%"
            >
              <stop offset="0%" stopColor="#ef4444" />
              <stop offset="20%" stopColor="#f97316" />
              <stop offset="40%" stopColor="#eab308" />
              <stop offset="60%" stopColor="#22c55e" />
              <stop offset="80%" stopColor="#3b82f6" />
              <stop offset="100%" stopColor="#a855f7" />
            </linearGradient>
          </defs>
          {nodePositions.slice(0, -1).map((pos, i) => {
            const nextPos = nodePositions[i + 1];
            if (!nextPos) return null;
            const prevPos = nodePositions[i - 1] || pos;
            const nextNextPos = nodePositions[i + 2] || nextPos;
            const cp1x = pos.x + (nextPos.x - prevPos.x) * 0.25;
            const cp1y = pos.y + (nextPos.y - prevPos.y) * 0.25;
            const cp2x = nextPos.x - (nextNextPos.x - pos.x) * 0.25;
            const cp2y = nextPos.y - (nextNextPos.y - pos.y) * 0.25;
            const isRainbow = i < currentIndex;
            return (
              <path
                key={`path-${i}`}
                d={`M ${pos.x} ${pos.y} C ${cp1x} ${cp1y}, ${cp2x} ${cp2y}, ${nextPos.x} ${nextPos.y}`}
                fill="none"
                stroke={isRainbow ? "url(#rainbowGradient)" : "#1e293b"}
                strokeWidth={isRainbow ? "10" : "8"}
                strokeLinecap="round"
                className={
                  isRainbow ? "drop-shadow-[0_0_10px_rgba(168,85,247,0.5)]" : ""
                }
              />
            );
          })}
        </svg>

        {levelData.map((val, idx) => {
          const pos = nodePositions[idx];
          if (!pos) return null;
          const isCurrent = idx === currentIndex;
          const isVisited = visitedIndices.includes(idx);
          let baseClasses =
            "bg-slate-900 border-slate-700 text-slate-500 hover:border-slate-500 hover:scale-105";
          if (isVisited && !isCurrent) {
            baseClasses =
              "bg-emerald-900 border-emerald-500 text-emerald-400 shadow-[0_0_20px_rgba(16,185,129,0.6)]";
          } else if (isCurrent) {
            baseClasses =
              "bg-cyan-500 border-white text-slate-900 ring-4 ring-cyan-500/30 scale-110 z-20";
          }
          return (
            <div
              key={idx}
              data-game-node
              role="button"
              tabIndex={0}
              onPointerDown={(e) => e.stopPropagation()}
              onClick={() => onNodeClick(idx)}
              className={`absolute flex flex-col items-center justify-center w-16 h-16 rounded-full border-4 text-xl font-black transition-all duration-300 cursor-pointer touch-manipulation ${baseClasses}`}
              style={{ left: pos.x - 32, top: pos.y - 32 }}
            >
              <span className="relative z-10 drop-shadow-md">{val}</span>
              {isVisited && !isCurrent && (
                <div
                  className="absolute text-2xl animate-pulse drop-shadow-md select-none pointer-events-none z-40 opacity-80"
                  style={{ marginTop: "-50px" }}
                >
                  🌈
                </div>
              )}
            </div>
          );
        })}

        {tutorialProps && <UnicornTutorial {...tutorialProps} />}

        {nodePositions[currentIndex] && (
          <div
            className="absolute pointer-events-none z-30 w-20 h-20 transition-all duration-500 ease-in-out filter drop-shadow-2xl"
            style={{
              left: nodePositions[currentIndex].x - 40,
              top: nodePositions[currentIndex].y - 100,
            }}
          >
            <UnicornAvatar image={unicornImage} className="w-full h-full" />
          </div>
        )}

        {(() => {
          const lastIdx = levelData.length;
          const pos = nodePositions[lastIdx];
          if (!pos) return null;
          const isVisited = visitedIndices.includes(lastIdx);
          return (
            <div
              data-game-node
              role="button"
              tabIndex={0}
              onPointerDown={(e) => e.stopPropagation()}
              onClick={() => onNodeClick(lastIdx)}
              className={`absolute flex items-center justify-center w-16 h-16 rounded-full border-4 transition-transform z-10 cursor-pointer touch-manipulation ${
                isVisited
                  ? "bg-emerald-500 border-emerald-300 scale-110 shadow-[0_0_50px_rgba(16,185,129,0.8)] animate-pulse"
                  : "bg-slate-900 border-slate-700 opacity-60 hover:opacity-100 hover:scale-105 hover:border-emerald-500/50"
              }`}
              style={{ left: pos.x - 32, top: pos.y - 32 }}
            >
              <CheckCircle
                className={`w-8 h-8 pointer-events-none ${
                  isVisited ? "text-white" : "text-slate-600"
                }`}
              />
              <span className="absolute -bottom-8 text-xs font-bold tracking-widest text-emerald-400 pointer-events-none">
                GOAL
              </span>
            </div>
          );
        })()}
      </div>
    </div>
  );
};

export default GameWorld;
