import { useState, useEffect, useRef, useCallback } from "react";
import VictoryModal from "../../components/shared/victoryModal";
import GlobalHeader from "../../components/shared/globalHeader";
import GameHUD from "../../components/shared/gameHUD";
import { useGameSystem } from "../../components/shared/useGameSystem";
import GameWorld from "./gameWorld";
import { useGalaxyAttack } from "./useGalaxyAttack";

const SpaceUnicornGame = ({
  onExit,
  lastCompletedLevel = 0,
  onSaveProgress,
  calcCoins,
  coins,
  onHome,
  unicornImage,
}) => {
  const { gameState, level, elapsedTime, startGame, completeLevel, failLevel } =
    useGameSystem({
      initialLevel: lastCompletedLevel || 1,
      onSaveProgress,
    });

  const { gameRef, launchLevel, setPointer, tick, stop, getHud } =
    useGalaxyAttack();

  const [frame, setFrame] = useState(0);
  const [hud, setHud] = useState({ kills: 0, target: 12, score: 0, lives: 3 });
  const arenaRef = useRef(null);
  const loopRef = useRef(null);
  const lastTimeRef = useRef(0);

  const startLoop = useCallback(() => {
    lastTimeRef.current = performance.now();

    const loop = (now) => {
      const dt = Math.min(50, now - lastTimeRef.current);
      lastTimeRef.current = now;

      if (gameRef.current.playing) {
        tick(
          dt,
          () => {
            stop();
            completeLevel();
          },
          () => {
            stop();
            failLevel();
          }
        );
        setHud(getHud());
        setFrame((f) => f + 1);
      }

      loopRef.current = requestAnimationFrame(loop);
    };

    loopRef.current = requestAnimationFrame(loop);
  }, [tick, stop, completeLevel, failLevel, gameRef, getHud]);

  const handleLaunch = useCallback(
    (lvl) => {
      launchLevel(lvl);
      startGame(lvl);
      setHud(getHud());
      startLoop();
    },
    [launchLevel, startGame, startLoop, getHud]
  );

  useEffect(() => {
    handleLaunch(lastCompletedLevel || 1);
    return () => {
      stop();
      if (loopRef.current) cancelAnimationFrame(loopRef.current);
    };
  }, []);

  const pointerOnArena = (clientX) => {
    if (!arenaRef.current) return;
    setPointer(clientX, arenaRef.current.getBoundingClientRect());
  };

  const formatTime = (ms) => (ms / 1000).toFixed(2);

  return (
    <div className="fixed inset-0 w-full h-app bg-slate-950 text-white flex flex-col overflow-hidden select-none" data-testid="game-shell">
      <div className="shrink-0 z-40 pointer-events-none">
        <div className="pointer-events-auto">
          <GlobalHeader coins={coins} onBack={onExit} isSubScreen onHome={onHome} />
        </div>
      </div>

      <GameHUD
        title="Galaxy Unicorn"
        level={level}
        elapsedTime={elapsedTime}
        gameState={gameState === "playing" ? "playing" : "idle"}
        layout="stacked"
        lives={hud.lives}
        progress={hud.kills}
        target={hud.target}
        progressLabel="Targets"
      />

      <div
        ref={arenaRef}
        className="flex-1 relative min-h-0 touch-none"
        style={{ touchAction: "none" }}
        onPointerDown={(e) => {
          e.currentTarget.setPointerCapture(e.pointerId);
          pointerOnArena(e.clientX);
        }}
        onPointerMove={(e) => {
          if (e.buttons === 0 && e.pointerType === "mouse") return;
          pointerOnArena(e.clientX);
        }}
        onPointerUp={(e) => {
          try {
            e.currentTarget.releasePointerCapture(e.pointerId);
          } catch {
            /* ignore */
          }
        }}
      >
        <GameWorld gameRef={gameRef} unicornImage={unicornImage} tick={frame} />

        {gameState === "playing" && (
          <div className="absolute bottom-safe left-0 right-0 pointer-events-none flex justify-center px-4 pb-2">
            <p className="text-[10px] text-slate-400/90 font-bold uppercase tracking-wider bg-slate-900/70 px-3 py-1.5 rounded-full border border-slate-700/80">
              Drag to fly · Auto rainbow blasts · Grab ✨ pickups
            </p>
          </div>
        )}
      </div>

      {(gameState === "levelComplete" || gameState === "failed") && (
        <VictoryModal
          state={gameState}
          failReason={
            gameState === "failed"
              ? "Your unicorn ship was hit! Clear the galaxy invaders."
              : ""
          }
          time={formatTime(elapsedTime)}
          coinsEarned={
            gameState === "levelComplete" && calcCoins ? calcCoins(level) : 0
          }
          onAction={
            gameState === "failed"
              ? () => handleLaunch(level)
              : () => handleLaunch(level + 1)
          }
          isNext={gameState === "levelComplete"}
        />
      )}
    </div>
  );
};

export default SpaceUnicornGame;
