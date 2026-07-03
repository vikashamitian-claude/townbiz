# Active Tasks

## Sprint 1A - Repo Hygiene and Project Alignment

Status: **Complete**

1. [x] Add Godot 4 `.gitignore` - covers `.godot/`, `build/`, `android/`, export artifacts, OS noise.
2. [x] Stop tracking local/editor/build artifacts - `.godot/` removed from tracking; `build/` ignored.
3. [x] Align `README.md` with active scene (`Game.tscn`), active script (`Game.gd`), autoloads, and stack.
4. [x] Mark legacy prototype files in documentation - `Main`, `MissionUI`, `MissionTest`, `SimTest` documented as legacy/test in README.

### Sprint 1A Audit Findings

- Active entry point: `scenes/Game.tscn` with `scripts/Game.gd`.
- Three autoloads: `GameState`, `Sim`, `MissionManager`.
- `SimConfig.gd` and `MissionData.gd` are active support scripts.
- Legacy files (`Main.tscn`, `Main.gd`) are not referenced by any active code.
- Test files (`MissionTest`, `SimTest`) and unused files (`MissionUI`) are not loaded at runtime.
- `export_presets.cfg` contains a Web preset only. No Android preset exists yet.
- No sensitive data found in tracked files.
- `build/` directory exists on disk with web export artifacts; correctly ignored by `.gitignore`.

## Sprint 1 - Stabilization

Status: **Superseded by the Living Business build below**

Sprint 1 Tasks 3, 4, and 6 (mission progression stability, Chapter 1 alignment,
save/load) are cleared by `BIZTOWN_BUILD_SPEC.md`, approved by Vikash. Task 5
(Android export) remains gated — not started.

## Sprint L1-L5 - "Living Business" Chapter 1 rebuild

Status: **Code complete, execution verification BLOCKED (no Godot binary in the
build session's sandbox — see `.agent_reports/claude_latest.md`)**

Governed by `BIZTOWN_BUILD_SPEC.md` (wins over any older sprint doc it conflicts with).

1. [x] **Sprint L1-A/B** — Signal redesign (mission logic driven only by
   `day_ended`, `inventory_purchased`, `ravi_hired`, `shop_expanded`,
   `month_ended` — never generic `changed`), demand noise, day events,
   supplier cost drift, rent/expansion real stakes. Engine: `scripts/sim/*.gd`,
   `scripts/events/EventEngine.gd`.
2. [x] **Sprint L2** — Living customers (regulars, credit requests, bulk
   orders) + reworked 5-beat Chapter 1 missions. `scripts/mission/*.gd`.
3. [x] **Sprint L3** — Save/load (`scripts/save/SaveManager.gd`) + `Game.gd`
   UI hooks (demand range hint, today/yesterday supplier cost, telegraph
   banner, credit/bulk/lender decision modals, month-end summary, regulars
   HUD chip, Continue/New Game boot choice).
4. [ ] **Sprint L4** — Balance sweep. Harness written (`tests/BalanceSweep.gd`
   + `.tscn`), NOT yet run — needs a real Godot binary. Target: ~70% survive
   Month-End without the lender; expansion affordable day 40-55.
5. [ ] **Human playtest gate** — blocked behind Stage 2/4 test execution above.

**To unblock:** run the test scenes on Vikash's Android device via the Godot
Android editor (see `ANDROID_TESTING.md` — results are drawn on screen for
screenshotting), or run the headless commands in the README on any machine
with Godot, and report the output back.

Android export stays gated regardless of the above.

## Backlog

- Staff hiring
- Inventory
- Warehouse
- Factory
- Multi-product, multi-business, ranks, multiplayer — explicitly out of scope
  for Chapter 1 (see `BIZTOWN_BUILD_SPEC.md`)
