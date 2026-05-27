export const NODE_SPACING_Y = 110;
export const PATH_WIDTH = 150;

export const generateLevelData = (lvl) => {
  const len = 5 + lvl * 5;
  const arr = new Array(len).fill(null);
  let curr = 0;
  let last = 0;

  const maxJ = lvl > 5 ? 6 : lvl > 2 ? 4 : 3;

  const allowNegative = lvl >= 15;
  const bigNegative = lvl >= 25;

  const minNeg = 1;
  const maxNeg = bigNegative ? 5 : 2;

  while (curr < len) {
    const doTrick = allowNegative && Math.random() < 0.2 && len - curr > 6;
    let trickPlaced = false;

    if (doTrick) {
      const B = Math.floor(Math.random() * (maxNeg - minNeg + 1)) + minNeg;

      const netProgress = Math.floor(Math.random() * 3) + 1;
      const F = B + netProgress;

      if (curr + F < len && arr[curr + F] === null) {
        arr[curr] = F;
        arr[curr + F] = -B;

        curr += F - B;

        last = -999;
        trickPlaced = true;
        continue;
      }
    }

    let j;
    let attempts = 0;
    do {
      j = Math.floor(Math.random() * maxJ) + 1;
      attempts++;
    } while (
      (j === last && len - curr > j && attempts < 10) ||
      (curr + j < len && arr[curr + j] !== null)
    );

    if (curr + j > len) j = len - curr;

    arr[curr] = j;
    curr += j;
    last = j;
  }

  for (let i = 0; i < len; i++) {
    if (arr[i] === null) {
      if (allowNegative && Math.random() < 0.3) {
        const decB = Math.floor(Math.random() * (maxNeg - minNeg + 1)) + minNeg;
        arr[i] = -decB;
      } else {
        arr[i] = Math.floor(Math.random() * maxJ) + 1;
      }
    }
  }
  return arr;
};

export const generateNodePositions = (length) => {
  const positions = [];
  for (let i = 0; i <= length; i++) {
    const t = i / length;
    const y = i * NODE_SPACING_Y;
    const x =
      window.innerWidth / 6 + Math.sin(t * Math.PI * 3) * (PATH_WIDTH * 1);
    positions.push({ x, y });
  }
  return positions;
};
