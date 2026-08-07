# Unicorn Arcade: Godot conversion evaluation

Date: 2026-07-31

Source snapshot: `df09baa574f2ea5480eced173a61e2a73ec7144d` (`main`)

Upstream: `https://github.com/PatGuettler/unicorn-arcade.git`

## Executive recommendation

Rebuild the application as a Godot 4 project while treating the current React game as an executable gameplay specification. Preserve all level generators, failure rules, timers, rewards, save semantics, room-editor operations, and responsive behavior before changing balance or content. Use a shared Godot game shell plus one scene/controller per game, migrate the metagame first, then port games in risk-based batches.

The conversion is feasible. Most activities are self-contained UI or 2D gameplay, and the current save model is compact. The largest parity risks are Mathtris, its real-time power system, the responsive room editor, touch/swipe input across many aspect ratios, and the absence of an explicit authoritative design specification outside the code.

Art direction is intentionally gated. See [the proposed 3D checkpoint](art-direction/README.md). No production modeling or replacement art should begin until the owner approves or revises it.

## Verified baseline

- Clone preserves upstream history and `origin`; the working tree was clean before these evaluation files were added.
- Unit tests: **3 files, 8 tests passed**.
- Production verification: Vite production build and GitHub Pages verifier passed; **1,441 modules transformed**.
- End-to-end suite: **306 tests passed** in approximately 3.2 minutes.
- E2E coverage spans nine viewport profiles: small phone, Samsung, Samsung compact, Pixel 9, large phone, portrait tablet, large tablet, phone landscape, and tablet landscape.
- Live walkthrough covered login, home, dashboard, number games, Unicorn Jump, companion marketplace, decoration marketplace, Unicorn Alley, and Sparkle's room.
- Browser console showed no warnings or errors during the walkthrough.

The first Playwright attempt failed only because its Chromium binary was not installed. After installing the expected browser build, the full suite passed. This was an environment prerequisite, not an application failure.

## Current product architecture

The source is a React 18/Vite/Tailwind application packaged for mobile with Capacitor 5. State is primarily client-side and persisted in `localStorage` under `unicorn_arcade_v1`. Android native files and a Google Play internal-track workflow are present. A GitHub Pages workflow provides the web deployment. README text mentions iOS support, but no iOS native project is tracked.

The player starts with 1,000 coins and owns/equips Sparkle. Shared completed-level rewards are `10 + (level * 5)` coins. Hints cost 5 coins, except level 1 hints are free. A successful level records level, elapsed time, and date, and raises the maximum unlocked level. The shared timer updates every 50 ms.

There are six companions:

| Companion | Price |
| --- | ---: |
| Sparkle | 0 |
| Rainbow | 500 |
| Star | 1,200 |
| Cloud | 2,500 |
| Dreamer | 5,000 |
| Mystic | 10,000 |

The decoration catalog has 107 entries across 14 categories. Rarity distribution is 42 common, 37 uncommon, 21 rare, and 7 legendary. Decorations sell for 50% of purchase price. Room editing supports a shared inventory, companion-house gifting, placement/removal, dragging, 45-degree rotation, resizing, 8% grid snapping, front/back layer ordering, and per-room reset.

## Gameplay parity specification

### Number games

| Game | Rules that must remain exact |
| --- | --- |
| Unicorn Jump | Path length is `5 + 5*level`. Maximum jump is 3 through level 2, 4 for levels 3–5, and 6 afterward. Negative trick jumps begin at level 15 and grow at level 25. The player must select the indexed jump exactly; any wrong jump fails. Preserve pan/zoom and the free tutorial. |
| Sliding Window | Array length is 15, or 20 after level 5. Values are 0–20 initially, 0–100 after level 2, and -100–100 after level 5. Window size is `min(5, 3 + floor(level/3))`. The player chooses the maximum in each moving window. Rival delay is `max(1000, 2500 - 150*level)` ms. A wrong choice or rival win fails. |
| Coin Count | Targets for levels 1–3 are multiples of five from 5–45 cents; levels 4–8 use 25–124 cents; level 9 onward uses 100–499 cents. Available coins are penny, nickel, dime, and quarter. Exact total wins; overshoot fails. |
| Cash Counter | Targets for levels 1–3 are $1–20, levels 4–8 are $20–99, and level 9 onward is $100–999. Bills are $1, $5, $10, $20, $50, and $100. Exact total wins; overshoot fails. |
| Math Swipe | Problem count is `3 + floor(level/2)`. Levels 1–3 use addition with 1–8; 4–6 use subtraction; 7–10 use larger mixed problems; level 11 onward is 40% multiplication (2–11), 30% addition, and 30% subtraction. A random operand or result is missing and two cards are offered. Tap or swipe over 80 px accepts. One wrong answer fails. |
| Mathtris | 8x14 board, initially filled in the bottom five rows plus up to two more by level. Equations occupy five horizontal/vertical cells as `n op n = n` or `n = n op n`, with single-digit results. Levels 1–10 use only 1, 2, `+`, and `=`; 3 unlocks at level 11, 4 at 13, 5 at 16, digits through 9 at 21+, and subtraction at 24. Falling speed ramps with level/time/drops to a 90 ms minimum. Concurrent falls increase from 1 to 2/3/4/5 at 35/70/110/150 seconds, with one extra at level 12, capped at 5. Taps/swipes swap adjacent fixed blocks; swipes/arrows move falling blocks. Equation clears score `hits*100`; swap clears score `hits*150`; level is `floor(score/700)+1`; only top-out ends the run. Three clears charge a companion power. Preserve each companion's current power behavior. Mathtris currently does not use the shared persistence/reward path. |

