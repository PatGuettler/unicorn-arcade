# Unicorn Arcade 0.8.0 Alpha

Android arm64 playtest build.

## What changed

- Applies the approved illustrated-signage UI direction consistently across the title screen, home, game categories, game selection, profile, marketplace, rooms, furniture bag, and all 22 minigames.
- Adds the production ornate `UNICORN ARCADE` title sign generated from the approved concept.
- Uses high-contrast dark ink on pastel category signs and cream lettering on navy signs.
- Adds consistent warm-gold trim, plum shadows, cyan hover/focus cues, readable disabled states, and phone-friendly touch targets.
- Brightens the magical meadow presentation while retaining the live randomly animated 3D companion.
- Preserves the 0.7.1 gameplay, room functionality, live 3D unicorn/decor previews, and Galaxy Unicorn difficulty curve.

## Install

Install `UnicornArcade-0.8.0-alpha-arm64.apk` on an arm64 Android device. This build uses the same package ID and signing key as 0.5.0 through 0.7.1, so it should install as an in-place update and retain save data.

If Android still reports an install conflict, remove the older build once and install this APK fresh. Removing the app also removes local save data.

Signing certificate SHA-256: `97dcac80c34ab36c9b1e0da8cef5dc87c14911ffdb26d30aa0bc039f1e8be42b`

APK SHA-256: `ec3eab780e7e7b0b9ec800e66dd11a68df0a250066697dda95b9cec70b04580e`

## Verification

- 77 deterministic gameplay/parity checks passed.
- 137 runtime, interaction, 3D-preview, and UI-accessibility checks passed.
- Representative 574 x 1280 phone renders were reviewed for title, home, category, marketplace, room/bag, and Mathtris layouts.
