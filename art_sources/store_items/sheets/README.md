# Store item model sheets

These are the mobile-optimized, separated Blender sources derived from the 17 Meshy reconstruction GLBs supplied on 2026-08-02. Each sheet folder contains the editable `.blend` source and a JSON report with the source filename, SHA-256, split thresholds, catalog IDs, and polygon counts.

- Runtime scenes: `godot/assets/models/store/sheets/`
- Visual review sheets: `previews/store_items/sheets/`
- Reproducible processing and audit tools: `tools/store_items/`
- Authored runtime lookup: `godot/data/store_model_catalog.json`

The supplied files cover 101 catalog items. Together with the six earlier `store1_mobile.glb` models, the game now loads all 107 store props lazily from authored models. The redownloaded Halloween sheet supplies `hall_ghost`, `hall_skull`, `hall_web`, `hall_spider`, `hall_bat`, and `hall_alien`, so no catalog prop relies on a procedural fallback.

`store_glb_audit.json` records the successful re-import audit for the model collection.
