import { describe, expect, it } from "vitest";
import { generateLevelData } from "./levelUtils.js";

describe("generateLevelData", () => {
  it("returns an array with expected length for a level", () => {
    const level = 3;
    const data = generateLevelData(level);
    expect(Array.isArray(data)).toBe(true);
    expect(data.length).toBe(5 + level * 5);
  });

  it("fills every slot with a non-null jump value", () => {
    const data = generateLevelData(1);
    expect(data.every((value) => value !== null)).toBe(true);
  });
});
