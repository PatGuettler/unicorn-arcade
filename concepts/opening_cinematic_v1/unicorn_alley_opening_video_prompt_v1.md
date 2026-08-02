# Unicorn Arcade opening cinematic v1

## Concept: The Alley Awakens

Use `unicorn_alley_opening_frame_v1.png` as both the Godot boot image and the exact image-to-video starting frame. The still shows all six companions gathered in Unicorn Alley at quiet dawn. The five-second animation gently wakes the same world without changing the composition, then resolves on a soft magical flourish suitable for a quick cut or crossfade into the regular game UI.

The alley was selected over the meadow because its six character-coded doors visually establish the complete cast and the larger Unicorn Arcade world in a single short shot.

## Image-to-video prompt

Create a polished five-second portrait opening cinematic for a children's mobile game, using the supplied image as the exact first frame and visual source of truth.

Preserve the six canonical unicorns exactly: Sparkle in the foreground; Rainbow, Star, Cloud, Dreamer, and winged Mystic in the middle distance. Preserve every coat color, mane and tail color, horn, wing, flank mark, body proportion, face, and eye style. Preserve the exact pastel Unicorn Alley architecture, six ornate doors, cobblestone lane, distant castle, dawn lighting, camera position, storybook gouache/watercolor finish, and portrait framing.

Start with a seamless near-still hold matching the supplied frame exactly—no opening cut, reframing, zoom jump, or character repositioning. Then let the world gently come alive: soft dawn light grows slightly warmer; flowers and leaves stir in a tiny breeze; a few restrained golden sparkles drift upward; the unicorns blink naturally, flick their ears, breathe, and make small individual head or tail movements. Mystic's crystal wings catch one subtle rainbow glint. Add a very slow, smooth camera push forward along the center of the lane with stable perspective and no camera rotation. Keep all six unicorns visible and readable throughout.

During the final second, guide the drifting sparkles into one soft curved sweep toward the distant castle and briefly brighten the warm center of the lane. End on a stable, beautiful frame—no fade to black—so the app can cut or crossfade directly into its normal UI. Motion should feel welcoming, magical, calm, and premium, never frantic or comedic.

No dialogue. No generated text, title, logo, UI, loading bar, subtitles, border, or watermark. Do not add, remove, duplicate, transform, swap, or merge characters. No walking, running, jumping, flying, lip movement, camera shake, rapid zoom, action blur, scene cut, door opening, new props, extra doors, or anatomy changes. Keep horns, hooves, tails, wings, faces, and flank marks structurally stable with no warping, flicker, or extra limbs.

## Timing guide

- **0.00–0.50 s:** Exact still-frame match; only nearly imperceptible breathing and ambient light.
- **0.50–3.75 s:** Slow camera push; natural blinks, ears and tails; breeze, flowers and sparse sparkles.
- **3.75–5.00 s:** Sparkles arc toward the castle; center light warms; camera eases to a stable stop.

## Negative prompt

Text, letters, logo, captions, watermark, UI, loading indicator, new characters, missing character, duplicated unicorn, merged unicorns, altered coat colors, altered mane colors, missing flank marks, missing wings, extra wings, extra legs, distorted anatomy, malformed hooves, warped faces, mismatched eyes, lip-sync, speaking, galloping, jumping, flying, chaotic movement, door opening, extra doors, hard cut, fade to black, camera shake, whip pan, fast zoom, fisheye, motion blur, flicker, frame jitter, style change, photorealism, plastic 3D render.

## Suggested generation settings

- Duration: exactly 5.0 seconds
- Orientation: portrait
- Source framing: 2:3; keep center-safe for taller phone crops
- Camera: one continuous slow dolly forward
- Motion strength: low
- Reference/image fidelity: high
- Frame rate: 30 fps if selectable
- Looping: off
- Audio: off for the first generation pass; add a separate short chime/harp cue later if desired

## Runtime behavior intent

Display the PNG immediately as the engine boot image. When the matching video is decoded and ready, replace the still with video playback from frame zero. Any pointer press, touch, keyboard key, controller button, or Android back action should stop the cinematic immediately and enter the normal game UI. The same transition function should handle both skip and natural playback completion so app initialization runs exactly once.

## Concept-image generation record

Generated with the built-in OpenAI image-generation workflow using the production Unicorn Alley plate plus a temporary identity sheet assembled from the six canonical side-profile concepts. No existing project art was overwritten.
