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

## Sprint 3D - Walkable town presentation (owner-approved pivot, HUMAN_DECISIONS.md)

Status: **Phase 3D-1 code complete — awaiting on-device verification**

1. [x] **Phase 3D-1** — graybox 3D town: touch-joystick player, follow camera,
   soap shop + street + customers as 3D figures, contextual interactions
   (manage at the counter, hire Ravi in person, expand next door in person),
   all HUD/modals/save wired to the unchanged sim engine.
   `scenes/Town3D.tscn`, `scripts/world3d/`. Now the main scene;
   `Game.tscn` kept as 2D fallback.
2. [ ] **Phase 3D-2** — swap graybox for CC0 low-poly assets (Kenney-style;
   Vikash downloads on phone, uploads via GitHub web).
3. [ ] **Phase 3D-3** — interiors, character variety, town life polish.

## Sprint CE - Customer experience variety (owner-approved, HUMAN_DECISIONS.md)

Status: **Code complete, execution verification pending (same blocker as above)**

Not machine learning (asked and clarified) — richer content within the existing engine.

1. [x] Two new day events: `local_holiday` (1-day demand dip), `wedding_season`
   (2-day demand boost). `SimConfig.gd`, `scripts/events/EventEngine.gd`.
2. [x] Recurring customer memory: named credit customers build a track record
   (`GameState.customer_relationships`) that nudges their next reliability
   roll; both UIs flag repeat vs. new names in the credit modal.
3. [x] Regulars trend surfaced as diary/log lines (first regular, +5
   milestones, drops) in both `Game.gd` and `Town3D.gd`.
4. [ ] Re-run the balance sweep once Godot is available — adding two event
   weights shifts every event's relative frequency slightly; §9 targets
   should be reconfirmed.

## Backlog

- Staff hiring
- Inventory
- Warehouse
- Factory
- Multi-product, multi-business, ranks, multiplayer — explicitly out of scope
  for Chapter 1 (see `BIZTOWN_BUILD_SPEC.md`)
