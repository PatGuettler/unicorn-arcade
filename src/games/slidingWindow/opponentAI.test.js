import { describe, expect, it } from "vitest";
import { OpponentAI } from "./opponentAI.js";

describe("OpponentAI", () => {
  it("slows down less on higher levels but never below 1 second", () => {
    const ai = new OpponentAI(1, 3, [1, 2, 3, 4, 5]);
    expect(ai.getMoveSpeed()).toBe(2500);

    const fastAi = new OpponentAI(20, 3, [1, 2, 3, 4, 5]);
    expect(fastAi.getMoveSpeed()).toBe(1000);
  });

  it("resets position and running state", () => {
    const ai = new OpponentAI(1, 2, [1, 2, 3, 4]);
    ai.position = 3;
    ai.isRunning = true;
    ai.reset();

    expect(ai.position).toBe(0);
    expect(ai.isRunning).toBe(false);
  });
});
