# Sparkle V1 refinement ledger

## Candidate 01 — rejected

Observed mismatch: several regions were translated twice after being assigned to runtime pivots. The torso/head rendered above the legs, and horn/mane details became detached. The exported hierarchy existed, but the visible model was invalid.

Bounded correction: preserve world transforms with each parent's inverse matrix and apply the same rule to nested pivot empties. Do not alter the anatomical manifest until the hierarchy renders correctly.

Evidence is retained under `previews/sparkle_v1/history/candidate_01_transform_bug/`:

- `validation.json`
- `turntable_sheet.png`
- side/front/top overlays

Candidate 01 strict IoU: side 0.247279, front 0.427270, top 0.264319. These values are diagnostic only because the hierarchy was visibly broken.

## Candidate 02 — rejected

The inverse-parent rule was present, but the newly created pivot matrices had not been evaluated before inversion. Candidate 02 therefore reproduced Candidate 01 exactly. The unchanged metrics and images confirmed that no anatomical comparison was yet meaningful.

Bounded correction: force dependency-graph evaluation before capturing child world transforms and parent inverses, restore the captured world matrix after parenting, and evaluate again.

## Candidate 03 — validator correction required

The dependency-graph correction assembled the model correctly. Side IoU improved from 0.247279 to 0.504530, front improved from 0.427270 to 0.590118 and passed, while top remained exactly 0.264319.

Matched-view inspection showed the top metric was contaminated by the preview ground plane, whose alpha filled the entire top render. This was a validation-harness error; it did not justify changing anatomy.

Bounded correction: hide `PreviewGround` for orthographic validation and restore it only for the beauty turntable.

## Candidate 04 — camera calibration required

Removing preview geometry corrected the top score from 0.264319 to 0.750110, while front remained passing at 0.590118. Side remained 0.504530.

The side heatmap showed the model's ground line about 78 pixels below the concept even though horn height was close. The side camera's chosen world rectangle therefore made the model too large in frame; the mismatch should be corrected in calibration before anatomy.

Bounded correction: solve the vertical world rectangle from the concept ground and horn landmarks, preserve the camera center along the nose-to-tail axis, and expand the horizontal span by the same aspect ratio. The revised side rectangle is `[-2.24, 1.75, -0.695, 4.235]`.

## Candidate 05 — directional graybox accepted

The calibrated rebuild passes all strict directional thresholds:

| View | Strict raw IoU | Tolerant large-form IoU | Threshold |
| --- | ---: | ---: | ---: |
| Side | 0.559090 | 0.762460 | 0.55 |
| Front | 0.590118 | 0.704088 | 0.50 |
| Top | 0.750110 | 0.841926 | 0.42 |

Visual selection rationale: Candidate 05 is the first trustworthy assembled graybox and retains the approved wingless identity, matte palette, horn, mane/tail color masses, flank stars, planted stance, and named runtime pivots. It advances to Godot import validation.

Open items for the next character gate: soften the spherical head-to-muzzle transition, broaden the neck mane, simplify/straighten the hind-leg surface, refine hoof proportions, add production UVs, author a rig, and validate idle/celebrate animation modes. Passing this graybox gate does not approve final topology, deformation, or textures.

## Candidate 06 — slimmer torso requested

Owner review: Sparkle reads a little fat on the eight-angle turntable.

Observable mismatch: the torso is too barrel-shaped in three-quarter views, the head is broader than a horse-like silhouette should be, and the hooves are dramatically wider/deeper than the lower legs. Preserve muzzle length, vertical head profile, expression, mane, tail, limb spacing, and stance.

Bounded edit: reduce torso ring half-widths by roughly 10–15%, reduce vertical radii by roughly 8–13%, and raise ring centers 0.04–0.06 units. Narrow head cross-sections roughly 8–14% without shortening the muzzle or changing the vertical profile. Move ears, eyes, and nostrils inward through manifest controls. Reduce hoof width/depth to roughly 1.2–1.3 times the lower-leg diameter, and rebind flank stars to the revised torso surface. Retain shoulder/hip root burial and nearly the same topline. Perform one full deterministic rebuild and compare the identical cameras against Candidate 05.

Candidate 06 visibly resolves the barrel torso, broad face, and oversized hoof proportions. Front strict IoU improved from 0.590118 to 0.615350 and top improved from 0.750110 to 0.779924. Side strict IoU measured 0.549531, missing the unchanged 0.55 gate by 0.000469; the side large-form IoU remained healthy at 0.736033. Evidence is retained under `previews/sparkle_v1/history/candidate_06_slimmer_draft/`.

## Candidate 07 — side-silhouette micro-correction

Bounded edit: add 0.01 units of vertical radius to only the four central torso rings. Do not change torso half-width, head cross-sections, face-detail placement, hoof scale, camera calibration, limbs, mane, tail, or accessories. This preserves the slimmer three-quarter read while restoring the concept's side belly depth.

Candidate 07 passes every unchanged directional threshold:

| View | Strict raw IoU | Tolerant large-form IoU | Threshold |
| --- | ---: | ---: | ---: |
| Side | 0.550072 | 0.736130 | 0.55 |
| Front | 0.615771 | 0.739853 | 0.50 |
| Top | 0.779924 | 0.867100 | 0.42 |

Visual selection rationale: Candidate 07 retains Candidate 06's materially narrower head, slimmer lateral torso volume, and proportional hooves while recovering the authoritative side silhouette by the smallest recorded geometry change. It replaces Candidate 05 as the approved directional graybox for Godot integration. Production topology, rigging, UVs, and animation remain later gates.
