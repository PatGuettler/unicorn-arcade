import { FURNITURE, FURNITURE_CATEGORIES } from "../data/furnitureCatalog";

export { FURNITURE, FURNITURE_CATEGORIES };

export const SELL_BACK_RATIO = 0.5;
export const GRID_SNAP_PERCENT = 8;

export function inferCategory(itemId) {
  if (itemId.startsWith("bed_")) return "beds";
  if (itemId.startsWith("table_") || itemId === "desk_office") return "tables";
  if (
    itemId.startsWith("lamp_") ||
    ["lamp", "chandelier", "candle", "lantern", "disco", "flashlight", "studio_spot"].includes(
      itemId
    )
  )
    return "lighting";
  if (itemId.startsWith("rug_") || itemId === "rug") return "rugs";
  if (itemId.startsWith("pet_")) return "pets";
  if (itemId.startsWith("toy_")) return "toys";
  if (
    ["tv_retro", "tv_flat", "pc_gamer", "console", "radio", "phone_retro", "camera", "record_player"].includes(
      itemId
    )
  )
    return "electronics";
  if (itemId.startsWith("xmas_")) return "seasonal";
  if (itemId.startsWith("hall_")) return "seasonal";
  if (["fairy_lights", "skylight_poster", "peach_wall"].includes(itemId)) return "wall";
  if (
    ["mush_stool", "bamboo_speaker", "butterfly_model", "moss_ball", "zen_garden", "terrarium", "hammock"].includes(
      itemId
    )
  )
    return "nature";
  if (
    ["mom_tea", "fruit_basket", "espresso_maker", "ironwood_counter", "brick_oven"].includes(itemId)
  )
    return "kitchen";
  if (
    ["star_lamp", "moon_chair", "crown_display", "golden_toilet", "crystal_ball"].includes(itemId)
  )
    return "luxury";
  if (itemId.startsWith("uni_")) return "unicorn";
  if (["book_stack", "bubble_machine"].includes(itemId)) return "cozy";
  return "cozy";
}

export function getFurnitureDef(itemId) {
  return FURNITURE.find((f) => f.id === itemId);
}

export function getAvailableCount(itemId, furniture) {
  const totalPurchased = furniture.inventory[itemId] || 0;
  let totalPlaced = 0;
  Object.values(furniture.placements).forEach((roomItems) => {
    roomItems.forEach((i) => {
      if (i.itemId === itemId) totalPlaced++;
    });
  });
  return Math.max(0, totalPurchased - totalPlaced);
}

export function getPlacedCount(itemId, furniture) {
  let total = 0;
  Object.values(furniture.placements).forEach((roomItems) => {
    roomItems.forEach((i) => {
      if (i.itemId === itemId) total++;
    });
  });
  return total;
}

export function getOwnedFurniture(furniture) {
  return FURNITURE.filter((f) => (furniture.inventory[f.id] || 0) > 0);
}

export function filterByCategory(items, categoryId) {
  if (!categoryId || categoryId === "all") return items;
  return items.filter((f) => (f.category || inferCategory(f.id)) === categoryId);
}

export function searchFurniture(items, query) {
  const q = query.trim().toLowerCase();
  if (!q) return items;
  return items.filter(
    (f) =>
      f.name.toLowerCase().includes(q) ||
      (f.desc && f.desc.toLowerCase().includes(q)) ||
      (f.category || inferCategory(f.id)).includes(q)
  );
}

export function canPlaceItem(itemId, furniture) {
  return getAvailableCount(itemId, furniture) > 0;
}

export function snapToGrid(value, enabled = true) {
  if (!enabled) return value;
  const step = GRID_SNAP_PERCENT;
  return Math.round(value / step) * step;
}

export function normalizePlacedItem(item, index = 0) {
  return {
    instanceId: item.instanceId,
    itemId: item.itemId,
    x: item.x ?? 50,
    y: item.y ?? 50,
    rotation: item.rotation ?? 0,
    scale: item.scale ?? 1,
    zIndex: item.zIndex ?? index + 1,
  };
}

export function sortByZIndex(items) {
  return [...items].sort((a, b) => (a.zIndex ?? 0) - (b.zIndex ?? 0));
}

export function getNextZIndex(items) {
  if (!items.length) return 1;
  return Math.max(...items.map((i) => i.zIndex ?? 0)) + 1;
}

export function reorderZIndex(items, instanceId, direction) {
  const sorted = sortByZIndex(items);
  const idx = sorted.findIndex((i) => i.instanceId === instanceId);
  if (idx < 0) return items;

  const swapIdx = direction === "front" ? idx + 1 : idx - 1;
  if (swapIdx < 0 || swapIdx >= sorted.length) return items;

  const next = sorted.map((item, i) => {
    if (i === idx) return { ...item, zIndex: sorted[swapIdx].zIndex ?? swapIdx + 1 };
    if (i === swapIdx) return { ...item, zIndex: sorted[idx].zIndex ?? idx + 1 };
    return { ...item, zIndex: item.zIndex ?? i + 1 };
  });
  return sortByZIndex(next);
}

export function getRoomDecorCount(placements, unicornId) {
  return (placements[unicornId] || []).length;
}

export function getFurnitureSummary(furniture) {
  const summary = {};
  FURNITURE_CATEGORIES.forEach((c) => {
    if (c.id === "all") return;
    summary[c.id] = { owned: 0, placed: 0, available: 0 };
  });

  FURNITURE.forEach((f) => {
    const cat = f.category || inferCategory(f.id);
    if (!summary[cat]) summary[cat] = { owned: 0, placed: 0, available: 0 };
    const owned = furniture.inventory[f.id] || 0;
    const placed = getPlacedCount(f.id, furniture);
    summary[cat].owned += owned;
    summary[cat].placed += placed;
    summary[cat].available += Math.max(0, owned - placed);
  });
  return summary;
}

export const RARITY_STYLES = {
  common: "bg-slate-700 text-slate-300",
  uncommon: "bg-emerald-900/80 text-emerald-300",
  rare: "bg-blue-900/80 text-blue-300",
  legendary: "bg-amber-900/80 text-amber-300",
};
