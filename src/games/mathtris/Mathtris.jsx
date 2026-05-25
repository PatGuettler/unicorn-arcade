// Mathtris.jsx
// A Tetris-style math game for 6–8 year olds.
// Blocks fall with numbers (+, -, =). Settle blocks, swap adjacent ones,
// and complete equations like  1 + 2 = 3  across or down to clear them!

import { useState, useEffect, useRef, useCallback } from "react";
import GlobalHeader from "../../components/shared/globalHeader";
import GameHUD from "../../components/shared/gameHUD";

// ─── Constants ────────────────────────────────────────────────────────────────
const COLS = 8;
const ROWS = 14;
const CELL = 42; // px per cell

// Block visual config
const BLOCK_CFG = {
  "1": { bg: "#FF6B6B", shadow: "#B83232" },
  "2": { bg: "#FF9F43", shadow: "#B85E00" },
  "3": { bg: "#FECA57", shadow: "#B88C00" },
  "4": { bg: "#26de81", shadow: "#0A8C3E" },
  "5": { bg: "#45aaf2", shadow: "#1567A8" },
  "6": { bg: "#a55eea", shadow: "#6322A8" },
  "7": { bg: "#fd9644", shadow: "#B85300" },
  "8": { bg: "#fc5c65", shadow: "#B01C25" },
  "9": { bg: "#2bcbba", shadow: "#0A7A6E" },
  "+": { bg: "#f7b731", shadow: "#A87300" },
  "-": { bg: "#4b7bec", shadow: "#1A3FA8" },
  "=": { bg: "#a29bfe", shadow: "#5A50C0" },
};

const MSGS = [
  "🎉 Awesome!",
  "🌟 Great job!",
  "🥳 You did it!",
  "⭐ Fantastic!",
  "🎊 Amazing!",
  "💥 Brilliant!",
];

// ─── Pure helpers ─────────────────────────────────────────────────────────────
function makeBoard() {
  return Array.from({ length: ROWS }, () => Array(COLS).fill(null));
}

function shuffle(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

/** Levels 1–10: only 1, 2, +, =. Valid clears: 1+1=2 and 2=1+1 */
const TIER_BASICS = {
  label: "Basics",
  allowed: ["1", "2", "+", "="],
  equationKits: [
    ["1", "+", "1", "=", "2"],
    ["2", "=", "1", "+", "1"],
  ],
  bagWeights: { 1: 5, 2: 4, "+": 2, "=": 2 },
  idealStock: { 1: 2, 2: 1, "+": 1, "=": 1 },
};

const TIER_INTERMEDIATE = {
  label: "Growing",
  allowed: ["1", "2", "3", "4", "5", "+", "="],
  equationKits: [
    ["1", "+", "1", "=", "2"],
    ["2", "=", "1", "+", "1"],
    ["1", "+", "2", "=", "3"],
    ["3", "=", "1", "+", "2"],
    ["2", "+", "2", "=", "4"],
    ["4", "=", "2", "+", "2"],
    ["2", "+", "3", "=", "5"],
    ["5", "=", "2", "+", "3"],
  ],
  bagWeights: { 1: 3, 2: 3, 3: 3, 4: 2, 5: 2, "+": 2, "=": 2 },
  idealStock: { 1: 1, 2: 1, 3: 1, "+": 1, "=": 1 },
};

const TIER_ADVANCED = {
  label: "Expert",
  allowed: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "+", "-", "="],
  equationKits: [
    ["1", "+", "2", "=", "3"],
    ["4", "-", "1", "=", "3"],
    ["5", "=", "2", "+", "3"],
    ["7", "=", "9", "-", "2"],
  ],
  bagWeights: {
    1: 2, 2: 2, 3: 2, 4: 2, 5: 2, 6: 1, 7: 1, 8: 1, 9: 1,
    "+": 2, "-": 1, "=": 2,
  },
  idealStock: { 1: 1, 2: 1, 3: 1, "+": 1, "=": 1 },
};

function kitUsesOnlyAllowed(kit, allowed) {
  return kit.every((t) => allowed.includes(t));
}

/** Drop interval (ms) — keeps getting faster past level 10 */
function getDropInterval(level) {
  if (level <= 10) return Math.max(300, 1000 - (level - 1) * 78);
  if (level <= 20) return Math.max(220, 298 - (level - 11) * 8);
  return Math.max(150, 218 - (level - 21) * 3);
}

