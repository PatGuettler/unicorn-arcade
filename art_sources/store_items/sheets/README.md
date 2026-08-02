# Store item model sheets

These are the mobile-optimized, separated Blender sources derived from the 16 Meshy reconstruction GLBs supplied on 2026-08-02. Each sheet folder contains the editable `.blend` source and a JSON report with the source filename, SHA-256, split thresholds, catalog IDs, and polygon counts.

- Runtime scenes: `godot/assets/models/store/sheets/`
- Visual review sheets: `previews/store_items/sheets/`
- Reproducible processing and audit tools: `tools/store_items/`
- Authored runtime lookup: `godot/data/store_model_catalog.json`

The supplied files cover 95 catalog items. Together with the six earlier `store1_mobile.glb` models, the game now loads 101 authored store props lazily. Sheet 12 was not supplied, so `hall_ghost`, `hall_skull`, `hall_web`, `hall_spider`, `hall_bat`, and `hall_alien` intentionally retain their procedural fallbacks.

`store_glb_audit.json` records the successful re-import audit for all 95 new items.