### Word and mystery games

The shared target count is `min(12, 3 + floor(1.2*level))`, except Caption Quest caps at 4 and Odd One Out caps at 6.

| Game | Rules that must remain exact |
| --- | --- |
| Unicorn Blast | Type falling words. Start with 3 lives. Fall speed is `0.12 + 0.015*level`; spawn interval is `max(1400, 2800 - 120*level)` ms. |
| Rhyme Rally | Choose the rhyme from four options. |
| Sentence Sprout | Tap shuffled words in sentence order. |
| Missing Magic | Choose the missing word from three options. |
| Sight Spark | Memorize then type a flashed word. Flash duration is `max(800, 2200 - 80*level)` ms. |
| Prefix Potion | Combine prefix/root concepts by choosing the real word. |
| Vowel Vines | Choose the word beginning with the target vowel. |
| Letter Lift | Enter the required letter sequence with the keyboard. |
| Syllable Stamp | Tap syllable parts in the correct order. |
| Caption Quest | Choose a caption for an emoji scene from four options; start with 3 lives. |
| Opposite Orbit | Choose the antonym. |
| Scramble Spell | Tap scrambled letters in correct order. |
| Odd One Out | Identify the outlier among four items; start with 3 lives. |
| Size Line-Up | Tap words from shortest to longest. |
| Chain Link | Choose a word beginning with the prior word's last letter. |

### Future/arcade game

| Game | Rules that must remain exact |
| --- | --- |
| Galaxy Unicorn | Horizontal drag movement and automatic fire. Target kills are `8 + floor(level*2.5)`. Start with 3 lives. Fire interval is `max(120, 280 - 15*level)` ms; spawn interval is `max(600, 2200 - 150*level)` ms. Enemy types are cloud, bat, rock, and skull. A boss appears every fifth level after 60% progress. Pickups drop at 12%; healing caps at 5 lives and the other pickup enables rapid fire. Collision or an escaped enemy costs one life. |

## Art and content inventory

The tracked raster set includes six companion character PNGs, six room backgrounds, one Unicorn Alley JPEG, ten U.S. coin/currency images, the app icon and feature image, and three large generated source images at repository root. Most game objects, enemies, pickups, categories, furniture, and feedback use emoji, Lucide icons, CSS gradients, or canvas effects rather than authored game art. There are no bundled audio assets or local font files.

This means “all new graphics” is a broad replacement program, not a texture swap. It includes:

- Six modeled, rigged, and animated companion characters with approved identity sheets.
- Modular alley and room environment kits plus six room identities.
- 107 furniture/decor objects, with reusable material/shape families to control scope.
- Per-game icons, tokens, hazards, enemies, pickups, panels, tutorials, feedback effects, and accessibility states.
- Original currency artwork that remains denomination-readable without copying the current raster set.
- App/store marketing art, iconography, loading art, and screenshots.
- A replacement font strategy and a complete sound/music pass.

Several source images are unusually large for mobile delivery, including currency textures over 7 MB and room backgrounds around 1.3–2.5 MB. Godot imports should use explicit texture groups, maximum sizes, compression presets, mipmap rules, and atlasing where appropriate.

The Mathtris screen imports Google-hosted Fredoka One at runtime, which conflicts with an offline-first claim. Bundle an appropriately licensed local font in the Godot build.

## Proposed Godot architecture

Use Godot 4 with a portrait-first 2D UI shell and selective 3D viewports for companions, rooms, and alley presentation. Keep learning-game interaction in `Control`/`Node2D` scenes unless 3D materially improves it. This limits mobile cost and helps preserve touch behavior.

Recommended top-level structure:

