import { UNICORNS } from "./storage";

export function getCompanionItemId(unicornId) {
  return `companion_${unicornId}`;
}

export function isCompanionItemId(itemId) {
  return typeof itemId === "string" && itemId.startsWith("companion_");
}

export function getCompanionUnicornId(itemId) {
  return itemId.replace("companion_", "");
}

/** Grant one placeable companion per owned unicorn (not sold in shop). */
export function syncCompanionInventory(userData) {
  if (!userData?.furniture || !userData.ownedUnicorns) return userData;
  userData.ownedUnicorns.forEach((unicornId) => {
    const key = getCompanionItemId(unicornId);
    const owned = userData.furniture.inventory[key] || 0;
    if (owned < 1) {
      userData.furniture.inventory[key] = 1;
    }
  });
  return userData;
}

export function getCompanionDef(unicornId) {
  const unicorn = UNICORNS.find((u) => u.id === unicornId);
  if (!unicorn) return null;
  return {
    id: getCompanionItemId(unicornId),
    name: unicorn.name,
    icon: "🦄",
    category: "companions",
    rarity: "legendary",
    desc: `Your ${unicorn.name} — unlocked with this house!`,
    price: 0,
    isCompanion: true,
    unicornId,
    image: unicorn.image,
    scale: unicorn.scale ?? 1,
  };
}
