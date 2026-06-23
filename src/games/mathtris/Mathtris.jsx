// Mathtris.jsx
// A Tetris-style math game for 6–8 year olds.
// Blocks fall with numbers (+, -, =). Settle blocks, swap adjacent ones,
// and complete equations like  1 + 2 = 3  across or down to clear them!

import { useState, useEffect, useRef, useCallback } from "react";
import GlobalHeader from "../../components/shared/globalHeader";
import GameHUD from "../../components/shared/gameHUD";
import { UnicornAvatar } from "../../components/assets/gameAssets";
import { guardTap } from "../../utils/mobileTouch";
import { useMathtrisLayout } from "../../utils/playArea";
import {
  applyUnicornPower,
  getUnicornPowerDef,
  SOLVES_FOR_POWER,
} from "./unicornPowers";

// ─── Constants ────────────────────────────────────────────────────────────────
const COLS = 8;
const ROWS = 14;
const MATRIS_GRID = { cols: COLS, rows: ROWS, gap: 2, gridPadding: 8 };
const SWIPE_MIN_PX = 22;
const TAP_MAX_PX = 12;
const FALLING_SWIPE_PX = 14;
const FALLING_MOVE_MS = 40;

function getFallingList(g) {
  if (!g.fallingList) {
    g.fallingList = g.falling
      ? [{ ...g.falling, id: g.falling.id ?? 1 }]
      : [];
    g.falling = null;
  }
  return g.fallingList;
}

function isFallingAt(g, r, c) {
  return getFallingList(g).some((p) => p.row === r && p.col === c);
}

function findFallingAt(g, r, c) {
  return getFallingList(g).find((p) => p.row === r && p.col === c);
}

function cellBlockedForPiece(g, r, c, pieceId) {
  if (r < 0 || r >= ROWS || c < 0 || c >= COLS) return true;
  if (g.board[r]?.[c]) return true;
  return getFallingList(g).some(
    (p) => p.id !== pieceId && p.row === r && p.col === c
  );
}

function isTopRowFull(board) {
  return board[0].some(Boolean);
}

function endGameTopOut(g) {
  g.phase = "over";
  g.message = "Blocks hit the top!";
  g.fallingList = [];
  g.falling = null;
}

/** More blocks fall at once as the round goes on */
function getConcurrentDropCount(elapsedSec, level) {
  let n = 1;
  if (elapsedSec >= 35) n = 2;
  if (elapsedSec >= 70) n = 3;
  if (elapsedSec >= 110) n = 4;
  if (elapsedSec >= 150) n = 5;
  if (level >= 12) n = Math.min(5, n + 1);
  return n;
}

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

/** Drop interval (ms) — level, blocks placed, and time in round (Tetris-style ramp) */
function getDropInterval(level, dropsPlaced = 0, elapsedSec = 0) {
  let ms;
  if (level <= 10) ms = 950 - (level - 1) * 70;
  else if (level <= 20) ms = 280 - (level - 11) * 7;
  else ms = 200 - (level - 21) * 4;

  ms -= Math.min(240, dropsPlaced * 5);
  ms -= Math.min(200, Math.floor(elapsedSec) * 4);

  return Math.max(90, ms);
}

function getOpenSpawnColumns(board, fallingList = []) {
  const open = [];
  for (let c = 0; c < COLS; c++) {
    if (board[0][c]) continue;
    if (fallingList.some((p) => p.row === 0 && p.col === c)) continue;
    open.push(c);
  }
  return open;
}

/** Random open column; avoid repeating the same lane when possible */
function pickSpawnColumn(board, lastCol = -1, fallingList = []) {
  const open = getOpenSpawnColumns(board, fallingList);
  if (!open.length) return -1;
  if (open.length === 1) return open[0];
  const choices = lastCol >= 0 ? open.filter((c) => c !== lastCol) : open;
  const pool = choices.length ? choices : open;
  return pool[Math.floor(Math.random() * pool.length)];
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

function countTokens(board, fallingList, next, nextQueue = []) {
  const counts = {};
  const add = (v) => {
    if (!v) return;
    counts[v] = (counts[v] || 0) + 1;
  };
  for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c < COLS; c++) {
      if (board[r][c]) add(board[r][c].value);
    }
  }
  (fallingList || []).forEach((p) => add(p.value));
  if (next?.value) add(next.value);
  (nextQueue || []).forEach((n) => add(n.value));
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
        else if (slots[i] !== kit[i]) {
          compatible = false;
          break;
        }
      }
      if (!compatible || !need.length) continue;
      if (need.length <= 2) missing.push(...need);
    }
  });
  return missing;
}

function getSpawnPriority(g) {
  const cfg = getLevelConfig(g.level);
  const counts = countTokens(
    g.board,
    getFallingList(g),
    g.next,
    g.nextQueue
  );
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
  g.powerCharge = 0;
  g.powerReady = false;
  g.dropSlowUntil = 0;
  g.dropsPlaced = 0;
  g.lastSpawnCol = -1;
}

