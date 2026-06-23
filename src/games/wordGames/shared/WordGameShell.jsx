import GlobalHeader from "../../../components/shared/globalHeader";
import GameHUD from "../../../components/shared/gameHUD";
import VictoryModal from "../../../components/shared/victoryModal";
export default function WordGameShell({
  title,
  children,
  footer,
  unicornImage,
  coins,
  onExit,
  onHome,
  gameState,
  level,
  elapsedTime,
  onBuyHint,
  showHint,
  hintCost = 5,
  isFreeHint,
  victory,
  hudExtra,
  hudProgress,
  hudTarget,
  hudProgressLabel,
  lives,
}) {
  const formatTime = (ms) => (ms / 1000).toFixed(2);

  return (
    <div className="fixed inset-0 w-full h-app bg-gradient-to-b from-slate-950 via-purple-950/80 to-slate-950 text-white flex flex-col overflow-hidden select-none" data-testid="word-game-shell">
      <div className="shrink-0 z-40 pointer-events-none">
        <div className="pointer-events-auto">
          <GlobalHeader coins={coins} onBack={onExit} isSubScreen onHome={onHome} />
        </div>
      </div>

      <div className="shrink-0 z-20 w-full">
        <GameHUD
          title={title}
          level={level}
          elapsedTime={elapsedTime}
          gameState={gameState === "playing" ? "playing" : "idle"}
          coins={coins}
          onBuyHint={onBuyHint}
          showHint={showHint}
          hintCost={hintCost}
          isFreeHint={isFreeHint}
          layout="stacked"
          progress={hudProgress}
          target={hudTarget}
          progressLabel={hudProgressLabel}
          lives={lives}
        />
        {hudExtra && (
          <div className="flex justify-center px-4 pb-2 pt-1">{hudExtra}</div>
        )}
      </div>

      <div className="flex-1 min-h-0 relative">{children}</div>

      {footer && <div className="shrink-0 z-30">{footer}</div>}

      {victory && (gameState === "levelComplete" || gameState === "failed") && (
        <VictoryModal
          state={gameState}
          failReason={victory.failReason || ""}
          time={formatTime(elapsedTime)}
          coinsEarned={victory.coinsEarned || 0}
          onAction={victory.onAction}
          isNext={gameState === "levelComplete"}
        />
      )}
    </div>
  );
}