function getLevelConfig(level) {
  const tierProgress =
    level <= 10 ? (level - 1) / 9 :
    level <= 20 ? (level - 11) / 9 :
    Math.min(1, (level - 21) / 19);

  const spawnHelpChance = Math.max(0.48, 0.9 - tierProgress * 0.42);
  const stuckThreshold = Math.round(5 + tierProgress * 10);
  const injectStuckKit = level <= 18 || tierProgress < 0.72;

  if (level <= 10) {
    return {
      ...TIER_BASICS,
      label: level <= 5 ? "Basics" : "Basics+",
      spawnHelpChance,
      stuckThreshold,
      injectStuckKit,
    };
  }

  if (level <= 20) {
    const digits = ["1", "2", "3"];
    if (level >= 13) digits.push("4");
    if (level >= 16) digits.push("5");
    const allowed = [...digits, "+", "="];
    const equationKits = TIER_INTERMEDIATE.equationKits.filter((k) =>
      kitUsesOnlyAllowed(k, allowed)
    );
    const bagWeights = {};
    digits.forEach((d) => { bagWeights[d] = 3; });
    bagWeights["+"] = 2;
    bagWeights["="] = 2;
    const idealStock = { "+": 1, "=": 1 };
    digits.forEach((d) => { idealStock[d] = 1; });

    return {
      label: "Growing",
      allowed,
      equationKits,
      bagWeights,
      idealStock,
      spawnHelpChance,
      stuckThreshold,
      injectStuckKit,
    };
  }

  const maxDigit = Math.min(9, 5 + Math.floor((level - 21) / 3));
  const digits = Array.from({ length: maxDigit }, (_, i) => String(i + 1));
  const allowed = [...digits, "+", "="];
  if (level >= 24) allowed.push("-");

  let equationKits = TIER_ADVANCED.equationKits.filter((k) =>
    kitUsesOnlyAllowed(k, allowed)
  );
  if (!equationKits.length) {
    equationKits = TIER_INTERMEDIATE.equationKits.filter((k) =>
      kitUsesOnlyAllowed(k, allowed)
    );
  }

  const bagWeights = {};
  digits.forEach((d) => { bagWeights[d] = Number(d) <= 5 ? 2 : 1; });
  bagWeights["+"] = 2;
  bagWeights["="] = 2;
  if (level >= 24) bagWeights["-"] = Math.min(2, 1 + Math.floor((level - 24) / 6));

  const idealStock = { "+": 1, "=": 1 };
  digits.slice(0, Math.min(3, digits.length)).forEach((d) => { idealStock[d] = 1; });

  return {
    label: "Expert",
    allowed,
    equationKits,
    bagWeights,
    idealStock,
    spawnHelpChance,
    stuckThreshold,
    injectStuckKit,
  };
}

function refillBag(cfg) {
  const bag = [];
  for (const [v, n] of Object.entries(cfg.bagWeights)) {
    for (let i = 0; i < n; i++) bag.push(v);
  }
  return shuffle(bag);
}

function countTokens(board, falling, next) {
  const counts = {};
  const add = (v) => { counts[v] = (counts[v] || 0) + 1; };
  for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c < COLS; c++) {
      if (board[r][c]) add(board[r][c].value);
    }
  }
  if (falling?.value) add(falling.value);
  if (next?.value) add(next.value);
  return counts;
}

const isDigit = (v) => v && /^\d$/.test(v);

/** Every 5-cell run horizontally or vertically */
function forEachSegment5(fn) {
  for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c <= COLS - 5; c++) {
      fn(Array.from({ length: 5 }, (_, i) => ({ r, c: c + i })));
    }
  }
  for (let c = 0; c < COLS; c++) {
    for (let r = 0; r <= ROWS - 5; r++) {
      fn(Array.from({ length: 5 }, (_, i) => ({ r: r + i, c })));
    }
  }
}

function readSegment(board, positions) {
  const seg = [];
  for (const { r, c } of positions) {
    if (!board[r][c]) return null;
    seg.push(board[r][c].value);
  }
  return seg;
}

function isValidEquationSeg(seg) {
  const [a, b, c2, d, e] = seg;
  // Pattern: n op n = n  (e.g. 1+2=3)
  if (isDigit(a) && (b === "+" || b === "-") && isDigit(c2) && d === "=" && isDigit(e)) {
    const res = b === "+" ? +a + +c2 : +a - +c2;
    if (res === +e && res >= 0 && res <= 9) return true;
  }
  // Pattern: n = n op n  (e.g. 3=1+2)
  if (isDigit(a) && b === "=" && isDigit(c2) && (d === "+" || d === "-") && isDigit(e)) {
    const res = d === "+" ? +c2 + +e : +c2 - +e;
    if (res === +a && res >= 0 && res <= 9) return true;
  }
  return false;
}

/** Pieces missing on a line (row or column) that partially matches a valid kit */
function getLineMissingPieces(board, cfg) {
  const missing = [];
  forEachSegment5((positions) => {
    const slots = positions.map(({ r, c }) => board[r][c]?.value ?? null);
    for (const kit of cfg.equationKits) {
      const need = [];
      let compatible = true;
      for (let i = 0; i < 5; i++) {
        if (slots[i] === null) need.push(kit[i]);
        else if (slots[i] !== kit[i]) { compatible = false; break; }
      }
      if (!compatible || !need.length) continue;
      if (need.length <= 2) missing.push(...need);
    }
  });
  return missing;
}

