# Unicorn Arcade 0.1.0 prototype

This is an early Android playtest build of the Godot conversion.

## What is playable

- Portrait-first arcade shell and the complete 22-game registry
- Coin Count
- Rhyme Rally
- Shared coin rewards, hint costs, level progression, and local save persistence
- The current Sparkle 3D directional graybox

The other 20 game ports, final character model/animation, production artwork, audio polish, and full parity validation are not complete yet.

## Install

- Requires an arm64 Android device running Android 7.0 or newer.
- Download `UnicornArcade-0.1.0-prototype-arm64.apk` and allow installation from the app used to open it if Android prompts you.
- This APK is debug-signed for private playtesting, so Android or Play Protect may identify it as an unknown development build.
- Future prototypes may reset or migrate local save data.

## Verification

- Package: `com.guettler.unicornarcade`
- Version: `0.1.0-prototype` (`versionCode` 1)
- Size: 31,832,451 bytes (30.36 MiB)
- SHA-256: `780288A1DB8760E7D67317860A9A341B452292E81A64A9F028A3CE26A0338ABD`
- APK signature: verified with Android Signature Schemes v2 and v3
- Architecture: arm64-v8a
- Godot checks: 12/12 passed
