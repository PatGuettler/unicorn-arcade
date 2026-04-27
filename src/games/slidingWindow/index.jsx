import React, { useState, useEffect, useRef } from "react";
import { ZoomIn, ZoomOut } from "lucide-react";
import { useGameViewport } from "../../hooks/gameViewport";
import VictoryModal from "../../components/shared/victoryModal";
import GlobalHeader from "../../components/shared/globalHeader";
import GameHUD from "../../components/shared/gameHUD";
import { useGameSystem } from "../../components/shared/useGameSystem";
import { OpponentAI } from "./opponentAI";
import { formatTime } from "../../utils/useGameManager";
import { PlayerTrack } from "./player";
import { OpponentTrack } from "./bot";

const SlidingWindowGame = ({
  onExit,
  lastCompletedLevel = 0,
  onSaveProgress,
  calcCoins,
  coins,
  onSpendCoins,
  onHome,
  unicornImage,
}) => {
  const LAYOUT = {
    NODE_WIDTH: 80,
    NODE_GAP: 20,
    FULL_W: 100,
    PADDING: 100,
    ROW_GAP: 200,
  };

  const viewport = useGameViewport(1);
  const {
    gameState,
    level,
    elapsedTime,
    showHint,
    startGame,
    registerMove,
    buyHint,
    completeLevel,
    failLevel,
    hintCost,
  } = useGameSystem({
    initialLevel: lastCompletedLevel,
    onSaveProgress,
    onSpendCoins,
  });

  const [levelData, setLevelData] = useState([]);
  const [opponentLevelData, setOpponentLevelData] = useState([]);
  const [windowSize, setWindowSize] = useState(3);
  const [windowPos, setWindowPos] = useState(0);
  const [collectedNodes, setCollectedNodes] = useState([]);
  const [opponentPos, setOpponentPos] = useState(0);
  const [opponentCollectedNodes, setOpponentCollectedNodes] = useState([]);
  const [failReason, setFailReason] = useState("");

  const opponentRef = useRef(null);
  const containerRef = useRef(null);

  useEffect(() => {
    let startLvl = lastCompletedLevel;
    if (startLvl === 0) startLvl = 1;
    launchLevel(startLvl);
  }, []);

  //Used to center the users screen. Should happen at start and as the window slides
  useEffect(() => {
    if (gameState !== "playing") return;

    const windowCenterX =
      LAYOUT.PADDING + (windowPos + windowSize / 2) * LAYOUT.FULL_W;

    const windowCenterY = LAYOUT.ROW_GAP / 2;

    const screenCenterX = window.innerWidth / 2;
    const screenCenterY = window.innerHeight / 2;

    viewport.setPan({
      x: screenCenterX - windowCenterX * viewport.zoom,
      y: screenCenterY - windowCenterY * viewport.zoom,
    });
  }, [windowPos, windowSize, gameState]);

  // AI Logic Lifecycle
  useEffect(() => {
    if (
      gameState === "playing" &&
      opponentRef.current &&
      opponentLevelData.length > 0
    ) {
      opponentRef.current.stop();
      opponentRef.current.reset();

      const timeoutId = setTimeout(() => {
        if (opponentRef.current && gameState === "playing") {
          opponentRef.current.start(
            (newPos) => {
              setOpponentPos(newPos);
              setOpponentCollectedNodes((prev) => [...prev, newPos - 1]);
            },
            () => {
              setFailReason("The rival beat you to the finish!");
              failLevel("The rival beat you!");
            }
          );
        }
      }, 500);

      return () => clearTimeout(timeoutId);
    } else if (gameState !== "playing" && opponentRef.current) {
      opponentRef.current.stop();
    }
  }, [gameState, opponentLevelData]);

  // Cleanup opponent on unmount
  useEffect(() => {
    return () => {
      if (opponentRef.current) opponentRef.current.stop();
    };
  }, []);

  // --- Game Logic ---

  const launchLevel = (lvl) => {
    const len = 15 + (lvl > 5 ? 5 : 0);
    const min = lvl > 5 ? -100 : 0;
    const max = lvl > 2 ? 100 : 20;

    //using two different sets of numbers so the player because I was going to have the bot light up the right answer, but that make less sense.
    // Might make this use the same array later
    //@TODO
    const data = Array.from(
      { length: len },
      () => Math.floor(Math.random() * (max - min + 1)) + min
    );

    const opponentData = Array.from(
      { length: len },
      () => Math.floor(Math.random() * (max - min + 1)) + min
    );

    const size = Math.min(5, 3 + Math.floor(lvl / 3));

    setLevelData(data);
    setOpponentLevelData(opponentData);
    setWindowSize(size);
    setWindowPos(0);
    setOpponentPos(0);
    setCollectedNodes([]);
    setOpponentCollectedNodes([]);
    setFailReason("");

    const buffer = 70;
    const windowWidth = windowSize * LAYOUT.FULL_W;
    const windowHeight = LAYOUT.ROW_GAP + 200 + buffer * 2;

    const maxZoomX = (window.innerWidth * 0.85) / windowWidth;
    const maxZoomY = (window.innerHeight * 0.6) / windowHeight;
    const optimalZoom = Math.min(maxZoomX, maxZoomY, 1);

    viewport.setZoom(optimalZoom);

    if (opponentRef.current) opponentRef.current.stop();
    opponentRef.current = new OpponentAI(lvl, size, opponentData);

    startGame(lvl);
  };

  const handlePlayerNodeClick = (idx) => {
    if (gameState !== "playing") return;

    // Validate window bounds
    const winIndices = Array.from(
      { length: windowSize },
      (_, i) => windowPos + i
    );
    if (!winIndices.includes(idx)) return;

    // Logic: Find Max in current window
    let maxVal = -Infinity;
    winIndices.forEach((i) => {
      if (levelData[i] > maxVal) maxVal = levelData[i];
    });

    if (levelData[idx] === maxVal) {
      registerMove(true);
      setCollectedNodes((prev) => [...prev, idx]);

      if (windowPos + windowSize >= levelData.length) {
        if (opponentRef.current) opponentRef.current.stop();
        completeLevel();
      } else {
        setWindowPos((p) => p + 1);
      }
    } else {
      registerMove(false);
      setFailReason("Wrong node selected!");
      failLevel("Not the max value!");
    }
  };

  const handleMove = (e) => viewport.doDrag(e);
  const handleUp = () => viewport.endDrag();

  return (
    <div
      className="w-full h-screen bg-gradient-to-b from-slate-950 via-purple-950 to-slate-950 overflow-hidden text-white select-none relative"
      onMouseDown={viewport.startDrag}
      onMouseMove={handleMove}
      onMouseUp={handleUp}
      onMouseLeave={handleUp}
      onTouchStart={(e) => {
        viewport.touchStart(e);
        viewport.startDrag(e);
      }}
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
        title="Race the Unicorn!"
        level={level}
        elapsedTime={elapsedTime}
        gameState={gameState}
        coins={coins}
        onBuyHint={buyHint}
        showHint={showHint}
        hintCost={hintCost}
        isFreeHint={level === 1}
      />

      <div className="absolute bottom-6 right-6 z-30 flex flex-col gap-2 pointer-events-auto">
        <button
          onClick={() => viewport.applyZoom(0.2)}
          className="p-3 bg-slate-800 rounded-full text-cyan-400 border border-slate-600 hover:bg-slate-700"
        >
          <ZoomIn />
        </button>
        <button
          onClick={() => viewport.applyZoom(-0.2)}
          className="p-3 bg-slate-800 rounded-full text-slate-400 border border-slate-600 hover:bg-slate-700"
        >
          <ZoomOut />
        </button>
      </div>

      <div
        ref={containerRef}
        className="absolute top-0 left-0 will-change-transform origin-top-left"
        style={{
          transform: `translate(${viewport.pan.x}px, ${viewport.pan.y}px) scale(${viewport.zoom})`,
          transition: viewport.isDragging
            ? "none"
            : "transform 0.5s cubic-bezier(0.4, 0, 0.2, 1)",
        }}
      >
        <div className="relative">
          {/* Top Row: Player */}
          <PlayerTrack
            levelData={levelData}
            windowPos={windowPos}
            windowSize={windowSize}
            collectedNodes={collectedNodes}
            gameState={gameState}
            showHint={showHint}
            unicornImage={unicornImage}
            onNodeClick={handlePlayerNodeClick}
            layoutConstants={LAYOUT}
          />

          {/* Bottom Row: AI Opponent */}
          <OpponentTrack
            levelData={opponentLevelData}
            windowPos={opponentPos}
            windowSize={windowSize}
            collectedNodes={opponentCollectedNodes}
            gameState={gameState}
            layoutConstants={LAYOUT}
          />
        </div>
      </div>

      {(gameState === "levelComplete" || gameState === "failed") && (
        <VictoryModal
          state={gameState}
          failReason={failReason || "Wrong move!"}
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

export default SlidingWindowGame;
