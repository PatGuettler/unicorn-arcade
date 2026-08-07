# Unicorn Arcade 0.2.0 alpha

This Android alpha expands the Godot conversion from two playable games to seventeen.

## Playable now

- Number: Coin Count and Cash Counter
- Word: Unicorn Blast, Rhyme Rally, Sentence Sprout, Missing Magic, Sight Spark, Prefix Potion, Vowel Vines, Letter Lift, Syllable Stamp, and Caption Quest
- Mystery: Opposite Orbit, Scramble Spell, Odd One Out, Size Line-Up, and Chain Link
- Persistent login, home/category navigation, profile progress, settings, coins, hints, rewards, levels, and local saves

Unicorn Jump, Sliding Window, Math Swipe, Mathtris, Galaxy Unicorn, the marketplace, Unicorn Alley, and the room editor remain upcoming work. Sparkle is still the directional graybox pending the later model-refinement pass.

## Install

- Requires an arm64 Android device running Android 7.0 or newer.
- Download `UnicornArcade-0.2.0-alpha-arm64.apk` and allow installation from the app used to open it if Android prompts you.
- This APK is debug-signed for private playtesting, so Android or Play Protect may identify it as an unknown development build.
- It uses the same package ID as the earlier prototype and should install as an update. Future alphas may still migrate or reset development save data.

## Verification

- Package: `com.guettler.unicornarcade`
- Version: `0.2.0-alpha` (`versionCode` 2)
- Size: 31,882,631 bytes (30.41 MiB)
- SHA-256: `F19DA40C160A5D056CC3056210520BB70B0E74BB49B42B40866B48BBB153F7C7`
- APK signature: verified with Android Signature Schemes v2 and v3
- Architecture: arm64-v8a
- Godot pure parity checks: 47/47 passed
- Godot runtime interaction checks: 69/69 passed
- Individual new-scene launch smokes: 15/15 passed
- Original React unit baseline: 8/8 passed
