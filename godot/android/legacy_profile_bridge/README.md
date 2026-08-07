# Legacy React profile bridge

`LegacyProfileBridge.kt` is a source-only Godot Android v2 plugin. It creates an
off-screen WebView with `loadDataWithBaseURL("https://localhost/")`, the same
origin used by the previous Capacitor app, and returns only
`localStorage['unicorn_arcade_v1']` to Godot. It never writes or removes legacy
storage. The exported AAR must be built in the Android template/plugin pipeline
before enabling it; no binary artifact is tracked in this repository.

Desktop has no singleton and leaves the import as a safe no-op. Android reports
pending status until a bridge is present and verifies the v5 save after import.