```text
autoload/
  AppState.gd          # player, economy, settings, migrations
  SaveService.gd       # atomic JSON save/load and version upgrades
  GameRegistry.gd      # metadata and scene lookup for 22 games
  RewardService.gd     # exact reward/hint rules
  AudioService.gd
scenes/
  shell/               # login, home, dashboard, category, result modal
  marketplace/         # companions, decorations, purchase/sell flows
  world/               # alley and room editor
  games/<game>/        # one isolated scene/controller per game
resources/
  companions/          # typed Resource records
  furniture/
  curricula/           # word/sentence/problem content
tests/
  unit/
  integration/
  parity/
```

Data should move from component constants into typed custom `Resource` files or reviewed JSON, depending on authoring needs. Each game scene should implement a small common contract: initialize with player/level/seed, emit success/failure/exit, expose hint behavior, and provide a deterministic debug mode. Do not unify game internals beyond this contract; Mathtris, Galaxy Unicorn, and the simpler question games have very different runtime needs.

Save migration should import `unicorn_arcade_v1` on web builds when available, translate it to a versioned Godot schema, and preserve purchased/equipped companions, coins, progress, decoration inventory, and room layouts. Native builds need a documented transfer decision because Capacitor localStorage does not automatically become Godot `user://` data.

## Migration sequence

1. Freeze the React baseline with screenshots, seeded level fixtures, save examples, and extracted balance constants.
2. Approve the art direction and create calibrated concept sheets/manifests; do not use generated perspective art as anatomical authority.
3. Build the Godot shell, save/economy services, navigation, modal flow, input abstraction, and responsive layout harness.
4. Port one representative simple number game (Coin Count) and one simple word game (Rhyme Rally) to validate the shared contract.
5. Port remaining form/question games, then Unicorn Jump and Sliding Window.
6. Port Galaxy Unicorn, then Mathtris as separately tested real-time systems.
7. Build companion marketplace, decoration marketplace, alley, and room editor; integrate approved 3D assets behind mobile budgets.
8. Add accessibility, audio, localization readiness, analytics/crash reporting if desired, platform exports, and store assets.
9. Run parity verification across the same nine viewport/aspect profiles and target devices before retiring the React build.

## Verification strategy

- Extract deterministic fixtures for every level generator. Seed both implementations and compare accepted answers, failure conditions, progression gates, and difficulty bands.
- Record golden save files covering new player, partial progress, all companions, mixed furniture layouts, and maximum-level edge cases.
- Build headless GDScript tests for reward formulas, catalog transactions, save migration, level generation, and companion powers.
- Add scene-level interaction tests for touch, keyboard, swipe threshold, drag/drop, rotate/resize, grid snap, layering, and pause/resume.
- Capture golden screenshots at the existing nine viewport classes. New art will intentionally differ, but layout geometry, information hierarchy, hit areas, and game-state visibility should be reviewable side by side.
- Profile low/mid-range Android hardware for frame time, memory, texture residency, draw calls, shader compilation, and 3D viewport cost.

## Risks and decisions to resolve

1. **License inconsistency:** README calls the repository private/proprietary while `LICENSE` contains GPLv3. Confirm ownership and intended licensing before distributing a derivative build.
2. **iOS scope:** README mentions iOS, but no iOS native project exists. Decide whether initial Godot delivery is Android + web or includes a new iOS export/signing pipeline.
3. **Save continuity:** decide whether existing browser/Capacitor player data must migrate into native Godot builds and what user-facing transfer mechanism is acceptable.
4. **Mathtris parity:** its concurrent falls, swaps, equation detection, speed ramps, and powers require deterministic fixtures and device-level input tests.
5. **3D scope/performance:** use 3D where it benefits companionship and room ownership; keep educational game boards primarily 2D unless an approved prototype demonstrates equal clarity and performance.
6. **Currency representation:** replacement coin/bill art must remain educationally accurate and legally appropriate. Review current U.S. currency reproduction guidance during production.
7. **Content provenance:** audit word banks, emoji-dependent scenes, fonts, icons, and generated images before store release.
8. **Balance changes:** “exact gameplay” means balance improvements should be deferred until parity is signed off and then tracked as a separate design change.

## Definition of conversion parity

Parity is reached when a fresh and migrated player can traverse the same navigation, play all 22 registered games with matching rules and difficulty bands, receive the same rewards/hints, buy/equip/sell the same catalog content, edit and restore rooms with equivalent operations, and retain progress across relaunches on target platforms. Responsive behavior, touch/keyboard controls, failure/success feedback, and performance must pass agreed device profiles. New graphics may change the presentation, but not the information available to the player or the timing and mechanics that determine outcomes.
