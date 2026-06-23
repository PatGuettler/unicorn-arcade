import React, { useEffect } from "react";
import { ZoomIn, ZoomOut } from "lucide-react";
import { useGameViewport } from "../../hooks/gameViewport";
import VictoryModal from "../../components/shared/victoryModal";
import GlobalHeader from "../../components/shared/globalHeader";
import GameHUD from "../../components/shared/gameHUD";
import GameWorld from "./gameWorld";
import { useUnicornGame } from "./useUnicornGame";
import { ignoreIfInteractive } from "../../utils/mobileTouch";

const UnicornJumpGame = ({
  onExit,
  lastCompletedLevel = 0,
  onSaveProgress,
  calcCoins,
  coins,
  onSpendCoins,
  onHome,
  unicornImage,
}) => {
  const viewport = useGameViewport(1);

  const {
    gameState,
    level,
    levelData,
    visitedIndices,
    currentIndex,
    elapsedTime,
    nodePositions,
    showHint,
    launchLevel,
    handleNodeClick,
    buyHint,
    hintCost,
  } = useUnicornGame(
    lastCompletedLevel,
    onSaveProgress,
    onSpendCoins,
    viewport
  );

  const formatTime = (ms) => (ms / 1000).toFixed(2);
  const handleDown = (e) => viewport.startDrag(e);
  const handleMove = (e) => viewport.doDrag(e);
  const handleUp = () => viewport.endDrag();

  useEffect(() => {
    let startLevel = lastCompletedLevel;
    if (startLevel === 0) startLevel = 1;
    launchLevel(startLevel);
  }, []);

  return (
    <div
      className="w-full h-app game-surface bg-gradient-to-b from-slate-950 via-purple-950 to-slate-950 overflow-hidden text-white select-none relative"
      data-testid="game-shell"
      onMouseDown={ignoreIfInteractive(handleDown)}
      onMouseMove={handleMove}
      onMouseUp={handleUp}
      onMouseLeave={handleUp}
      onTouchStart={ignoreIfInteractive((e) => {
        viewport.touchStart(e);
        viewport.startDrag(e);
      })}
      onTouchMove={(e) => {
        viewport.touchMove(e);
        handleMove(e);
      }}
      onTouchEnd={(e) => {
        viewport.touchEnd(e);
        handleUp(e);
      }}
      onWheel={(e) => viewport.applyZoom(e.deltaY * -0.001)}
      style={{ cursor: viewport.isDragging ? "grabbing" : "grab" }}
    >
      <div className="absolute top-0 left-0 w-full z-30 pointer-events-none">
        <div className="pointer-events-auto">
          <GlobalHeader
            coins={coins}
            onBack={onExit}
            isSubScreen={true}
            onHome={onHome}
          />
        </div>
      </div>

      <GameHUD
        title="Unicorn Jump"
        level={level}
        elapsedTime={elapsedTime}
        gameState={gameState}
        coins={coins}
        onBuyHint={buyHint}
        showHint={showHint}
        hintCost={hintCost}
        isFreeHint={level === 1 && visitedIndices.length <= 2}
      />

      <div className="absolute bottom-safe right-4 z-40 flex flex-col gap-2 pointer-events-auto">
        <button
          type="button"
          onClick={() => viewport.applyZoom(0.1)}
          className="p-3 min-w-[48px] min-h-[48px] bg-slate-800 rounded-full text-cyan-400 border border-slate-600 hover:bg-slate-700"
        >
          <ZoomIn />
        </button>
        <button
          type="button"
          onClick={() => viewport.applyZoom(-0.1)}
          className="p-3 min-w-[48px] min-h-[48px] bg-slate-800 rounded-full text-slate-400 border border-slate-600 hover:bg-slate-700"
        >
          <ZoomOut />
        </button>
      </div>

      <GameWorld
        viewport={viewport}
        nodePositions={nodePositions}
        levelData={levelData}
        currentIndex={currentIndex}
        visitedIndices={visitedIndices}
        showHint={showHint}
        onNodeClick={handleNodeClick}
        level={level}
        unicornImage={unicornImage}
      />

      {(gameState === "levelComplete" || gameState === "failed") && (
        <VictoryModal
          state={gameState}
          failReason={gameState === "failed" ? "Wrong jump!" : ""}
          time={formatTime(elapsedTime)}
          coinsEarned={
            gameState === "levelComplete" && calcCoins ? calcCoins(level) : 0
          }
          onAction={
            gameState === "failed"
              ? () => launchLevel(level)
              : () => launchLevel(level + 1)
          }
          isNext={gameState === "levelComplete"}
        />
      )}
    </div>
  );
};

export default UnicornJumpGame;
