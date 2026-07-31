# Unicorn Arcade 0.4.2 alpha

Phone-layout and Galaxy Unicorn follow-up for the complete Godot prototype.

## Fixed

- The equipped companion preview is centered vertically in the available Home hero area.
- Galaxy Unicorn's automatic rainbow bolts remain visible long enough to read on a phone.
- Fast bolts use swept collision so they cannot pass through enemies between frames on tall displays.
- The Home action now says `VIEW HOUSES • UNICORN ALLEY`; the Alley presents all six houses, and tapping an owned house opens its room.

## Validation

- Deterministic parity suite: 75 checks passed.
- Runtime integration suite: 95 checks passed.
- Real-render review at 574x1280 for centered Home, sustained Galaxy bolt, and the six-house Alley.

The companion geometry remains scheduled for the separate refinement pass.

## APK

- File: `UnicornArcade-0.4.2-alpha-arm64.apk`
- Package: `com.guettler.unicornarcade`
- Version: `0.4.2-alpha` (`versionCode` 6)
- Size: 31,984,638 bytes
- SHA-256: `7FB8DAFAC75B37B7727091BBA06016DD186089612A41B8BE5685A2CA357D7456`
- Signature: verified with APK Signature Schemes v2 and v3 (Godot debug signer)
