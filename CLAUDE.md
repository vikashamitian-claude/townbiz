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

Headless: `godot --headless --path . res://tests/TestRunner.tscn` (exit 0 = pass). Cloud sessions have **no Godot binary and no network path to fetch one** — Vikash (the human owner) runs the test scenes in the Godot Android editor on his phone and reports screenshots; results draw on screen. See `ANDROID_TESTING.md`. Never claim a test passed without real output.

**What a cloud session CAN verify without Godot:** `pip install gdtoolkit` works (PyPI is reachable). `gdlint <path>` and `gdformat --check <path>` run a real independent GDScript grammar parser — they catch syntax errors (bad brackets/indentation/tokens) across every `.gd` file and are worth running after any GDScript edit. They do NOT know Godot's node/class API, so a script can lint clean and still be wrong about e.g. a method name or node type — this narrows the verification gap, it doesn't close it. Godot 3.x is `apt`-installable here but is a different, incompatible GDScript dialect from this project's Godot 4.x — do not use it to "test" this codebase.

## Process

Hard engineering rules auto-load from the `biztown-rules` skill. Work reports go to `.agent_reports/claude_latest.md` (`/stage-report`). Acting on phone test results: `/playtest-results`. Work on the session's `claude/*` branch → draft PR to `main`.
