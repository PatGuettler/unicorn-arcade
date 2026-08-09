# Godot performance and maintainability refactor

This branch keeps the minigame-hardening behavior as its baseline.  The original
companion GLBs and 4K artwork remain source assets; runtime companion references
are paths in `CompanionAssetCatalog`, loaded once per path by
`RuntimeAssetLoader`. Static companion surfaces use checked-in thumbnails.

Decor in room buttons and the furniture bag is texture-backed. `DecorPreviewCache`
serializes uncached decor renders through one transient `RoomItemPreview3D` and
caches by `item_id` plus 45-degree yaw. The room keeps its one live animated
companion preview, so normal ten-item rooms stay within the two-viewport budget.

Companion texture import settings use a 2048 runtime size limit, generated mipmaps, VRAM compression, and
explicit normal-map detection. Source textures are not resized or removed.

`ArcadeGameController` is the common interface for every distinct registered
scene. Shared chrome consumes snapshots and state signals rather than probing
game fields for hint and retry state. Save schema v5, registry scene paths, and
the hardening touch/ad behavior remain unchanged.

## Measuring

Run `powershell -ExecutionPolicy Bypass -File tools/benchmark_godot.ps1` for a
five-run editor/import baseline. Results are written under ignored
`.tools/perf-results/`. For the approval gate, append five-run Pixel 9 Pro
start, Home, Marketplace, room, furniture-bag, Mathtris, Galaxy, and Comet
captures with `adb shell dumpsys meminfo` and `adb shell dumpsys gfxinfo`.

Validation recorded 99 parity checks, `RUNTIME_REFACTOR_INTEGRATION_OK`,
`COMPANION ABILITY POPUP TESTS PASSED`, and `AD_LAYOUT_INTEGRATION_OK: 48 checks`.
The benchmark sample `headless-import-20260809-103409.json` completed in
47,682.1 ms with no task-owned survivors. Current and hardening-reference
main-shell checks share the dashboard/game-grid icon accessibility failure;
it is inherited and unchanged. Pixel ADB was unavailable for device gates.

## Android export

A debug AAB was produced at `godot/build/android/UnicornArcade.aab`
(459,571,412 bytes; SHA-256
`1ABCEA97029F82C8C9007C86BB7321FE72823CB40B0E69B0D6A9DFCF0B24D603`). It
contains 1,939 ZIP entries, including `BundleConfig.pb` and the base manifest.
Godot logged `DONE` for the export, but its wrapper did not exit within ten
minutes; the exact task-owned Godot and Java processes were cleaned afterward.
Pixel validation remained unavailable.

Helper boundaries: `ProfileViewComponents` owns profile aggregation,
`WordRoundCatalog` owns pure modular word-round selection, and
`AdBannerRecoveryPolicy` owns stale/recovery predicates. The duplicate root
Poing addon deletion is validated but blocked pending direct, exact destructive
approval; the live plugin remains `godot/addons/admob`.
