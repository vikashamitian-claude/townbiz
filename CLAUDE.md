# BizTown

Godot 4.x GDScript business-sim game. Android-first, portrait 720x1280, touch-only. Chapter 1 = one soap shop that feels alive ("Living Business" build).

## Context read order

1. `FOUNDATION.md` — frozen design laws, highest authority (never edit)
2. `BIZTOWN_BUILD_SPEC.md` — approved Chapter 1 build; wins conflicts with older docs (never edit)
3. `INTEGRATION.md` — autoload order + test command

## Layout

- `scripts/sim/` — `SimConfig.gd` (ALL tunables), `GameState.gd` (data only), `Sim.gd` (rules, `run_day()`)
- `scripts/events/EventEngine.gd`, `scripts/mission/`, `scripts/save/SaveManager.gd`
- Autoloads (order matters): GameState, Events, Sim, Missions, SaveManager
- `scenes/Town3D.tscn` + `scripts/world3d/` — ACTIVE game UI: 3D walkable town (approved pivot, see HUMAN_DECISIONS.md)
- `scenes/Game.tscn` + `scripts/Game.gd` — old 2D UI, kept as fallback until 3D reaches parity
- `tests/TestRunner.tscn` (6 suites), `tests/BalanceSweep.tscn` (100-seed balance)

## Testing reality

Headless: `godot --headless --path . res://tests/TestRunner.tscn` (exit 0 = pass). Cloud sessions have **no Godot binary** — Vikash (the human owner) runs the test scenes in the Godot Android editor on his phone and reports screenshots; results draw on screen. See `ANDROID_TESTING.md`. Never claim a test passed without real output.

## Process

Hard engineering rules auto-load from the `biztown-rules` skill. Work reports go to `.agent_reports/claude_latest.md` (`/stage-report`). Acting on phone test results: `/playtest-results`. Work on the session's `claude/*` branch → draft PR to `main`.
