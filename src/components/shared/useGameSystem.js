import { useState, useEffect, useRef } from "react";

export const useGameSystem = ({
  initialLevel = 1,
  onSaveProgress,
  onSpendCoins,
  hintCost = 5,
}) => {
  const [gameState, setGameState] = useState("playing");
  const [level, setLevel] = useState(initialLevel);
  const [elapsedTime, setElapsedTime] = useState(0);
  const [showHint, setShowHint] = useState(false);

  const startTimeRef = useRef(0);

  // Timer Logic
  useEffect(() => {
    let interval = null;
    if (gameState === "playing") {
      startTimeRef.current = Date.now() - elapsedTime;
      interval = setInterval(
        () => setElapsedTime(Date.now() - startTimeRef.current),
        50
      );
    }
    return () => clearInterval(interval);
  }, [gameState]);

  // Automatic Free Hints on Level 1
  useEffect(() => {
    if (level === 1 && gameState === "playing") {
      setShowHint(true);
    }
  }, [level, gameState]);

  const startGame = (lvl) => {
    setLevel(lvl);
    setElapsedTime(0);
    setShowHint(false);
    setGameState("playing");
    startTimeRef.current = Date.now();
  };

  const registerMove = (isValid) => {
    if (gameState !== "playing") return;

    // Hide hint after a successful move
    if (isValid) {
      setShowHint(false);
    }
  };

  const buyHint = () => {
    if (showHint || gameState !== "playing") return;

    // Check if we are in the "free hint" window (e.g. level 1, first 2 moves)
    const isFree = level === 1;

    if (isFree) {
      setShowHint(true);
      return;
    }

    if (onSpendCoins && onSpendCoins(hintCost)) {
      setShowHint(true);
    }
  };

  const completeLevel = () => {
    const finalTime = elapsedTime / 1000;
    onSaveProgress(level, finalTime);
    setGameState("scoring");
    setTimeout(() => setGameState("levelComplete"), 1000);
  };

  const failLevel = () => {
    setGameState("failed");
  };

  return {
    gameState,
    setGameState,
    level,
    elapsedTime,
    showHint,
    startGame,
    registerMove,
    buyHint,
    completeLevel,
    failLevel,
    hintCost,
  };
};