function boardHasEquation(board) {
  return findEqs(board).length > 0;
}

/** Starting pile: bottom rows fully filled (leaves top rows open for falling blocks) */
const START_FILL_ROWS = 5;

function getBottomPileCells(level) {
  const extraRows = Math.min(2, Math.floor(level / 12));
  const fillRows = Math.min(ROWS - 3, START_FILL_ROWS + extraRows);
  const startRow = ROWS - fillRows;
  const cells = [];

  for (let r = startRow; r < ROWS; r++) {
    for (let c = 0; c < COLS; c++) {
      cells.push({ r, c });
    }
  }

  return cells;
}

/** Start with a jumbled pile at the bottom (not pre-solved equations) */
function seedBoardBottomPile(level) {
  const cfg = getLevelConfig(level);

  for (let attempt = 0; attempt < 60; attempt++) {
    const board = makeBoard();
    const cells = getBottomPileCells(level);
    const pool = [];
    while (pool.length < cells.length) {
      pool.push(...refillBag(cfg));
    }
    const tokens = shuffle(pool.slice(0, cells.length));

    cells.forEach(({ r, c }, i) => {
      board[r][c] = { value: tokens[i] };
    });

    if (!boardHasEquation(board)) return board;
  }

  const board = makeBoard();
  const cells = getBottomPileCells(level);
  const tokens = shuffle(refillBag(cfg).slice(0, cells.length));
  cells.forEach(({ r, c }, i) => {
    board[r][c] = { value: tokens[i] };
  });
  return board;
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
        const filledCells = cells.filter(({ r, c }) => board[r][c]);
        best = {
          cells: filledCells,
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
  unicornImage,
  unicornId = "sparkle",
}) {
  const powerDef = getUnicornPowerDef(unicornId);
  // All mutable game state lives in a ref to avoid stale closures in setInterval.
  const G = useRef({
    board:      makeBoard(),
    falling:    null,       // legacy; use fallingList
    fallingList: [],
    next:       { value: "1" },
    nextQueue:  [],
    fallIdSeq:  0,
    activeFallingId: null,
    score:      0,
    level:      1,
    phase:      "idle",     // "idle" | "playing" | "clearing" | "over"
    selected:   null,       // { r, c } | null
    flashCells: new Set(),  // "r,c" strings being cleared
    message:    "",
    blockBag:       [],
    injectQueue:    [],
    blocksSinceClear: 0,
    powerCharge: 0,
    powerReady: false,
    dropSlowUntil: 0,
    dropsPlaced: 0,
    lastSpawnCol: -1,
  });

  // Single state tick forces React re-render from ref mutations
  const [, setTick] = useState(0);
  const draw = useCallback(() => setTick((n) => n + 1), []);

  const [showHint, setShowHint] = useState(false);
  const [hintInfo, setHintInfo] = useState({ cells: [], message: "" });
  const [elapsedTime, setElapsedTime] = useState(0);
  const timerStartRef = useRef(0);
  const { cell, cellFont: layoutCellFont, boardMaxWidth, stackedControls } =
    useMathtrisLayout(MATRIS_GRID);

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

  const powerContextRef = useRef({
    findEqs,
    getLevelConfig,
    forEachSegment5,
    ROWS,
    COLS,
    level: 1,
  });
  powerContextRef.current.level = G.current.level;

  const chargePower = useCallback(
    (g) => {
      g.powerCharge = (g.powerCharge || 0) + 1;
      if (g.powerCharge >= SOLVES_FOR_POWER) {
        g.powerReady = true;
        g.powerCharge = 0;
        return true;
      }
      return false;
    },
    []
  );

  const runClearAnimation = useCallback(
    (board, hits, opts) => {
      const {
        pts = 100,
        scoreBonus,
        message,
        clearEntireBoard = false,
        clearDelay = 780,
      } = opts;
      const g = G.current;
      g.phase = "clearing";
      g.board = board;
      g.flashCells = new Set(hits.map((h) => `${h.r},${h.c}`));
      g.message = message;
      dismissHint();
      draw();

      setTimeout(() => {
        const g2 = G.current;
        if (clearEntireBoard) {
          g2.board = makeBoard();
        } else {
          const cleared = board.map((row, ri) =>
            row.map((cell, ci) =>
              g2.flashCells.has(`${ri},${ci}`) ? null : cell
            )
          );
          g2.board = applyGravity(cleared);
        }
        g2.score += scoreBonus ?? hits.length * pts;
        g2.level = Math.floor(g2.score / 700) + 1;
        g2.flashCells = new Set();
        g2.message = "";
        g2.phase = "playing";
        g2.blocksSinceClear = 0;

        if (isTopRowFull(g2.board)) {
          endGameTopOut(g2);
          draw();
          return;
        }

        if (g2.level > g.level) {
          const newCfg = getLevelConfig(g2.level);
          g2.blockBag = refillBag(newCfg);
          g2.message = `🚀 Level ${g2.level}!`;
        }
        draw();
      }, clearDelay);

      return true;
    },
    [draw, dismissHint]
  );

  // ── Clear logic ──────────────────────────────────────────────────────────
  const handleClear = useCallback(
    (board, pts = 100) => {
      const hits = findEqs(board);
      if (!hits.length) return false;
      const g = G.current;
      const powerReady = chargePower(g);
      const msg = powerReady
        ? `${powerDef.emoji} ${powerDef.name} ready! Tap your unicorn.`
        : MSGS[Math.floor(Math.random() * MSGS.length)];

      return runClearAnimation(board, hits, {
        pts,
        message: msg,
      });
    },
    [chargePower, powerDef.emoji, powerDef.name, runClearAnimation]
  );

  const activatePower = useCallback(() => {
    const g = G.current;
    if (!g.powerReady || g.phase !== "playing") return;

    dismissHint();

    const ctx = {
      ...powerContextRef.current,
      level: g.level,
    };
    const result = applyUnicornPower(unicornId, g.board, ctx);

    if (!result.ok) {
      g.message = result.message;
      const hint = findHintInfo(g.board, g.level);
      if (hint.cells?.length) {
        setHintInfo(hint);
        setShowHint(true);
      }
      draw();
      return;
    }

    g.powerReady = false;
    g.powerCharge = 0;
    g.message = "";

    if (result.slowDropMs) {
      g.dropSlowUntil = Date.now() + result.slowDropMs;
    }

    if (!result.runClearAfter) {
      g.score += result.scoreBonus || 0;
      g.message = result.message;
      draw();
      return;
    }

    getFallingList(g).forEach((p) => {
      g.board[p.row][p.col] = { value: p.value };
    });
    g.fallingList = [];
    g.falling = null;

    runClearAnimation(result.board, result.flashCells, {
      scoreBonus: result.scoreBonus,
      message: result.message,
      clearEntireBoard: result.clearEntireBoard,
      clearDelay: result.clearEntireBoard ? 1100 : 780,
    });
  }, [unicornId, runClearAnimation, draw, dismissHint]);

  const dequeueNextBlock = useCallback((g) => {
    if (!g.nextQueue?.length) {
      g.nextQueue = [pickNextBlock(g)];
    }
    const block = g.nextQueue.shift();
    g.next = g.nextQueue[0] || pickNextBlock(g);
    while (g.nextQueue.length < 3) {
      g.nextQueue.push(pickNextBlock(g));
    }
    return block;
  }, []);

  const settleFallingOntoBoard = useCallback(
    (g, nb, settledCount) => {
      g.dropsPlaced = (g.dropsPlaced || 0) + settledCount;
      if (isTopRowFull(nb)) {
        g.board = nb;
        endGameTopOut(g);
        return true;
      }
      if (!handleClear(nb)) {
        g.board = nb;
        g.blocksSinceClear += settledCount;
      }
      if (isTopRowFull(g.board)) {
        endGameTopOut(g);
        return true;
      }
      return false;
    },
    [handleClear]
  );

  const spawnWave = useCallback(
    (g) => {
      const elapsedSec =
        timerStartRef.current > 0
          ? (Date.now() - timerStartRef.current) / 1000
          : 0;
      const want = getConcurrentDropCount(elapsedSec, g.level);
      const existing = getFallingList(g);
      const spawning = [];
      let lastCol = g.lastSpawnCol;

      for (let i = 0; i < want; i++) {
        const col = pickSpawnColumn(g.board, lastCol, [...existing, ...spawning]);
        if (col < 0) break;
        lastCol = col;
        const block = dequeueNextBlock(g);
        g.fallIdSeq = (g.fallIdSeq || 0) + 1;
        spawning.push({
          id: g.fallIdSeq,
          value: block.value,
          row: 0,
          col,
        });
      }

      if (!spawning.length) {
        endGameTopOut(g);
        return false;
      }

      g.lastSpawnCol = lastCol;
      g.fallingList = [...existing, ...spawning];
      return true;
    },
    [dequeueNextBlock]
  );

  // ── Advance the game one tick ────────────────────────────────────────────
  const doStep = useCallback(() => {
    const g = G.current;
    if (g.phase !== "playing") return;

    const list = getFallingList(g);
    if (!list.length) {
      if (!spawnWave(g)) {
        draw();
        return;
      }
      draw();
      return;
    }

    const nb = g.board.map((r) => [...r]);
    const stillFalling = [];
    let settled = 0;

    for (const p of list) {
      const nr = p.row + 1;
      if (nr >= ROWS || cellBlockedForPiece(g, nr, p.col, p.id)) {
        nb[p.row][p.col] = { value: p.value };
        settled++;
      } else {
        p.row = nr;
        stillFalling.push(p);
      }
    }

    g.fallingList = stillFalling;

    if (settled > 0) {
      if (settleFallingOntoBoard(g, nb, settled)) {
        draw();
        return;
      }
    }
    draw();
  }, [draw, spawnWave, settleFallingOntoBoard]);

  stepRef.current = doStep;

  // ── Main game loop (single interval, time-based speed) ───────────────────
  useEffect(() => {
    let last = Date.now();
    const id = setInterval(() => {
      const g = G.current;
      if (g.phase !== "playing") { last = Date.now(); return; }
      const slow = g.dropSlowUntil > Date.now();
      const elapsedSec =
        timerStartRef.current > 0
          ? (Date.now() - timerStartRef.current) / 1000
          : 0;
      const speed =
        getDropInterval(g.level, g.dropsPlaced || 0, elapsedSec) *
        (slow ? 2.35 : 1);
      const now = Date.now();
      if (now - last >= speed) {
        last = now;
        stepRef.current();
      }
    }, 40);
    return () => clearInterval(id);
  }, []);

  // ── Keyboard controls ────────────────────────────────────────────────────
  const nudgeFallingPiece = useCallback(
    (pieceId, dir) => {
      const g = G.current;
      if (g.phase !== "playing") return;
      const p = getFallingList(g).find((x) => x.id === pieceId);
      if (!p) return;

      if (dir === "left") {
        const nc = p.col - 1;
        if (nc >= 0 && !cellBlockedForPiece(g, p.row, nc, p.id)) {
          p.col = nc;
          draw();
        }
      } else if (dir === "right") {
        const nc = p.col + 1;
        if (nc < COLS && !cellBlockedForPiece(g, p.row, nc, p.id)) {
          p.col = nc;
          draw();
        }
      } else if (dir === "down") {
        const nr = p.row + 1;
        if (nr >= ROWS || cellBlockedForPiece(g, nr, p.col, p.id)) {
          const nb = g.board.map((r) => [...r]);
          nb[p.row][p.col] = { value: p.value };
          g.fallingList = getFallingList(g).filter((x) => x.id !== p.id);
          settleFallingOntoBoard(g, nb, 1);
        } else {
          p.row = nr;
          draw();
        }
      }
    },
    [draw, settleFallingOntoBoard]
  );

  const nudgeActiveOrAll = useCallback(
    (dir) => {
      const g = G.current;
      const list = getFallingList(g);
      if (!list.length) return;
      const target =
        list.find((p) => p.id === g.activeFallingId) || list[0];
      nudgeFallingPiece(target.id, dir);
    },
    [nudgeFallingPiece]
  );

  useEffect(() => {
    const onKey = (e) => {
      const g = G.current;
      if (g.phase !== "playing" || !getFallingList(g).length) return;
      if (e.key === "ArrowLeft") {
        e.preventDefault();
        nudgeActiveOrAll("left");
      } else if (e.key === "ArrowRight") {
        e.preventDefault();
        nudgeActiveOrAll("right");
      } else if (e.key === "ArrowDown") {
        e.preventDefault();
        nudgeActiveOrAll("down");
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [nudgeActiveOrAll]);

  // ── Swap (tap or swipe) ─────────────────────────────────────────────────
  const swapCells = useCallback(
    (sr, sc, tr, tc) => {
      const g = G.current;
      if (g.phase !== "playing") return false;
      if (!g.board[sr]?.[sc] || !g.board[tr]?.[tc]) return false;
      if (isFallingAt(g, sr, sc) || isFallingAt(g, tr, tc)) return false;
      const dr = Math.abs(sr - tr);
      const dc = Math.abs(sc - tc);
      if (!((dr === 1 && dc === 0) || (dr === 0 && dc === 1))) return false;
      const nb = g.board.map((row) => [...row]);
      [nb[sr][sc], nb[tr][tc]] = [nb[tr][tc], nb[sr][sc]];
      g.selected = null;
      if (!handleClear(nb, 150)) {
        g.board = nb;
        draw();
      }
      return true;
    },
    [handleClear, draw]
  );

  const onCellClick = useCallback(
    (r, c) => {
      const g = G.current;
      if (g.phase !== "playing") return;
      if (!g.board[r][c]) {
        g.selected = null;
        draw();
        return;
      }
      if (isFallingAt(g, r, c)) return;

      if (!g.selected) {
        g.selected = { r, c };
        draw();
      } else {
        const { r: sr, c: sc } = g.selected;
        if (sr === r && sc === c) {
          g.selected = null;
          draw();
          return;
        }
        if (swapCells(sr, sc, r, c)) return;
        g.selected = { r, c };
        draw();
      }
    },
    [swapCells, draw]
  );

  const processFallingSwipe = useCallback(
    (start, clientX, clientY) => {
      if (start.fallingId == null) return false;
      const dx = clientX - start.x;
      const dy = clientY - start.y;
      if (Math.abs(dx) < FALLING_SWIPE_PX && dy < FALLING_SWIPE_PX) return false;

      const now = Date.now();
      if (now - (start.lastMoveAt || 0) < FALLING_MOVE_MS) return true;

      if (Math.abs(dx) >= FALLING_SWIPE_PX && Math.abs(dx) >= Math.abs(dy)) {
        nudgeFallingPiece(start.fallingId, dx > 0 ? "right" : "left");
        start.lastMoveAt = now;
        start.x = clientX;
        start.y = clientY;
        return true;
      }
      if (dy >= FALLING_SWIPE_PX && dy > Math.abs(dx)) {
        nudgeFallingPiece(start.fallingId, "down");
        start.lastMoveAt = now;
        start.x = clientX;
        start.y = clientY;
        return true;
      }
      return true;
    },
    [nudgeFallingPiece]
  );

  const gridPointerRef = useRef(null);
  const skipClickRef = useRef(false);

  const handleGridPointerUp = useCallback(
    (e) => {
      const start = gridPointerRef.current;
      gridPointerRef.current = null;
      if (!start || start.pointerId !== e.pointerId) return;

      const dx = e.clientX - start.x;
      const dy = e.clientY - start.y;
      const dist = Math.hypot(dx, dy);
      const g = G.current;
      const { r, c } = start;

      skipClickRef.current = true;
      window.setTimeout(() => {
        skipClickRef.current = false;
      }, 350);

      if (start.fallingId != null) {
        processFallingSwipe(start, e.clientX, e.clientY);
        return;
      }

      if (dist < TAP_MAX_PX) {
        onCellClick(r, c);
        return;
      }
      if (dist < SWIPE_MIN_PX || g.phase !== "playing") return;

      let dr = 0;
      let dc = 0;
      if (Math.abs(dx) > Math.abs(dy)) dc = dx > 0 ? 1 : -1;
      else if (Math.abs(dy) > Math.abs(dx)) dr = dy > 0 ? 1 : -1;
      else return;

      const fallingPiece = findFallingAt(g, r, c) || (start.fallingId
        ? getFallingList(g).find((p) => p.id === start.fallingId)
        : null);
      if (fallingPiece || start.fallingId != null) {
        const id = fallingPiece?.id ?? start.fallingId;
        g.activeFallingId = id;
        if (dc === -1) nudgeFallingPiece(id, "left");
        else if (dc === 1) nudgeFallingPiece(id, "right");
        else if (dr === 1) nudgeFallingPiece(id, "down");
        return;
      }

      const tr = r + dr;
      const tc = c + dc;
      if (tr < 0 || tr >= ROWS || tc < 0 || tc >= COLS) return;

      if (g.board[r][c] && g.board[tr][tc]) {
        swapCells(r, c, tr, tc);
        return;
      }

      if (g.selected && g.board[g.selected.r]?.[g.selected.c] && g.board[tr]?.[tc]) {
        swapCells(g.selected.r, g.selected.c, tr, tc);
      }
    },
    [onCellClick, swapCells, nudgeFallingPiece, processFallingSwipe]
  );

  const onGridPointerMove = useCallback(
    (e) => {
      const start = gridPointerRef.current;
      if (!start || start.pointerId !== e.pointerId) return;
      if (start.fallingId == null) return;
      processFallingSwipe(start, e.clientX, e.clientY);
    },
    [processFallingSwipe]
  );

  const onGridPointerDown = useCallback((e) => {
    const g = G.current;
    if (g.phase !== "playing") return;
    if (e.pointerType === "mouse" && e.button !== 0) return;
    const cell = e.target.closest("[data-mcell]");
    if (!cell) return;
    const r = Number(cell.dataset.r);
    const c = Number(cell.dataset.c);
    const piece = findFallingAt(g, r, c);
    if (piece) g.activeFallingId = piece.id;
    gridPointerRef.current = {
      r,
      c,
      fallingId: piece?.id ?? null,
      x: e.clientX,
      y: e.clientY,
      pointerId: e.pointerId,
      lastMoveAt: 0,
    };
    try {
      e.currentTarget.setPointerCapture(e.pointerId);
    } catch {
      /* ignore */
    }
  }, []);

  const onGridPointerUp = useCallback(
    (e) => {
      handleGridPointerUp(e);
      try {
        e.currentTarget.releasePointerCapture(e.pointerId);
      } catch {
        /* ignore */
      }
    },
    [handleGridPointerUp]
  );

  const moveLeft = () => nudgeActiveOrAll("left");
  const moveRight = () => nudgeActiveOrAll("right");
  const moveDown = () => nudgeActiveOrAll("down");

  const startGame = useCallback(() => {
    const g = G.current;
    g.level = 1;
    g.board = seedBoardBottomPile(g.level);
    g.falling = null;
    g.fallingList = [];
    g.fallIdSeq = 0;
    g.activeFallingId = null;
    g.nextQueue = [];
    g.score = 0;
    g.phase = "playing";
    g.selected = null;
    g.flashCells = new Set();
    g.message = "";
    initSpawnState(g);
    g.next = pickNextBlock(g);
    g.nextQueue = [pickNextBlock(g), pickNextBlock(g), pickNextBlock(g)];
    setElapsedTime(0);
    timerStartRef.current = Date.now();
    setShowHint(false);
    setHintInfo({ cells: [], message: "" });
    draw();
  }, [draw]);

  // ── Build display board (overlay falling block) ──────────────────────────
  const g = G.current;
  powerContextRef.current.level = g.level;
  const hudGameState =
    g.phase === "playing" || g.phase === "clearing" ? "playing" : "idle";
  const hintByKey = new Map(
    showHint
      ? hintInfo.cells
          .filter((h) => g.board[h.r]?.[h.c])
          .map((h) => [`${h.r},${h.c}`, h])
      : []
  );
  const display = g.board.map((r) => r.map((c) => (c ? { ...c } : null)));
  getFallingList(g).forEach((p) => {
    display[p.row][p.col] = {
      value: p.value,
      isFalling: true,
      fallingId: p.id,
    };
  });
  const elapsedForHud =
    timerStartRef.current > 0
      ? (Date.now() - timerStartRef.current) / 1000
      : 0;
  const incomingCount = getFallingList(g).length
    ? 0
    : getConcurrentDropCount(elapsedForHud, g.level);

  const ctrlSize = Math.max(44, Math.min(56, Math.round(cell * 1.2)));
  const ctrlBtn = {
    width: ctrlSize,
    height: ctrlSize,
    borderRadius: 12,
    background: "rgba(255,255,255,0.14)",
    color: "#fff",
    border: "2px solid rgba(255,255,255,0.28)",
    fontSize: "1.35rem",
    cursor: "pointer",
    fontFamily: "inherit",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    userSelect: "none",
    WebkitUserSelect: "none",
    touchAction: "manipulation",
    transition: "transform 0.08s, background 0.1s",
  };
  const cellFont = layoutCellFont;
  const powerCharge = g.powerCharge || 0;
  const powerReady = g.powerReady;
  const cloudActive = g.dropSlowUntil > Date.now();

  // ── Render ───────────────────────────────────────────────────────────────
  return (
    <div
      className="w-full h-app flex flex-col overflow-hidden font-sans"
      data-testid="game-shell"
      style={{
        background: "linear-gradient(155deg, #0d0b1e 0%, #1a1240 45%, #0c1f3f 100%)",
        fontFamily: "'Fredoka One', 'Comic Sans MS', cursive",
      }}
    >
      <div className="shrink-0 z-40 pointer-events-none">
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
        layout="stacked"
      />

      <div className="app-scroll overflow-x-hidden flex flex-col items-center px-2 py-2 pb-safe gap-2">
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
        @keyframes fadeIn {
          from { opacity: 0; transform: scale(0.85); }
          to   { opacity: 1; transform: scale(1); }
        }

        .cell-pop   { animation: cellPop    0.78s forwards; }
        .cell-fall  { animation: cellBounce 0.55s infinite; }
        .cell-sel   { animation: glowPulse  0.65s infinite; }
        .cell-hint  { animation: glowPulse  0.65s infinite; box-shadow: 0 0 0 3px rgba(56,189,248,0.9), 0 0 20px 6px rgba(56,189,248,0.55) !important; }
        .msg-box    { animation: msgFloat   0.55s infinite; }
        .overlay    { animation: fadeIn     0.25s ease-out both; }

        .ctrl-btn:active { transform: scale(0.88) !important; }
        .play-btn:hover  { transform: translateY(-2px) scale(1.03); }
        .play-btn:active { transform: scale(0.95); }
      `}</style>

      <div
        className={`flex items-center justify-center gap-3 w-full mx-auto ${
          stackedControls
            ? "flex-col max-w-full"
            : "flex-col sm:flex-row sm:items-start max-w-[min(100%,480px)]"
        }`}
        style={stackedControls ? { maxWidth: boardMaxWidth } : undefined}
      >

        <div className="relative shrink-0 mx-auto">

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
            className="mathtris-grid"
            onPointerDown={onGridPointerDown}
            onPointerMove={onGridPointerMove}
            onPointerUp={onGridPointerUp}
            onPointerCancel={() => {
              gridPointerRef.current = null;
            }}
            style={{
              display: "grid",
              gridTemplateColumns: `repeat(${COLS}, ${cell}px)`,
              gridTemplateRows: `repeat(${ROWS}, ${cell}px)`,
              gap: 2,
              background: "#06061a",
              padding: 4,
              borderRadius: 12,
              border: "3px solid rgba(90,80,220,0.35)",
              boxShadow: "0 0 50px rgba(60,50,200,0.25), inset 0 0 30px rgba(0,0,40,0.6)",
              maxWidth: "100%",
              touchAction: hudGameState === "playing" ? "none" : "auto",
            }}
          >
            {display.map((row, ri) =>
              row.map((boardCell, ci) => {
                const key     = `${ri},${ci}`;
                const isSel   = g.selected?.r === ri && g.selected?.c === ci;
                const isFlash = g.flashCells.has(key);
                const isHint  = hintByKey.has(key);
                const cfg = boardCell ? BLOCK_CFG[boardCell.value] : null;
                const isEmpty = !cfg;

                return (
                  <div
                    key={key}
                    data-mcell
                    data-r={ri}
                    data-c={ci}
                    onClick={() => {
                      if (skipClickRef.current) return;
                      onCellClick(ri, ci);
                    }}
                    className={
                      isFlash         ? "cell-pop"  :
                      isSel           ? "cell-sel"  :
                      isHint          ? "cell-hint" :
                      boardCell?.isFalling ? "cell-fall" : ""
                    }
                    data-falling={boardCell?.isFalling ? "true" : undefined}
                    style={{
                      width: cell,
                      height: cell,
                      borderRadius: 7,
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      fontSize: cellFont,
                      fontWeight: "bold",
                      cursor: boardCell ? "pointer" : "default",
                      userSelect: "none",
                      WebkitUserSelect: "none",
                      background: cfg
                        ? `linear-gradient(145deg, ${cfg.bg} 40%, ${cfg.shadow})`
                        : isHint
                        ? "rgba(56,189,248,0.12)"
                        : "rgba(255,255,255,0.028)",
                      boxShadow: cfg
                        ? `0 4px 0 ${cfg.shadow}, inset 0 1px 0 rgba(255,255,255,0.38), ${boardCell?.isFalling ? "0 0 12px rgba(255,255,255,0.35)" : ""}`
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
                    {boardCell ? boardCell.value : null}
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
              {unicornImage && (
                <div
                  className="w-24 h-24 sm:w-28 sm:h-28"
                  style={{
                    animation: g.phase === "over" ? "none" : "bounce 1s infinite",
                  }}
                >
                  <UnicornAvatar image={unicornImage} className="w-full h-full" />
                </div>
              )}
              <div style={{ fontSize: unicornImage ? "2.2rem" : "3.8rem", lineHeight: 1 }}>
                {g.phase === "over" ? "😅" : "🎮"}
              </div>
              <div style={{ color: "#fff", fontSize: "1.7rem", textAlign: "center" }}>
                {g.phase === "over" ? "Game Over!" : "Ready?"}
              </div>
              {g.phase === "over" && (
                <>
                  {g.message && (
                    <div style={{ color: "#fca5a5", fontSize: "1rem", textAlign: "center", maxWidth: 280 }}>
                      {g.message}
                    </div>
                  )}
                  <div style={{ color: "#FFD700", fontSize: "1.3rem" }}>⭐ Score: {g.score}</div>
                </>
              )}
              {g.phase === "idle" && (
                <div style={{ color: "rgba(236,72,153,0.9)", fontSize: "0.85rem", textAlign: "center", maxWidth: 260, lineHeight: 1.5 }}>
                  {powerDef.emoji} Your power: <strong>{powerDef.name}</strong> — {powerDef.short}
                </div>
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

        <div
          className={`grid grid-cols-2 sm:grid-cols-1 gap-2 sm:gap-3 text-white w-full shrink-0 ${
            stackedControls ? "max-w-full" : "sm:w-[148px] max-w-[320px]"
          }`}
        >
          {unicornImage && hudGameState === "playing" && (
            <button
              type="button"
              onClick={activatePower}
              onTouchStart={guardTap}
              disabled={!powerReady || g.phase !== "playing"}
              className={`col-span-2 sm:col-span-1 relative z-30 flex items-center gap-2.5 rounded-xl border px-3 py-2.5 text-left transition-all touch-manipulation pointer-events-auto ${
                powerReady && g.phase === "playing"
                  ? "border-pink-400/70 bg-pink-950/60 cursor-pointer hover:brightness-110 active:scale-[0.98] shadow-[0_0_20px_rgba(236,72,153,0.35)]"
                  : "border-pink-500/30 bg-pink-950/40 cursor-default opacity-80"
              }`}
              style={powerReady ? { animation: "glowPulse 1.2s infinite" } : undefined}
            >
              <div className="w-11 h-11 shrink-0">
                <UnicornAvatar image={unicornImage} className="w-full h-full" />
              </div>
              <div className="min-w-0 flex-1">
                <div className="text-xs font-bold text-pink-100 leading-tight">
                  {powerDef.emoji} {powerDef.name}
                </div>
                <div className="text-[0.7rem] text-pink-200/90 leading-snug mt-0.5">
                  {powerReady
                    ? "Tap to use power!"
                    : cloudActive
                    ? "Cloud Float active!"
                    : powerDef.short}
                </div>
                {!powerReady && (
                  <div className="flex gap-1 mt-2">
                    {Array.from({ length: SOLVES_FOR_POWER }, (_, i) => (
                      <div
                        key={i}
                        className="h-1.5 flex-1 rounded-full"
                        style={{
                          background: i < powerCharge
                            ? "linear-gradient(90deg, #f472b6, #ec4899)"
                            : "rgba(255,255,255,0.15)",
                        }}
                      />
                    ))}
                  </div>
                )}
              </div>
            </button>
          )}

          <div style={{ background: "rgba(255,255,255,0.08)", borderRadius: 14, padding: "12px 14px", border: "2px solid rgba(255,255,255,0.14)" }}>
            <div style={{ opacity: 0.65, fontSize: "0.85rem", marginBottom: 8 }}>
              ⏭ Next{incomingCount > 1 ? ` (+${incomingCount - 1} more)` : ""}:
            </div>
            {(() => {
              const nv = g.next.value;
              const nc = BLOCK_CFG[nv];
              return (
                <div style={{ width: cell, height: cell, borderRadius: 8, background: `linear-gradient(145deg, ${nc.bg} 40%, ${nc.shadow})`, boxShadow: `0 4px 0 ${nc.shadow}, inset 0 1px 0 rgba(255,255,255,0.38)`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: cellFont, color: "#fff", fontWeight: "bold", textShadow: "1px 2px 4px rgba(0,0,0,0.65)", border: "1px solid rgba(255,255,255,0.42)" }}>
                  {nv}
                </div>
              );
            })()}
          </div>

          {g.level <= 5 && (
            <div className="col-span-2 sm:col-span-1" style={{ background: "rgba(255,255,255,0.07)", borderRadius: 14, padding: "12px 14px", border: "2px solid rgba(255,255,255,0.12)", fontSize: "0.82rem", lineHeight: 1.8 }}>
              <div style={{ color: "#FFD700", fontWeight: "bold", marginBottom: 4, fontSize: "0.9rem" }}>How to play:</div>
              <div>🎲 Blocks fall in random columns</div>
              <div>⬅️ ➡️ Move block</div>
              <div>⬇️ Drop faster</div>
              <div>👆 Tap or swipe to swap blocks!</div>
              <div>👆 Swipe falling blocks to move (works while they drop!)</div>
              <div>⚠️ Blocks reach the top = game over</div>
              <div>⏱️ Long rounds drop more blocks at once!</div>
              <div style={{ opacity: 0.75, fontSize: "0.75rem" }}>Speed rises over time!</div>
              <div>🦄 Solve 3 equations → tap unicorn to blast!</div>
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

          <div className="flex flex-col items-center gap-2 w-full bg-white/5 rounded-xl p-3 border border-white/10 pb-safe">
            <div className="text-xs opacity-60">Move falling block</div>
            <div className="flex gap-3 justify-center w-full">
              <button type="button" className="ctrl-btn" onClick={moveLeft}  style={ctrlBtn} title="Move Left">⬅️</button>
              <button type="button" className="ctrl-btn" onClick={moveDown}  style={ctrlBtn} title="Drop Down">⬇️</button>
              <button type="button" className="ctrl-btn" onClick={moveRight} style={ctrlBtn} title="Move Right">➡️</button>
            </div>
          </div>

          {showHint && hintInfo.message && g.phase === "playing" && (
            <div
              className="col-span-2 sm:col-span-1"
              style={{
                background: "rgba(8,8,28,0.92)",
                color: "#7DD3FC",
                border: "2px solid rgba(56,189,248,0.6)",
                borderRadius: 12,
                padding: "10px 12px",
                fontSize: "0.8rem",
                lineHeight: 1.5,
                textAlign: "center",
                boxShadow: "0 0 20px rgba(56,189,248,0.2)",
              }}
            >
              💡 {hintInfo.message}
            </div>
          )}

          {g.selected && (
            <div className="col-span-2 sm:col-span-1" style={{ background: "rgba(255,220,40,0.15)", borderRadius: 12, padding: "10px 12px", border: "2px solid rgba(255,220,40,0.4)", fontSize: "0.82rem", color: "#FFD700", textAlign: "center", animation: "glowPulse 0.65s infinite" }}>
              ✨ Tap or swipe to a neighbor to swap!
            </div>
          )}
        </div>
      </div>

      <p className="text-center text-white/35 text-xs px-2 pb-1 max-w-sm">
        Random columns • Swap to solve • Falls faster as you play
      </p>
      </div>
    </div>
  );
}
