# Save migration: Capacitor to Godot

Both apps use the `unicorn_arcade_v1`-compatible shape: users, last user,
coins, owned/equipped unicorns, furniture inventory/placements, and per-game
progress.

The native Godot app cannot directly read another app's WebView
`localStorage`. Migration is therefore an explicit, offline clipboard transfer:

1. In the existing app, copy/export the `unicorn_arcade_v1` JSON.
2. Open **Profile** in the Godot app.
3. Tap **Import save JSON from clipboard**.
4. Confirm the player name, coins, owned unicorns, furniture, and game levels.
5. Use **Copy save JSON** to create future backups.

`SaveManager.import_json()` accepts either:

- the complete `{ users, lastUser }` database, or
- one legacy user object, imported under the current user (or
  `Imported Player` when no user is active).

Missing fields are normalized automatically. Existing placement IDs, scale,
rotation, and z-order are preserved. Invalid JSON is rejected without changing
the current save.

Saves remain local-only at `user://save.json`; no account, analytics, or child
data is transmitted.
