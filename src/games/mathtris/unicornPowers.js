/** Equation clears needed before the equipped unicorn power can be activated */
export const SOLVES_FOR_POWER = 3;

export const UNICORN_POWER_DEFS = {
  sparkle: {
    name: "Sparkle Burst",
    short: "Clear one equation",
    emoji: "✨",
  },
  rainbow: {
    name: "Rainbow Row",
    short: "Clear the bottom row",
    emoji: "🌈",
  },
  star: {
    name: "Star Beam",
    short: "Clear a full column",
    emoji: "⭐",
  },
  cloud: {
    name: "Cloud Float",
    short: "Slow drops for 18s",
    emoji: "☁️",
  },
  dream: {
    name: "Dream Fix",
    short: "Complete a near-equation",
    emoji: "💫",
  },
  mystic: {
    name: "Mystic Clear",
    short: "Clear the whole board",
    emoji: "🔮",
  },
};

export function getUnicornPowerDef(unicornId) {
  return UNICORN_POWER_DEFS[unicornId] || UNICORN_POWER_DEFS.sparkle;
}

function cellsInRow(board, row) {
  const cells = [];
  for (let c = 0; c < board[0].length; c++) {
    if (board[row][c]) cells.push({ r: row, c });
  }
  return cells;
}

function cellsInColumn(board, col) {
  const cells = [];
  for (let r = 0; r < board.length; r++) {
    if (board[r][col]) cells.push({ r, c: col });
  }
  return cells;
}

function columnWithMostBlocks(board) {
  let bestCol = 0;
  let best = 0;
  for (let c = 0; c < board[0].length; c++) {
    let n = 0;
    for (let r = 0; r < board.length; r++) if (board[r][c]) n++;
    if (n > best) {
      best = n;
      bestCol = c;
    }
  }
  return bestCol;
}

function findBestEquationFix(board, level, helpers) {
  const cfg = helpers.getLevelConfig(level);
  let best = null;
  let bestScore = -1;

  helpers.forEachSegment5((positions) => {
    for (const kit of cfg.equationKits) {
      let matches = 0;
      let wrong = 0;
      for (let i = 0; i < 5; i++) {
        const { r, c } = positions[i];
        const cell = board[r][c];
        if (!cell) continue;
        if (cell.value === kit[i]) matches++;
        else wrong++;
      }
      if (wrong > 1) continue;
      const score = matches * 3 - wrong * 2;
      if (score > bestScore && matches >= 2) {
        bestScore = score;
        best = { positions, kit };
      }
    }
  });

  return best;
}

function applyKitToBoard(board, positions, kit) {
  const nb = board.map((row) => row.map((cell) => (cell ? { ...cell } : null)));
  positions.forEach(({ r, c }, i) => {
    nb[r][c] = { value: kit[i] };
  });
  return nb;
}

function allFilledCells(board) {
  const cells = [];
  for (let r = 0; r < board.length; r++) {
    for (let c = 0; c < board[0].length; c++) {
      if (board[r][c]) cells.push({ r, c });
    }
  }
  return cells;
}

/**
 * @returns {{ ok: boolean, message?: string, flashCells?: {r,c}[], board?: any[][], scoreBonus?: number, slowDropMs?: number, runClearAfter?: boolean }}
 */
export function applyUnicornPower(unicornId, board, context) {
  const def = getUnicornPowerDef(unicornId);
  const { findEqs, ROWS, COLS } = context;

  switch (unicornId) {
    case "sparkle": {
      const hits = findEqs(board);
      if (!hits.length) {
        return { ok: false, message: "No equation yet — keep swapping!" };
      }
      return {
        ok: true,
        message: `${def.emoji} ${def.name}!`,
        flashCells: hits,
        board,
        scoreBonus: hits.length * 80,
        runClearAfter: true,
      };
    }

    case "rainbow": {
      const hits = cellsInRow(board, ROWS - 1);
      if (!hits.length) {
        return { ok: false, message: "Bottom row is empty!" };
      }
      return {
        ok: true,
        message: `${def.emoji} ${def.name}!`,
        flashCells: hits,
        board,
        scoreBonus: hits.length * 35,
        runClearAfter: true,
      };
    }

    case "star": {
      const col = columnWithMostBlocks(board);
      const hits = cellsInColumn(board, col);
      if (!hits.length) {
        return { ok: false, message: "No blocks in columns!" };
      }
      return {
        ok: true,
        message: `${def.emoji} ${def.name}!`,
        flashCells: hits,
        board,
        scoreBonus: hits.length * 45,
        runClearAfter: true,
      };
    }

    case "cloud":
      return {
        ok: true,
        message: `${def.emoji} ${def.name}! Blocks float down slowly…`,
        flashCells: [],
        board,
        scoreBonus: 50,
        slowDropMs: 18000,
        runClearAfter: false,
      };

    case "dream": {
      const fix = findBestEquationFix(board, context.level, context);
      if (!fix) {
        return { ok: false, message: "No puzzle close enough to fix yet!" };
      }
      const fixed = applyKitToBoard(board, fix.positions, fix.kit);
      const hits = findEqs(fixed);
      if (!hits.length) {
        return { ok: false, message: "Couldn't complete a puzzle — try again soon!" };
      }
      return {
        ok: true,
        message: `${def.emoji} ${def.name}!`,
        flashCells: hits,
        board: fixed,
        scoreBonus: hits.length * 120,
        runClearAfter: true,
      };
    }

    case "mystic": {
      const hits = allFilledCells(board);
      if (!hits.length) {
        return { ok: false, message: "Board is already empty!" };
      }
      return {
        ok: true,
        message: `${def.emoji} ${def.name}!`,
        flashCells: hits,
        board,
        scoreBonus: 400 + hits.length * 25,
        runClearAfter: true,
        clearEntireBoard: true,
      };
    }

    default:
      return applyUnicornPower("sparkle", board, context);
  }
}
