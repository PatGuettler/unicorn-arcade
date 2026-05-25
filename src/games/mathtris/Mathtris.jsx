// Mathtris.jsx
// A Tetris-style math game for 6–8 year olds.
// Blocks fall with numbers (+, -, =). Settle blocks, swap adjacent ones,
// and complete equations like  1 + 2 = 3  to clear them!

import { useState, useEffect, useRef, useCallback } from "react";

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

function randBlock() {
  const r = Math.random();
  let v;
  if (r < 0.52)      v = String(Math.floor(Math.random() * 9) + 1); // 1-9
  else if (r < 0.70) v = "+";
  else if (r < 0.85) v = "-";
  else               v = "=";
  return { value: v };
}

const isDigit = (v) => v && /^\d$/.test(v);

/** Returns array of {r,c} for all cells that are part of a valid equation */
function findEqs(board) {
  const hits = new Set();
  for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c <= COLS - 5; c++) {
      const seg = [];
      let ok = true;
      for (let i = 0; i < 5; i++) {
        if (!board[r][c + i]) { ok = false; break; }
        seg.push(board[r][c + i].value);
      }
      if (!ok) continue;
      const [a, b, c2, d, e] = seg;
      let match = false;

      // Pattern: n op n = n  (e.g. 1+2=3)
      if (isDigit(a) && (b === "+" || b === "-") && isDigit(c2) && d === "=" && isDigit(e)) {
        const res = b === "+" ? +a + +c2 : +a - +c2;
        if (res === +e && res >= 0 && res <= 9) match = true;
      }
      // Pattern: n = n op n  (e.g. 3=1+2)
      if (isDigit(a) && b === "=" && isDigit(c2) && (d === "+" || d === "-") && isDigit(e)) {
        const res = d === "+" ? +c2 + +e : +c2 - +e;
        if (res === +a && res >= 0 && res <= 9) match = true;
      }
      if (match) {
        for (let i = 0; i < 5; i++) hits.add(`${r},${c + i}`);
      }
    }
  }
  return [...hits].map((k) => {
    const [row, col] = k.split(",").map(Number);
    return { r: row, c: col };
  });
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

// ─── Component ────────────────────────────────────────────────────────────────
export default function Mathtris() {
  // All mutable game state lives in a ref to avoid stale closures in setInterval.
  const G = useRef({
    board:      makeBoard(),
    falling:    null,       // { value, row, col } | null
    next:       randBlock(),
    score:      0,
    level:      1,
    phase:      "idle",     // "idle" | "playing" | "clearing" | "over"
    selected:   null,       // { r, c } | null
    flashCells: new Set(),  // "r,c" strings being cleared
    message:    "",
  });

  // Single state tick forces React re-render from ref mutations
  const [, setTick] = useState(0);
  const draw = useCallback(() => setTick((n) => n + 1), []);

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
        draw();
      }, 780);

      return true;
    },
    [draw]
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
      g.next = randBlock();
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
      const speed = Math.max(280, 1000 - (g.level - 1) * 80);
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
    g.board = makeBoard(); g.falling = null; g.next = randBlock();
    g.score = 0; g.level = 1; g.phase = "playing";
    g.selected = null; g.flashCells = new Set(); g.message = "";
    draw();
  }, [draw]);

  // ── Build display board (overlay falling block) ──────────────────────────
  const g = G.current;
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
      style={{
        minHeight: "100vh",
        background: "linear-gradient(155deg, #0d0b1e 0%, #1a1240 45%, #0c1f3f 100%)",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        padding: "14px 8px 20px",
        fontFamily: "'Fredoka One', 'Comic Sans MS', cursive",
        overflowX: "hidden",
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
        🔢 Number Drop! 🔢
      </h1>

      <div style={{ display: "flex", gap: 14, marginBottom: 12, flexWrap: "wrap", justifyContent: "center" }}>
        {[
          { icon: "⭐", label: "Score", val: g.score, color: "#FFD700" },
          { icon: "🚀", label: "Level", val: g.level,  color: "#4ADE80" },
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
                const cfg     = cell ? BLOCK_CFG[cell.value] : null;
                const isEmpty = !cfg;

                return (
                  <div
                    key={key}
                    onClick={() => onCellClick(ri, ci)}
                    className={
                      isFlash         ? "cell-pop"  :
                      isSel           ? "cell-sel"  :
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
                    {isEmpty && (
                      <div style={{ width: 3, height: 3, borderRadius: "50%", background: "rgba(255,255,255,0.07)" }} />
                    )}
                    {cell ? cell.value : null}
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
                {g.phase === "over" ? "Game Over!" : "Number Drop!"}
              </div>
              {g.phase === "over" && (
                <div style={{ color: "#FFD700", fontSize: "1.3rem" }}>⭐ Score: {g.score}</div>
              )}
              {g.phase === "idle" && (
                <div style={{ color: "rgba(255,255,255,0.75)", fontSize: "0.95rem", textAlign: "center", lineHeight: 1.7, maxWidth: 240 }}>
                  Make math equations like<br />
                  <span style={{ color: "#FECA57", fontSize: "1.2rem" }}>1 + 2 = 3</span>
                  <br />to clear blocks and score points!
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

          <div style={{ background: "rgba(255,255,255,0.07)", borderRadius: 14, padding: "12px 14px", border: "2px solid rgba(255,255,255,0.12)", fontSize: "0.82rem", lineHeight: 1.8 }}>
            <div style={{ color: "#FFD700", fontWeight: "bold", marginBottom: 4, fontSize: "0.9rem" }}>How to play:</div>
            <div>⬅️ ➡️ Move block</div>
            <div>⬇️ Drop faster</div>
            <div>👆 Tap 2 blocks to swap!</div>
            <div style={{ marginTop: 10, borderTop: "1px solid rgba(255,255,255,0.12)", paddingTop: 10, color: "#a0f0c0" }}>
              <div style={{ color: "#FECA57", marginBottom: 4 }}>Make equations:</div>
              <div>1 + 2 = 3 ✅</div>
              <div>4 - 1 = 3 ✅</div>
              <div>5 = 2 + 3 ✅</div>
              <div>7 = 9 - 2 ✅</div>
            </div>
          </div>

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
        Tap settled blocks to swap them • Make 5-block equations to score!
      </div>
    </div>
  );
}
