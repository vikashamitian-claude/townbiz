---
name: biztown-rules
description: BizTown engineering guardrails. Apply whenever writing or modifying GDScript, scenes, sim/mission/event/save code, or tuning game balance in this repo.
user-invocable: false
---

# BizTown hard rules (violations = rejected work)

Authority order: FOUNDATION.md (frozen) > BIZTOWN_BUILD_SPEC.md (approved build) > older sprint docs. Never edit FOUNDATION.md or BIZTOWN_BUILD_SPEC.md.

Engine constraints:
- Every tunable number lives in `scripts/sim/SimConfig.gd` and only there. Never type a gameplay number in Sim.gd or elsewhere — move it to SimConfig.
- All randomness goes through `GameState.rng`. Never `RandomNumberGenerator.new()` or global `randf()`/`randi()` in sim code (UI-only juice like confetti may use globals).
- Mission logic hangs ONLY off the five Sim events: `day_ended`, `inventory_purchased`, `ravi_hired`, `shop_expanded`, `month_ended`. `Sim.changed` is HUD-refresh only and must never drive missions.
- No game-over, ever. Broke = the lender path (a harder path, never death or reset).
- `GameState.gd` holds data only; `Sim.gd` never reads missions; `MissionManager.gd` never does business math. `run_day()` finishes ALL state mutation before emitting any signal.
- Autoload order in project.godot: GameState, Events, Sim, Missions, SaveManager.

Scope:
- No new gameplay systems beyond BIZTOWN_BUILD_SPEC.md. Multi-product, multi-business, ranks, multiplayer, achievements, tutorials, difficulty modes = Chapter 2+, forbidden now.
- UI stays functional: no art assets, sound, or polish passes. Android-first: touch-compatible, portrait 720x1280.
- Android export (APK, export preset) is gated behind human approval — do not add it unprompted.

Process:
- Gameplay design uncertainty → write the question and options to HUMAN_DECISIONS.md and stop with HUMAN APPROVAL REQUIRED. Never guess on design.
- Never claim a test passed without real command output. Cloud sessions have no Godot binary; Vikash runs the test scenes on his Android device (ANDROID_TESTING.md) and reports back screenshots.
- Report completed work to `.agent_reports/claude_latest.md` (use /stage-report).
