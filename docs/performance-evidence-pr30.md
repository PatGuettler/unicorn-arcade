# PR30 performance evidence

## Method

`tools/benchmark_pr30.ps1` runs `godot/tests/performance_probe_pr30.tscn` through the project-local Godot wrapper. Each label used three fresh engine processes, five warmups, and 15 measured samples per scenario (45 aggregate samples). Results are deterministic JSON under ignored `.tools/perf-results/`, with median/p95 wall time, repeated-navigation static-memory deltas, machine metadata, process IDs, timeout/modal cleanup, and survivor checks.

Machine: Windows 10.0.19045; Intel i7-6700K 4.00 GHz; 8 logical CPUs; Godot 4.7.1 stable official `a13da4feb`; rendered captures used NVIDIA GeForce GTX 1070 / OpenGL 3.3. Baseline: `.tools/perf-results/pr30-baseline-aggregate-20260810-192057.json`; candidate: `.tools/perf-results/pr30-candidate-aggregate-20260810-193031.json`.

## Decision table

Times are microseconds. The retention rule was targeted p95 **or** CPU/median improvement of at least 15%, stable memory, no attributable unrelated regression, and clean behavior/render evidence.

| Candidate | Baseline median / p95 | Candidate median / p95 | Change | Decision |
| --- | ---: | ---: | ---: | --- |
| Mathtris immutable tile-style cache | 42,771.2 / 56,509.9 | 26,370.1 / 58,004.1 | median -38.3%; p95 +2.6% | Accept: CPU/median gate met; p95 within 5% |
| Comet geometry only on resize | 27.305 / 45.073 | 14.820 / 20.860 | median -45.7%; p95 -53.7% | Accept |
| Word timer text once per displayed tenth | 5.169 / 10.583 | 2.644 / 3.761 | median -48.9%; p95 -64.5% | Accept |
| Galaxy allocation-free removals | 850.950 / 1,242.025 | 910.325 / 1,631.725 | median +7.0%; p95 +31.4% | Reject and revert |
| Inactive GameExperience candidate | 2.414 / 4.583 | 1.989 / 3.198 | measured path already returns early | Reject/no code change |
| Accessibility/safe-area candidate | 829.013 / 2,398.013 | 512.838 / 775.613 | existing scene-change scoping already prunes IDs | Reject/no code change |

Profile, marketplace, startup, and Galaxy were also exercised as unrelated controls. A reduced confirmation run (`pr30-candidate-aggregate-20260810-193317.json`) showed broad workstation-tail volatility even after Galaxy and Mathtris were temporarily reverted, including untouched scenarios; therefore only repeatable, source-local targeted improvements were attributed. Marketplace's first candidate p95 outlier (+17.3% while its median improved 7.3%) is recorded rather than claimed as a candidate-caused regression. Static-memory deltas were identical in every process: baseline `[-88,-88,-88]` bytes and candidate `[-88,-88,-88]` bytes after 80 repeated main/market navigation cycles.

The probe covers startup/scene construction, profile filter+scroll, marketplace refresh+scroll, Galaxy simulation/collision, Mathtris refresh, Comet layout, Word timer update, inactive GameExperience processing, and accessibility/safe-area transitions.

## Behavior and pixels

Focused assertions in `runtime_gameplay_correctness_integration.gd` verify Mathtris cache reuse and visual variants, Comet resize invalidation versus per-frame movement, and Word timer tenth transitions. Deterministic rendered captures use seed 3001, freeze time-driven processing after setup, and explicitly size a SubViewport to 450x1280 or 720x1280.

Capture pairs are retained under ignored `.tools/captures/`: `pr30-before`/`pr30-after` (Mathtris), `pr30-before-deterministic`/`pr30-after-deterministic` (Comet), and `pr30-word-before-seeded`/`pr30-word-after-seeded` (Word).

| Surface | 450x1280 SHA-256 | 720x1280 SHA-256 | Result |
| --- | --- | --- | --- |
| Mathtris | `4D85DEBB8AC7A0245B2FCA2A23511283ED50A0F3EFBC80B78108DBE238CDF409` | `6A5348F2CB69E22E0E1FC4C9599085C83B49F205AD6D3CF0BA2B7EB76107A130` | before = after |
| Comet Math Rescue | `69898C9308B489B8FB567D7B9BF93C080C93EF99B086619F95DF1422F1AFB9E7` | `E03647018415930A8BDF79BB6CC5D406011D4AFE6A3A66B97C2058E3005D299D` | before = after |
| Opposite Orbit (Word timer) | `5ABFF68FF29483DEF90D4BF73197BE8E2DC0C454B9F143665197728700403744` | `5D7BF76DBE628D3E68FAB55F077025CFF7CDFCC5A1F872464F0D34D26D94F0F0` | before = after |

Pixel/ADB collection was unavailable for this PR. The same-machine Windows gate is authoritative here; Android/device performance remains the PR32 release gate.

## Validation

The explicit CI manifest was run through `tools/run_godot.cmd`: parser, focused refactor/runtime suites, gameplay/level/outcome/profile/persistence suites, word/number/meta/shell suites, Galaxy pause, ad/layout/scope tests, and parity. All task-started processes were scoped to the project-local engine and checked for survivors; no external CodexCache Godot process was touched.

An accidentally invoked historical `runtime_integration.tscn` (not part of the established bounded manifest) reproduced its known callback-spam/native-shutdown failure. Its raw signal-11 log and exact engine/command/phase metadata are preserved at `.tools/crash-evidence/pr30-runtime-integration-20260810-195955/`. Per standing project guidance it was excluded, not rerun, and caused no gameplay change; the bounded replacement suites above all passed.
