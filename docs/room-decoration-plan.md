# Unicorn Alley Room Decoration — Improvement Plan

Inspired by **Animal Crossing** (catalog shopping, categories, layering, personality items) and **Stardew Valley** (cozy placement, room identity, seasonal decor).

## Phase 1 — Data & Catalog (AC-style shop foundation)

- [x] Add `category`, `desc`, `rarity`, and placement hints (`layer`, `snapSize`) to every furniture item
- [x] Define `FURNITURE_CATEGORIES` with labels and icons for shop/bag filtering
- [x] Add 20+ unique Animal Crossing–style decor items (cozy, nature, kitchen, wall/floor, rare)
- [x] Create `furnitureUtils.js` (available count, category filter, placement validation, z-order helpers)

## Phase 2 — Marketplace (Nook's Cranny feel)

- [x] Shop Decor tab: category chips + search bar
- [x] Item cards show description, rarity badge, and owned/placed/available counts
- [x] Post-purchase toast with "Go decorate in Unicorn Alley" action
- [x] Sell-back option (50% refund) for unused inventory in shop

## Phase 3 — Room Editor (placement like AC/HM)

- [x] Show unicorn avatar in room (home character presence)
- [x] Tap-to-select items with always-visible edit toolbar (mobile-friendly, not hover-only)
- [x] Z-index layering: Send to Back / Bring to Front
- [x] Optional grid snap toggle (8% grid, like AC placement grid)
- [x] Furniture Bag: filter by category + show only owned items with stock
- [x] Reset Room button (returns all items to bag for this unicorn)
- [x] Validate placement server-side in App (cannot place without inventory)

## Phase 4 — Unicorn Alley & Profile

- [x] Owned houses show decor item count badge on map
- [x] Locked houses open shop with prompt to buy that companion
- [x] Profile shows furniture summary: owned, placed, available per category

## Phase 5 — Polish

- [x] Migrate saved placements to include `zIndex` field for existing users
- [x] README section updated for new decor features

---

## Implementation notes (completed)

| Area | Files |
|------|--------|
| Catalog | `src/data/furnitureCatalog.js` — 99 items with categories, descriptions, rarity |
| Utils | `src/utils/furnitureUtils.js` |
| Shop | `src/components/shared/shopView.jsx` |
| Room | `src/components/unicornAlley/roomView.jsx` |
| Alley | `src/components/unicornAlley/unicornAlleyView.jsx` |
| Profile | `src/components/shared/profileView.jsx` |
| State | `src/App.jsx` — sell, reorder, reset, placement validation |

### New unique items (examples)

Mushroom Log Stool, Mom's Tea Set, Star Fragment Lamp, Crescent Moon Chair, Fairy Light Strand, Royal Crown Display, Golden Toilet, Unicorn Fountain, Glitter Rug, Cloud Pendant Lamp, and more — see `furnitureCatalog.js`.
