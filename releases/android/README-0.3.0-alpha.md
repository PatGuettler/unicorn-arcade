# Unicorn Arcade 0.3.0 alpha

This Android alpha completes the playable Godot game registry: all 22 mini-games now launch and implement their core React gameplay rules.

## Playable now

- Number: Unicorn Jump, Sliding Window, Coin Count, Cash Counter, Math Swipe, and Mathtris
- Word: Unicorn Blast, Rhyme Rally, Sentence Sprout, Missing Magic, Sight Spark, Prefix Potion, Vowel Vines, Letter Lift, Syllable Stamp, and Caption Quest
- Mystery: Opposite Orbit, Scramble Spell, Odd One Out, Size Line-Up, and Chain Link
- Arcade: Galaxy Unicorn
- Persistent login, home/category navigation, profile progress, settings, coins, hints, rewards, levels, and local saves

Mathtris includes its live 8x14 board, difficulty unlocks, concurrent falling blocks, swaps, equation clears, and all six companion power behaviors. Galaxy Unicorn includes drag movement, automatic firing, enemy waves, fifth-level bosses, pickups, and lives.

The companion/decor marketplace, Unicorn Alley, room editor, production audio, full device matrix, and final character/environment art remain upcoming. Sparkle is still the review-stage model pending the refinement pass we agreed to revisit.

## Install

- Requires an arm64 Android device running Android 7.0 or newer.
- Download `UnicornArcade-0.3.0-alpha-arm64.apk` and allow installation from the app used to open it if Android prompts you.
- This APK is debug-signed for private playtesting, so Android or Play Protect may identify it as an unknown development build.
- It uses the same package ID and a higher version code than 0.2.0, so it should install as an update.

## Verification

- Package: `com.guettler.unicornarcade`
- Version: `0.3.0-alpha` (`versionCode` 3)
- Size: 31,938,021 bytes (30.46 MiB)
- SHA-256: `A98BBD664FBF9CA26236A6D9398EB3B15017F0C7B621974377B8C37C29DB59BC`
- APK signature: verified with Android Signature Schemes v2 and v3
- Architecture: arm64-v8a only
- Godot deterministic parity checks: 66/66 passed
- Godot runtime interaction checks: 79/79 passed
- Original React unit baseline: 8/8 passed
