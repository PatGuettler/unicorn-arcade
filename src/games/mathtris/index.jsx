import Mathtris from "./Mathtris";

export default function MathtrisGame({
  onExit,
  onHome,
  coins = 0,
  onSpendCoins,
}) {
  return (
    <Mathtris
      onExit={onExit}
      onHome={onHome}
      coins={coins}
      onSpendCoins={onSpendCoins}
    />
  );
}
