import { useState, useEffect } from "react";
import { useGameSystem } from "../../../components/shared/useGameSystem";
import WordGameShell from "../shared/WordGameShell";
import { UnicornAvatar } from "../../../components/assets/gameAssets";
import { CHAIN_LINKS, pickForLevel, shuffle } from "../wordMysteries/lists";
import { targetForLevel } from "../shared/useWordLevel";

export default function ChainLinkGame({
  onExit, onHome, lastCompletedLevel = 0, onSaveProgress, calcCoins, coins, unicornImage,
}) {
  const { gameState, level, elapsedTime, startGame, completeLevel, failLevel } =
    useGameSystem({ initialLevel: lastCompletedLevel || 1, onSaveProgress });

  const [round, setRound] = useState(0);
  const [target, setTarget] = useState(5);
  const [link, setLink] = useState(null);
  const [chain, setChain] = useState([]);

  const loadLink = (lvl, r) => {
    const data = pickForLevel(CHAIN_LINKS, lvl + r);
    setLink({ ...data, options: shuffle(data.options) });
  };

  const launch = (lvl) => {
    setRound(0);
    setTarget(targetForLevel(lvl));
    setChain([]);
    startGame(lvl);
    loadLink(lvl, 0);
  };

  useEffect(() => { launch(lastCompletedLevel || 1); }, []);

  const extend = (word) => {
    if (gameState !== "playing" || !link) return;
    if (word === link.answer) {
      const newChain = [...chain, link.start, word];
      setChain(newChain);
      const nr = round + 1;
      if (nr >= target) completeLevel();
      else {
        setRound(nr);
        loadLink(level, nr);
      }
    } else failLevel();
  };

  const lastLetter = link?.start?.slice(-1)?.toUpperCase() || "?";

  return (
    <WordGameShell
      title="Chain Link"
      coins={coins}
      onExit={onExit}
      onHome={onHome}
      gameState={gameState}
      level={level}
      elapsedTime={elapsedTime}
      unicornImage={unicornImage}
      hudProgress={round + 1}
      hudTarget={target}
      hudProgressLabel="Links"
      victory={{
        failReason: "Pick a word that starts with the last letter!",
        coinsEarned: gameState === "levelComplete" && calcCoins ? calcCoins(level) : 0,
        onAction: gameState === "failed" ? () => launch(level) : () => launch(level + 1),
      }}
    >
      <div className="flex flex-col items-center justify-center h-full p-6 gap-5">
        {unicornImage && (
          <div className="w-20 h-20">
            <UnicornAvatar image={unicornImage} className="w-full h-full" />
          </div>
        )}
        {chain.length > 0 && (
          <p className="text-xs text-slate-500 truncate max-w-xs">
            Chain: {chain.join(" → ")}
          </p>
        )}
        <div className="flex items-center gap-2 text-2xl font-black">
          <span className="px-4 py-3 bg-slate-800 rounded-xl border border-slate-600">{link?.start}</span>
          <span className="text-cyan-400">→</span>
          <span className="px-4 py-3 bg-cyan-950 rounded-xl border-2 border-cyan-500 text-cyan-300">
            {lastLetter}...
          </span>
        </div>
        <p className="text-slate-400 text-sm text-center max-w-xs">
          Next word must start with &quot;{lastLetter.toLowerCase()}&quot;
        </p>
        <div className="grid grid-cols-2 gap-3 w-full max-w-xs">
          {link?.options.map((o) => (
            <button
              key={o}
              type="button"
              onClick={() => extend(o)}
              className="py-4 rounded-2xl bg-slate-800 border-2 border-cyan-600/40 font-bold hover:border-cyan-400 active:scale-95 capitalize"
            >
              {o}
            </button>
          ))}
        </div>
      </div>
    </WordGameShell>
  );
}