function getSpawnPriority(g) {
  const cfg = getLevelConfig(g.level);
  const counts = countTokens(g.board, g.falling, g.next);
  const pri = [];

  for (const [v, target] of Object.entries(cfg.idealStock)) {
    const have = counts[v] || 0;
    for (let i = have; i < target; i++) pri.push(v);
  }

  if (!(counts["="] >= 1)) pri.push("=");
  if (!(counts["+"] >= 1)) pri.push("+");

  pri.push(...getLineMissingPieces(g.board, cfg));

  return pri.filter((v) => cfg.allowed.includes(v));
}

function pickNextBlock(g) {
  const cfg = getLevelConfig(g.level);

  if (g.injectQueue?.length) {
    return { value: g.injectQueue.shift() };
  }

  // Stuck helper — less frequent at higher levels
  if (cfg.injectStuckKit && g.blocksSinceClear >= cfg.stuckThreshold) {
    const kit = cfg.equationKits[Math.floor(Math.random() * cfg.equationKits.length)];
    g.injectQueue = [...kit];
    return { value: g.injectQueue.shift() };
  }

  const pri = getSpawnPriority(g);
  if (pri.length && Math.random() < cfg.spawnHelpChance) {
    return { value: pri[Math.floor(Math.random() * pri.length)] };
  }

  if (!g.blockBag?.length) g.blockBag = refillBag(cfg);
  const idx = Math.floor(Math.random() * g.blockBag.length);
  return { value: g.blockBag.splice(idx, 1)[0] };
}

function initSpawnState(g) {
  const cfg = getLevelConfig(g.level);
  g.blockBag = refillBag(cfg);
  const kit = cfg.equationKits[Math.floor(Math.random() * cfg.equationKits.length)];
  g.injectQueue = shuffle([...kit]);
  g.blocksSinceClear = 0;
}

/** Returns array of {r,c} for all cells in valid horizontal or vertical equations */
function findEqs(board) {
  const hits = new Set();
  forEachSegment5((positions) => {
    const seg = readSegment(board, positions);
    if (!seg || !isValidEquationSeg(seg)) return;
    positions.forEach(({ r, c }) => hits.add(`${r},${c}`));
  });
  return [...hits].map((k) => {
    const [row, col] = k.split(",").map(Number);
    return { r: row, c: col };
  });
}

/** Hint: highlight a solvable equation (horizontal or vertical) */
function findHintInfo(board, level) {
  const cfg = getLevelConfig(level);
  const existing = findEqs(board);
  if (existing.length) {
    return {
      cells: existing,
      message: "Swap blocks to complete this equation!",
    };
  }

  let best = null;
  let bestScore = -1;

  forEachSegment5((positions) => {
    for (const kit of cfg.equationKits) {
      let matches = 0;
      let misplaced = 0;
      const cells = [];
      for (let i = 0; i < 5; i++) {
        const { r, c } = positions[i];
        const cell = board[r][c];
        cells.push({ r, c, want: kit[i] });
        if (!cell) continue;
        if (cell.value === kit[i]) matches++;
        else misplaced++;
      }
      if (misplaced > 2) continue;
      const score = matches * 3 - misplaced * 2;
      if (score > bestScore) {
        bestScore = score;
        const isVertical = positions[0].c === positions[1].c;
        const eqText = kit.join(isVertical ? " ↓ " : " ");
        best = {
          cells,
          message: isVertical ? `Make downward: ${eqText}` : `Make: ${kit.join(" ")}`,
        };
      }
    }
  });

  if (best) return best;

  const kit = cfg.equationKits[0];
  return { cells: [], message: `Try: ${kit.join(" ")} (across or down)` };
}

/** Drop all cells in each column to the bottom (Tetris-style gravity) */
function applyGravity(board) {
  const nb = makeBoard();
  for (let c = 0; c < COLS; c++) {
    const stack = [];
    for (let r = 0; r < ROWS; r++) if (board[r][c]) stack.push(board[r][c]);
    stack.forEach((cell, i) => { nb[ROWS - stack.length + i][c] = cell; });
  }
  return nb;
}

const HINT_COST = 5;

