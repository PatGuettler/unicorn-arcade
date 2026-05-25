import { useState, useEffect, useRef, useCallback } from "react";
import { useGameSystem } from "../../../components/shared/useGameSystem";
import WordGameShell from "../shared/WordGameShell";
import CannonArena from "../shared/CannonArena";
import { wordsForLevel } from "../shared/wordLists";
import { targetForLevel } from "../shared/useWordLevel";

export default function UnicornBlastGame({
  onExit,
  onHome,
  lastCompletedLevel = 0,
  onSaveProgress,
  calcCoins,
  coins,
  unicornImage,
}) {
  const { gameState, level, elapsedTime, startGame, completeLevel, failLevel } =
    useGameSystem({ initialLevel: lastCompletedLevel || 1, onSaveProgress });

  const [words, setWords] = useState([]);
  const [input, setInput] = useState("");
  const [done, setDone] = useState(0);
  const [target, setTarget] = useState(5);
  const [projectiles, setProjectiles] = useState([]);
  const [explosions, setExplosions] = useState([]);
  const [lives, setLives] = useState(3);

  const nextId = useRef(0);
  const spawnRef = useRef(null);
  const animRef = useRef(null);
  const running = useRef(false);
  const inputRef = useRef(null);

  const getSpeed = (lvl) => 0.12 + lvl * 0.015;
  const getSpawnMs = (lvl) => Math.max(1400, 2800 - lvl * 120);

  const launch = useCallback(
    (lvl) => {
      if (spawnRef.current) clearInterval(spawnRef.current);
      if (animRef.current) cancelAnimationFrame(animRef.current);
      running.current = false;

      setWords([]);
      setInput("");
      setDone(0);
      setTarget(targetForLevel(lvl));
      setProjectiles([]);
      setExplosions([]);
      setLives(3);
      startGame(lvl);

      const spawn = () => {
        const list = wordsForLevel(lvl);
        const text = list[Math.floor(Math.random() * list.length)];
        setWords((prev) => [
          ...prev,
          {
            id: nextId.current++,
            text,
            x: 12 + Math.random() * 76,
            y: 8,
            speed: getSpeed(lvl),
            destroyed: false,
          },
        ]);
      };

      spawnRef.current = setInterval(spawn, getSpawnMs(lvl));
      spawn();
      running.current = true;

      const tick = () => {
        if (!running.current) return;
        setWords((prev) =>
          prev.map((w) => {
            if (w.destroyed) return w;
            const y = w.y + w.speed;
            if (y > 78) {
              setLives((l) => {
                const n = l - 1;
                if (n <= 0) {
                  running.current = false;
                  clearInterval(spawnRef.current);
                  failLevel();
                }
                return n;
              });
              return { ...w, destroyed: true };
            }
            return { ...w, y };
          })
        );
        animRef.current = requestAnimationFrame(tick);
      };
      animRef.current = requestAnimationFrame(tick);
    },
    [startGame, failLevel]
  );

  useEffect(() => {
    launch(lastCompletedLevel || 1);
    return () => {
      running.current = false;
      clearInterval(spawnRef.current);
      cancelAnimationFrame(animRef.current);
    };
  }, []);

  const fireAt = (word) => {
    const pid = Date.now();
    setProjectiles([
      {
        id: pid,
        fromX: 50,
        fromY: 88,
        target: { x: word.x, y: word.y },
        status: "flying",
        progress: 0,
      },
    ]);

    let step = 0;
    const fly = () => {
      step += 0.12;
      setProjectiles((prev) =>
        prev.map((p) => (p.id === pid ? { ...p, progress: Math.min(1, step) } : p))
      );
      if (step < 1) requestAnimationFrame(fly);
      else {
        setProjectiles((prev) =>
          prev.map((p) => (p.id === pid ? { ...p, status: "hit", progress: 1 } : p))
        );
        setExplosions((ex) => [
          ...ex,
          { id: pid, x: word.x, y: word.y },
        ]);
        setTimeout(() => {
          setExplosions((ex) => ex.filter((e) => e.id !== pid));
          setProjectiles((prev) => prev.filter((p) => p.id !== pid));
        }, 600);
      }
    };
    requestAnimationFrame(fly);

    setWords((prev) =>
      prev.map((w) => (w.id === word.id ? { ...w, destroyed: true } : w))
    );
    setInput("");
    if (inputRef.current) inputRef.current.value = "";

    setDone((d) => {
      const n = d + 1;
      if (n >= target) {
        running.current = false;
        clearInterval(spawnRef.current);
        cancelAnimationFrame(animRef.current);
        setTimeout(() => completeLevel(), 400);
      }
      return n;
    });
  };

  const onInput = (e) => {
    if (gameState !== "playing") return;
    const val = e.target.value.toLowerCase().trim();
    setInput(val);
    const hit = words.find((w) => !w.destroyed && w.text === val);
    if (hit) fireAt(hit);
  };

  return (
    <WordGameShell
      title="Unicorn Blast"
      coins={coins}
      onExit={onExit}
      onHome={onHome}
      gameState={gameState}
      level={level}
      elapsedTime={elapsedTime}
      unicornImage={unicornImage}
      hudProgress={done}
      hudTarget={target}
      hudProgressLabel="Blasts"
      lives={lives}
      footer={
        <div className="px-4 pb-6 pt-2">
          <div className="max-w-md mx-auto bg-slate-900/90 border-2 border-pink-500/40 rounded-2xl p-4">
            <p className="text-center text-[10px] uppercase tracking-wider text-pink-300/80 mb-2">
              Type the word — your unicorn fires from the cannon!
            </p>
            <input
              ref={inputRef}
              type="text"
              value={input}
              onChange={onInput}
              className="w-full bg-slate-950 border-2 border-slate-600 rounded-xl px-4 py-3 text-center text-lg font-bold focus:border-pink-400 outline-none"
              placeholder="Type here..."
              autoCapitalize="off"
              autoCorrect="off"
              spellCheck={false}
              autoFocus
            />
          </div>
        </div>
      }
      victory={{
        failReason: "Words reached your cannon!",
        coinsEarned: gameState === "levelComplete" && calcCoins ? calcCoins(level) : 0,
        onAction:
          gameState === "failed"
            ? () => launch(level)
            : () => launch(level + 1),
      }}
    >
      <CannonArena
        words={words}
        projectiles={projectiles}
        explosions={explosions}
        unicornImage={unicornImage}
      />
    </WordGameShell>
  );
}
