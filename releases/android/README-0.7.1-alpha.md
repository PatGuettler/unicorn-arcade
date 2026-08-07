# Unicorn Arcade 0.7.1 alpha

This accessibility and layout checkpoint uses Android version code 12 and the
same install-compatible signing certificate as 0.5.0, 0.6.1, and 0.7.0.

Certificate SHA-256: `97dcac80c34ab36c9b1e0da8cef5dc87c14911ffdb26d30aa0bc039f1e8be42b`

Included changes:

- Applies readable minimum body and button font sizes throughout every screen and game family.
- Raises phone touch targets to a consistent minimum height while retaining the invisible Alley and room-item hit areas.
- Adds dark text outlines and higher-contrast default, hover, pressed, focus, disabled, and text-input states.
- Corrects reversed ARGB/RGBA values that rendered room overlays maroon instead of translucent navy.
- Fixes the empty Furniture Bag message that wrapped one character per line down the left edge.
- Gives the bag sheet real inner margins and prevents its category strip from clipping into the sheet edge.
- Hides the underlying floating BAG button and room status while the Furniture Bag is open.
- Keeps disabled actions, including the login ENTER button, visibly readable.

Validation: 77 deterministic checks and 137 runtime integration checks pass.
Visual QA covers login, Home, dashboard, category, profile, Marketplace,
Unicorn Alley, room editor, empty Furniture Bag, and all nine distinct game UI
families at the reported 574 x 1280 phone profile.