// ─── Component ────────────────────────────────────────────────────────────────
export default function Mathtris({
  onExit,
  onHome,
  coins = 0,
  onSpendCoins,
}) {
  // All mutable game state lives in a ref to avoid stale closures in setInterval.
  const G = useRef({
    board:      makeBoard(),
    falling:    null,       // { value, row, col } | null
    next:       { value: "1" },
    score:      0,
    level:      1,
    phase:      "idle",     // "idle" | "playing" | "clearing" | "over"
    selected:   null,       // { r, c } | null
    flashCells: new Set(),  // "r,c" strings being cleared
    message:    "",
    blockBag:       [],
    injectQueue:    [],
    blocksSinceClear: 0,
  });

  // Single state tick forces React re-render from ref mutations
  const [, setTick] = useState(0);
  const draw = useCallback(() => setTick((n) => n + 1), []);

  const [showHint, setShowHint] = useState(false);
  const [hintInfo, setHintInfo] = useState({ cells: [], message: "" });
  const [elapsedTime, setElapsedTime] = useState(0);
  const timerStartRef = useRef(0);

  const dismissHint = useCallback(() => setShowHint(false), []);

  const activateHint = useCallback(() => {
    const g = G.current;
    const info = findHintInfo(g.board, g.level);
    setHintInfo(info);
    setShowHint(true);
    draw();
  }, [draw]);

  const buyHint = useCallback(() => {
    const g = G.current;
    if (showHint || g.phase !== "playing") return;
    const isFree = g.level === 1;
    if (!isFree && onSpendCoins && !onSpendCoins(HINT_COST)) return;
    activateHint();
  }, [showHint, onSpendCoins, activateHint]);

  useEffect(() => {
    const id = setInterval(() => {
      if (G.current.phase === "playing") {
        setElapsedTime(Date.now() - timerStartRef.current);
      }
    }, 50);
    return () => clearInterval(id);
  }, []);

  // stepRef always holds the latest step callback (avoids stale closure in interval)
  const stepRef = useRef(null);

  // ── Clear logic ──────────────────────────────────────────────────────────
  const handleClear = useCallback(
    (board, pts = 100) => {
      const hits = findEqs(board);
      if (!hits.length) return false;
      const g = G.current;
      g.phase = "clearing";
      g.board = board;
      g.flashCells = new Set(hits.map((h) => `${h.r},${h.c}`));
      g.message = MSGS[Math.floor(Math.random() * MSGS.length)];
      dismissHint();
      draw();

      setTimeout(() => {
        const g2 = G.current;
        const cleared = board.map((row, ri) =>
          row.map((cell, ci) => (g2.flashCells.has(`${ri},${ci}`) ? null : cell))
        );
        g2.board = applyGravity(cleared);
        g2.score += hits.length * pts;
        g2.level = Math.floor(g2.score / 700) + 1;
        g2.flashCells = new Set();
        g2.message = "";
        g2.phase = "playing";
        g2.blocksSinceClear = 0;
        if (g2.level > g.level) {
          const newCfg = getLevelConfig(g2.level);
          g2.blockBag = refillBag(newCfg);
          g2.message = `🚀 Level ${g2.level}!`;
        }
        draw();
      }, 780);

      return true;
    },
    [draw, dismissHint]
  );

  // ── Settle a fallen block ────────────────────────────────────────────────
  const doSettle = useCallback(() => {
    const g = G.current;
    const fb = g.falling;
    if (!fb) return;
    const nb = g.board.map((r) => [...r]);
    nb[fb.row][fb.col] = { value: fb.value };
    g.falling = null;
    if (!handleClear(nb)) {
      g.board = nb;
      g.blocksSinceClear += 1;
      draw();
    }
  }, [handleClear, draw]);

  // ── Advance the game one tick ────────────────────────────────────────────
  const doStep = useCallback(() => {
    const g = G.current;
    if (g.phase !== "playing") return;

    if (!g.falling) {
      // Spawn new block
      const col = Math.floor(COLS / 2);
      if (g.board[0][col]) { g.phase = "over"; draw(); return; }
      g.falling = { ...g.next, row: 0, col };
      g.next = pickNextBlock(g);
      draw();
      return;
    }

    const fb = g.falling;
    const nr = fb.row + 1;
    if (nr >= ROWS || g.board[nr][fb.col]) {
      doSettle();
    } else {
      g.falling = { ...fb, row: nr };
      draw();
    }
  }, [doSettle, draw]);

  stepRef.current = doStep;

  // ── Main game loop (single interval, time-based speed) ───────────────────
  useEffect(() => {
    let last = Date.now();
    const id = setInterval(() => {
      const g = G.current;
      if (g.phase !== "playing") { last = Date.now(); return; }
      const speed = getDropInterval(g.level);
      const now = Date.now();
      if (now - last >= speed) {
        last = now;
        stepRef.current();
      }
    }, 40);
    return () => clearInterval(id);
  }, []);

  // ── Keyboard controls ────────────────────────────────────────────────────
  useEffect(() => {
    const onKey = (e) => {
      const g = G.current;
      if (g.phase !== "playing" || !g.falling) return;
      const fb = g.falling;
      if (e.key === "ArrowLeft") {
        e.preventDefault();
        if (fb.col > 0 && !g.board[fb.row][fb.col - 1]) {
          g.falling = { ...fb, col: fb.col - 1 }; draw();
        }
      } else if (e.key === "ArrowRight") {
        e.preventDefault();
        if (fb.col < COLS - 1 && !g.board[fb.row][fb.col + 1]) {
          g.falling = { ...fb, col: fb.col + 1 }; draw();
        }
      } else if (e.key === "ArrowDown") {
        e.preventDefault();
        const nr = fb.row + 1;
        if (nr >= ROWS || g.board[nr][fb.col]) doSettle();
        else { g.falling = { ...fb, row: nr }; draw(); }
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [doSettle, draw]);

  // ── Swap click handler ───────────────────────────────────────────────────
  const onCellClick = useCallback(
    (r, c) => {
      const g = G.current;
      if (g.phase !== "playing") return;
      if (!g.board[r][c]) { g.selected = null; draw(); return; }
      if (g.falling && g.falling.row === r && g.falling.col === c) return;

      if (!g.selected) {
        g.selected = { r, c }; draw();
      } else {
        const { r: sr, c: sc } = g.selected;
        if (sr === r && sc === c) { g.selected = null; draw(); return; }
        const dr = Math.abs(sr - r), dc = Math.abs(sc - c);
        if ((dr === 1 && dc === 0) || (dr === 0 && dc === 1)) {
          // Perform swap
          const nb = g.board.map((row) => [...row]);
          [nb[sr][sc], nb[r][c]] = [nb[r][c], nb[sr][sc]];
          g.selected = null;
          if (!handleClear(nb, 150)) { g.board = nb; draw(); }
        } else {
          g.selected = { r, c }; draw();
        }
      }
    },
    [handleClear, draw]
  );

  // ── On-screen button helpers ─────────────────────────────────────────────
  const moveLeft = () => {
    const g = G.current;
    if (g.phase !== "playing" || !g.falling) return;
    const fb = g.falling;
    if (fb.col > 0 && !g.board[fb.row][fb.col - 1]) { g.falling = { ...fb, col: fb.col - 1 }; draw(); }
  };
  const moveRight = () => {
    const g = G.current;
    if (g.phase !== "playing" || !g.falling) return;
    const fb = g.falling;
    if (fb.col < COLS - 1 && !g.board[fb.row][fb.col + 1]) { g.falling = { ...fb, col: fb.col + 1 }; draw(); }
  };
  const moveDown = () => {
    const g = G.current;
    if (g.phase !== "playing" || !g.falling) return;
    const fb = g.falling;
    const nr = fb.row + 1;
    if (nr >= ROWS || g.board[nr][fb.col]) doSettle();
    else { g.falling = { ...fb, row: nr }; draw(); }
  };

  const startGame = useCallback(() => {
    const g = G.current;
    g.board = makeBoard();
    g.falling = null;
    g.score = 0;
    g.level = 1;
    g.phase = "playing";
    g.selected = null;
    g.flashCells = new Set();
    g.message = "";
    initSpawnState(g);
    g.next = pickNextBlock(g);
    setElapsedTime(0);
    timerStartRef.current = Date.now();
    if (g.level === 1) activateHint();
    else setShowHint(false);
    draw();
  }, [draw, activateHint]);

  // ── Build display board (overlay falling block) ──────────────────────────
  const g = G.current;
  const tierCfg = getLevelConfig(g.level);
  const hudGameState =
    g.phase === "playing" || g.phase === "clearing" ? "playing" : "idle";
  const hintByKey = new Map(
    showHint ? hintInfo.cells.map((h) => [`${h.r},${h.c}`, h]) : []
  );
  const display = g.board.map((r) => r.map((c) => (c ? { ...c } : null)));
  if (g.falling) {
    display[g.falling.row][g.falling.col] = { value: g.falling.value, isFalling: true };
  }

  // ── Shared button style ──────────────────────────────────────────────────
  const ctrlBtn = {
    width: 52, height: 52,
    borderRadius: 12,
    background: "rgba(255,255,255,0.14)",
    color: "#fff",
    border: "2px solid rgba(255,255,255,0.28)",
    fontSize: "1.4rem",
    cursor: "pointer",
    fontFamily: "inherit",
    display: "flex", alignItems: "center", justifyContent: "center",
    userSelect: "none", WebkitUserSelect: "none",
    touchAction: "manipulation",
    transition: "transform 0.08s, background 0.1s",
  };

  // ── Render ───────────────────────────────────────────────────────────────
  return (
    <div
      className="w-full min-h-screen relative font-sans"
      style={{
        background: "linear-gradient(155deg, #0d0b1e 0%, #1a1240 45%, #0c1f3f 100%)",
        fontFamily: "'Fredoka One', 'Comic Sans MS', cursive",
        overflowX: "hidden",
      }}
    >
      <div className="absolute top-0 left-0 w-full z-40 pointer-events-none">
        <div className="pointer-events-auto">
          <GlobalHeader
            coins={coins}
            onBack={onExit}
            isSubScreen
            onHome={onHome}
          />
        </div>
      </div>

      <GameHUD
        title="Mathtris"
        level={g.level}
        elapsedTime={elapsedTime}
        gameState={hudGameState}
        coins={coins}
        onBuyHint={buyHint}
        showHint={showHint}
        hintCost={HINT_COST}
        isFreeHint={g.level === 1}
      />

      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          padding: "7.5rem 8px 20px",
        }}
      >
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Fredoka+One&display=swap');

        @keyframes cellPop {
          0%   { transform: scale(1);   opacity: 1; }
          40%  { transform: scale(1.35);opacity: 0.8; }
          100% { transform: scale(0);   opacity: 0; }
        }
        @keyframes cellBounce {
          0%,100% { transform: translateY(0px); }
          50%     { transform: translateY(-5px); }
        }
        @keyframes glowPulse {
          0%,100% { box-shadow: 0 0 0 3px rgba(255,220,40,0.5), 0 0 14px 4px rgba(255,220,40,0.4); }
          50%     { box-shadow: 0 0 0 4px rgba(255,220,40,0.9), 0 0 24px 8px rgba(255,220,40,0.7); }
        }
        @keyframes msgFloat {
          0%,100% { transform: translate(-50%,-50%) scale(1); }
          50%     { transform: translate(-50%,-50%) scale(1.06); }
        }
        @keyframes titleShine {
          0%,100% { text-shadow: 3px 3px 0 #8B5E00, 0 0 20px rgba(255,215,0,0.4); }
          50%     { text-shadow: 3px 3px 0 #8B5E00, 0 0 40px rgba(255,215,0,0.9); }
        }
        @keyframes fadeIn {
          from { opacity: 0; transform: scale(0.85); }
          to   { opacity: 1; transform: scale(1); }
        }

        .cell-pop   { animation: cellPop    0.78s forwards; }
        .cell-fall  { animation: cellBounce 0.55s infinite; }
        .cell-sel   { animation: glowPulse  0.65s infinite; }
        .cell-hint  { animation: glowPulse  0.65s infinite; box-shadow: 0 0 0 3px rgba(56,189,248,0.9), 0 0 20px 6px rgba(56,189,248,0.55) !important; }
        .msg-box    { animation: msgFloat   0.55s infinite; }
        .game-title { animation: titleShine 2.2s  infinite; }
        .overlay    { animation: fadeIn     0.25s ease-out both; }

        .ctrl-btn:active { transform: scale(0.88) !important; }
        .play-btn:hover  { transform: translateY(-2px) scale(1.03); }
        .play-btn:active { transform: scale(0.95); }
      `}</style>

      <h1
        className="game-title"
        style={{
          color: "#FFD700",
          fontSize: "clamp(1.6rem, 5.5vw, 2.5rem)",
          margin: "0 0 10px",
          letterSpacing: "2px",
          textAlign: "center",
        }}
      >
        🔢 Mathtris 🔢
      </h1>

      {showHint && hintInfo.message && g.phase === "playing" && (
        <div
          style={{
            background: "rgba(8,8,28,0.92)",
            color: "#7DD3FC",
            border: "2px solid rgba(56,189,248,0.6)",
            borderRadius: 14,
            padding: "10px 18px",
            marginBottom: 10,
            fontSize: "0.95rem",
            textAlign: "center",
            maxWidth: 320,
            boxShadow: "0 0 24px rgba(56,189,248,0.25)",
          }}
        >
          💡 {hintInfo.message}
        </div>
      )}

      <div style={{ display: "flex", gap: 14, marginBottom: 12, flexWrap: "wrap", justifyContent: "center" }}>
        {[
          { icon: "⭐", label: "Score", val: g.score, color: "#FFD700" },
          { icon: "🚀", label: "Level", val: g.level,  color: "#4ADE80" },
          ...(g.level <= 10
            ? [{ icon: "📘", label: "Mode", val: tierCfg.label, color: "#7DD3FC" }]
            : []),
        ].map(({ icon, label, val, color }) => (
          <div
            key={label}
            style={{
              background: "rgba(255,255,255,0.09)",
              borderRadius: 14,
              padding: "6px 20px",
              color: "#fff",
              fontSize: "1rem",
              border: "2px solid rgba(255,255,255,0.18)",
              letterSpacing: "0.5px",
            }}
          >
            {icon} {label}:{" "}
            <span style={{ color, fontSize: "1.25rem", marginLeft: 4 }}>{val}</span>
          </div>
        ))}
      </div>

      <div style={{ display: "flex", gap: 16, alignItems: "flex-start", flexWrap: "wrap", justifyContent: "center" }}>

        <div style={{ position: "relative" }}>

          {g.message && (
            <div
              className="msg-box"
              style={{
                position: "absolute",
                top: "38%", left: "50%",
                zIndex: 300,
                fontSize: "1.75rem",
                background: "rgba(8,8,28,0.93)",
                color: "#FFD700",
                padding: "14px 24px",
                borderRadius: 18,
                border: "3px solid #FFD700",
                whiteSpace: "nowrap",
                pointerEvents: "none",
                boxShadow: "0 0 35px rgba(255,215,0,0.4)",
              }}
            >
              {g.message}
            </div>
          )}

          <div
            style={{
              display: "grid",
              gridTemplateColumns: `repeat(${COLS}, ${CELL}px)`,
              gridTemplateRows:    `repeat(${ROWS}, ${CELL}px)`,
              gap: 2,
              background: "#06061a",
              padding: 4,
              borderRadius: 12,
              border: "3px solid rgba(90,80,220,0.35)",
              boxShadow: "0 0 50px rgba(60,50,200,0.25), inset 0 0 30px rgba(0,0,40,0.6)",
            }}
          >
            {display.map((row, ri) =>
              row.map((cell, ci) => {
                const key     = `${ri},${ci}`;
                const isSel   = g.selected?.r === ri && g.selected?.c === ci;
                const isFlash = g.flashCells.has(key);
                const hintCell = hintByKey.get(key);
                const isHint  = !!hintCell;
                const cfg     = cell ? BLOCK_CFG[cell.value] : null;
                const isEmpty = !cfg;

                return (
                  <div
                    key={key}
                    onClick={() => onCellClick(ri, ci)}
                    className={
                      isFlash         ? "cell-pop"  :
                      isSel           ? "cell-sel"  :
                      isHint          ? "cell-hint" :
                      cell?.isFalling ? "cell-fall" : ""
                    }
                    style={{
                      width: CELL, height: CELL,
                      borderRadius: 7,
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      fontSize: "1.45rem",
                      fontWeight: "bold",
                      cursor: cell && !cell.isFalling ? "pointer" : "default",
                      userSelect: "none",
                      WebkitUserSelect: "none",
                      background: cfg
                        ? `linear-gradient(145deg, ${cfg.bg} 40%, ${cfg.shadow})`
                        : isHint
                        ? "rgba(56,189,248,0.12)"
                        : "rgba(255,255,255,0.028)",
                      boxShadow: cfg
                        ? `0 4px 0 ${cfg.shadow}, inset 0 1px 0 rgba(255,255,255,0.38), ${cell?.isFalling ? "0 0 12px rgba(255,255,255,0.35)" : ""}`
                        : "none",
                      color: "#fff",
                      border: cfg
                        ? "1px solid rgba(255,255,255,0.42)"
                        : "1px solid rgba(255,255,255,0.05)",
                      textShadow: cfg ? "1px 2px 4px rgba(0,0,0,0.65)" : "none",
                      transition: "background 0.1s",
                      position: "relative",
                    }}
                  >
                    {isEmpty && !isHint && (
                      <div style={{ width: 3, height: 3, borderRadius: "50%", background: "rgba(255,255,255,0.07)" }} />
                    )}
                    {cell ? cell.value : isHint && hintCell?.want ? (
                      <span style={{ opacity: 0.45, color: "#7DD3FC" }}>{hintCell.want}</span>
                    ) : null}
                  </div>
                );
              })
            )}
          </div>

          {(g.phase === "idle" || g.phase === "over") && (
            <div
              className="overlay"
              style={{
                position: "absolute", inset: 0,
                background: "rgba(4,4,22,0.9)",
                borderRadius: 12,
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                justifyContent: "center",
                gap: 16,
              }}
            >
              <div style={{ fontSize: "3.8rem", lineHeight: 1 }}>
                {g.phase === "over" ? "😅" : "🎮"}
              </div>
              <div style={{ color: "#fff", fontSize: "1.7rem", textAlign: "center" }}>
                {g.phase === "over" ? "Game Over!" : "Mathtris"}
              </div>
              {g.phase === "over" && (
                <div style={{ color: "#FFD700", fontSize: "1.3rem" }}>⭐ Score: {g.score}</div>
              )}
              {g.phase === "idle" && (
                <div style={{ color: "rgba(255,255,255,0.75)", fontSize: "0.95rem", textAlign: "center", lineHeight: 1.7, maxWidth: 240 }}>
                  {g.level <= 10 ? (
                    <>
                      Use only <span style={{ color: "#FECA57" }}>1</span>,{" "}
                      <span style={{ color: "#FECA57" }}>2</span>,{" "}
                      <span style={{ color: "#f7b731" }}>+</span>, and{" "}
                      <span style={{ color: "#a29bfe" }}>=</span>
                      <br />
                      Try <span style={{ color: "#FECA57", fontSize: "1.2rem" }}>1 + 1 = 2</span>
                      {" "}or{" "}
                      <span style={{ color: "#FECA57", fontSize: "1.2rem" }}>2 = 1 + 1</span>
                    </>
                  ) : (
                    <>
                      Make math equations like<br />
                      <span style={{ color: "#FECA57", fontSize: "1.2rem" }}>1 + 2 = 3</span>
                      <br />to clear blocks and score points!
                    </>
                  )}
                </div>
              )}
              <button
                className="play-btn"
                onClick={startGame}
                style={{
                  background: "linear-gradient(135deg, #FF6B6B 0%, #FF9F43 100%)",
                  color: "#fff",
                  border: "none",
                  borderRadius: 50,
                  padding: "13px 40px",
                  fontSize: "1.35rem",
                  cursor: "pointer",
                  fontFamily: "inherit",
                  boxShadow: "0 5px 22px rgba(255,100,50,0.55)",
                  transition: "transform 0.15s, box-shadow 0.15s",
                  letterSpacing: "0.5px",
                }}
              >
                {g.phase === "over" ? "🔄 Try Again!" : "▶ Let's Play!"}
              </button>
            </div>
          )}
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 12, color: "#fff", minWidth: 130, maxWidth: 160 }}>
          <div style={{ background: "rgba(255,255,255,0.08)", borderRadius: 14, padding: "12px 14px", border: "2px solid rgba(255,255,255,0.14)" }}>
            <div style={{ opacity: 0.65, fontSize: "0.85rem", marginBottom: 8 }}>⏭ Next:</div>
            {(() => {
              const nv = g.next.value;
              const nc = BLOCK_CFG[nv];
              return (
                <div style={{ width: CELL, height: CELL, borderRadius: 8, background: `linear-gradient(145deg, ${nc.bg} 40%, ${nc.shadow})`, boxShadow: `0 4px 0 ${nc.shadow}, inset 0 1px 0 rgba(255,255,255,0.38)`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: "1.5rem", color: "#fff", fontWeight: "bold", textShadow: "1px 2px 4px rgba(0,0,0,0.65)", border: "1px solid rgba(255,255,255,0.42)" }}>
                  {nv}
                </div>
              );
            })()}
          </div>

          {g.level <= 5 && (
            <div style={{ background: "rgba(255,255,255,0.07)", borderRadius: 14, padding: "12px 14px", border: "2px solid rgba(255,255,255,0.12)", fontSize: "0.82rem", lineHeight: 1.8 }}>
              <div style={{ color: "#FFD700", fontWeight: "bold", marginBottom: 4, fontSize: "0.9rem" }}>How to play:</div>
              <div>⬅️ ➡️ Move block</div>
              <div>⬇️ Drop faster</div>
              <div>👆 Tap 2 blocks to swap!</div>
              <div style={{ marginTop: 10, borderTop: "1px solid rgba(255,255,255,0.12)", paddingTop: 10, color: "#a0f0c0" }}>
                <div style={{ color: "#FECA57", marginBottom: 4 }}>Make equations (across or down):</div>
                <div>1 + 1 = 2 ✅</div>
                <div>2 = 1 + 1 ✅</div>
                <div style={{ marginTop: 6, opacity: 0.75, fontSize: "0.75rem" }}>
                  Levels 1–10: only 1, 2, +, =
                </div>
              </div>
            </div>
          )}

          <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
            <div style={{ fontSize: "0.75rem", opacity: 0.55, marginBottom: 2 }}>Move falling block:</div>
            <div style={{ display: "flex", gap: 6 }}>
              <button className="ctrl-btn" onClick={moveLeft}  style={ctrlBtn} title="Move Left">⬅️</button>
              <button className="ctrl-btn" onClick={moveDown}  style={ctrlBtn} title="Drop Down">⬇️</button>
              <button className="ctrl-btn" onClick={moveRight} style={ctrlBtn} title="Move Right">➡️</button>
            </div>
          </div>

          {g.selected && (
            <div style={{ background: "rgba(255,220,40,0.15)", borderRadius: 12, padding: "10px 12px", border: "2px solid rgba(255,220,40,0.4)", fontSize: "0.82rem", color: "#FFD700", textAlign: "center", animation: "glowPulse 0.65s infinite" }}>
              ✨ Now tap a block next to it to swap!
            </div>
          )}
        </div>
      </div>

      <div style={{ marginTop: 16, color: "rgba(255,255,255,0.35)", fontSize: "0.78rem", textAlign: "center" }}>
        Tap settled blocks to swap them • Make 5-block equations across or down!
      </div>
      </div>
    </div>
  );
}
