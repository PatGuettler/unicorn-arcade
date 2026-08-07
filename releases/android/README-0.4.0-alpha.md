# Unicorn Arcade 0.4.0 alpha

This Android alpha contains the full playable Godot conversion checkpoint: all 22 mini-games plus the persistent companion/decor metagame.

## Included

- All 6 Number, 10 Word, 5 Mystery, and 1 Arcade games
- Companion marketplace with six companions, original prices, ownership, equipping, and house gifts
- Decor marketplace with all 107 original catalog records, category filters, search, purchases, and 50% unused-item resale
- Unicorn Alley with six owned/locked houses
- Persistent room editor with shared inventory, drag placement, optional 8% grid snap, 45-degree rotation, resizing, front/back layering, removal, and confirmed reset
- Persistent login, profile progress, settings, coins, hints, rewards, levels, companion ownership, inventory, and rooms

Sparkle and the other art remain prototype/review-stage. Final character anatomy, companion variants, room/furniture assets, effects, and production audio are intentionally still open.

## Install

- Requires an arm64 Android device running Android 7.0 or newer.
- Download `UnicornArcade-0.4.0-alpha-arm64.apk` and allow installation from the app used to open it if Android prompts you.
- This APK is debug-signed for private playtesting, so Android or Play Protect may identify it as an unknown development build.
- It uses the same package ID and a higher version code than 0.3.0, so it should install as an update.

## Verification

- Package: `com.guettler.unicornarcade`
- Version: `0.4.0-alpha` (`versionCode` 4)
- Minimum Android: 7.0 / API 24
- Size: 31,980,542 bytes (30.50 MiB)
- SHA-256: `BEB333D7E7D144F4432C96BDD57C5369402CAF685A68AF637ABFA185856195A3`
- APK signature: verified with Android Signature Schemes v2 and v3
- Architecture: arm64-v8a only
- Godot deterministic parity checks: 75/75 passed
- Godot runtime interaction and transaction checks: 91/91 passed
- Original React unit baseline: 8/8 passed
