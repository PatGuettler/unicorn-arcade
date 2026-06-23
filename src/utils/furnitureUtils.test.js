import { describe, expect, it } from "vitest";
import {
  canPlaceItem,
  getAvailableCount,
  inferCategory,
  reorderZIndex,
} from "./furnitureUtils.js";

describe("furnitureUtils", () => {
  it("infers categories from item ids", () => {
    expect(inferCategory("bed_cloud")).toBe("beds");
    expect(inferCategory("lamp_floor")).toBe("lighting");
    expect(inferCategory("companion_sparkle")).toBe("companions");
  });

  it("tracks available inventory after placement", () => {
    const furniture = {
      inventory: { bed_cloud: 2 },
      placements: { sparkle: [{ itemId: "bed_cloud", instanceId: "a" }] },
    };

    expect(getAvailableCount("bed_cloud", furniture)).toBe(1);
  });

  it("reorders z-index forward and backward", () => {
    const room = [
      { instanceId: "a", zIndex: 1 },
      { instanceId: "b", zIndex: 2 },
      { instanceId: "c", zIndex: 3 },
    ];

    const movedFront = reorderZIndex(room, "b", "front");
    expect(movedFront.map((item) => item.instanceId)).toEqual(["a", "c", "b"]);

    const movedBack = reorderZIndex(room, "b", "back");
    expect(movedBack.map((item) => item.instanceId)).toEqual(["b", "a", "c"]);
  });

  it("prevents placing more items than owned", () => {
    const furniture = {
      inventory: { bed_cloud: 1 },
      placements: { sparkle: [{ itemId: "bed_cloud", instanceId: "a" }] },
    };

    expect(canPlaceItem("bed_cloud", furniture)).toBe(false);
  });
});
