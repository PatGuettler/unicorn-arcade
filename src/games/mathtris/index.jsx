import Mathtris from "./Mathtris";

export default function MathtrisGame({
  onExit,
  onHome,
  coins = 0,
  onSpendCoins,
  unicornImage,
  unicornId,
}) {
  return (
    <Mathtris
      onExit={onExit}
      onHome={onHome}
      coins={coins}
      onSpendCoins={onSpendCoins}
      unicornImage={unicornImage}
      unicornId={unicornId}
    />
  );
}
