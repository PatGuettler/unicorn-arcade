import { useState, useEffect } from "react";
import { generateLevelData, generateNodePositions } from "./levelUtils";
import { useGameSystem } from "../../components/shared/useGameSystem";

export const useUnicornGame = (
  initialLevel,
  onSaveProgress,
  onSpendCoins,
  viewport
) => {
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
    initialLevel,
    onSaveProgress,
    onSpendCoins,
  });

  const [levelData, setLevelData] = useState([]);
  const [visitedIndices, setVisitedIndices] = useState([]);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [nodePositions, setNodePositions] = useState([]);

  // Sync Camera
  useEffect(() => {
    if (gameState === "playing" && nodePositions[currentIndex]) {
      const pos = nodePositions[currentIndex];
      const targetScreenX = window.innerWidth / 2;
      const targetScreenY = window.innerHeight * 0.35;
      const newPanX = targetScreenX - pos.x * viewport.zoom;
      const newPanY = targetScreenY - pos.y * viewport.zoom;
      viewport.setPan({ x: newPanX, y: newPanY });
    }
  }, [currentIndex, gameState, nodePositions, viewport.zoom, viewport.setPan]);

  const launchLevel = (lvl) => {
    const arr = generateLevelData(lvl);
    const positions = generateNodePositions(arr.length);

    setLevelData(arr);
    setNodePositions(positions);
    setCurrentIndex(0);
    setVisitedIndices([0]);

    viewport.setZoom(1);
    viewport.setPan({ x: 0, y: window.innerHeight * 0.3 });

    startGame(lvl);
  };

  const handleNodeClick = (idx) => {
    if (viewport.didDrag?.() || gameState !== "playing") return;
    const power = levelData[currentIndex];
    const dist = idx - currentIndex;

    if (dist === power) {
      setCurrentIndex(idx);
      setVisitedIndices((p) => [...p, idx]);
      registerMove(true);

      if (idx === levelData.length) {
        completeLevel();
      }
    } else {
      failLevel();
    }
  };

  return {
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
  };
};
