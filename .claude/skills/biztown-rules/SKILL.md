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
- No new gameplay systems beyond BIZTOWN_BUILD_SPEC.md. Multi-product, multi-business gameplay, ranks, multiplayer, achievements, tutorials, difficulty modes = Chapter 2+, forbidden as PLAYABLE features now — Chapter 1 stays one playable business (soap shop). Combat/guns: never (asked and refused, see HUMAN_DECISIONS.md).
- Long-term direction (approved 2026-07-04/05, HUMAN_DECISIONS.md + DESIGN_CONSTRUCTION_ECONOMY.md): a walkable 3D world with a construction-first, player-built economy. The keystone law — "what is built stays" — is backed by `GameState.built_structures` (town as JSON-safe data, seeded from `DefaultTown.gd`, rebuilt via `StructureCatalog.gd`/`Town3D._rebuild_structures()`); never bypass the registry when adding world structures. The contractor loop (build contracts: offer → materials paid upfront → house joins the registry → payout) is owner-approved gameplay ("develop the whole game in the new guideline", 2026-07-05). Still not approved without an explicit ask: material-shop entities, govt/private contract split, township planner, business-select screen, second playable business, multiplayer.
- Presentation = stylized 3D walkable town in Godot (`scripts/world3d/`, approved 2026-07-03 — HUMAN_DECISIONS.md). View code talks to the autoloads only; NO business logic in the view layer. No sound yet. Android-first: touch-compatible, portrait 720x1280.
- Android export (APK, export preset) is gated behind human approval — do not add it unprompted.

Process:
- Gameplay design uncertainty → write the question and options to HUMAN_DECISIONS.md and stop with HUMAN APPROVAL REQUIRED. Never guess on design.
- Never claim a test passed without real command output. Cloud sessions have no Godot binary; Vikash runs the test scenes on his Android device (ANDROID_TESTING.md) and reports back screenshots.
- Report completed work to `.agent_reports/claude_latest.md` (use /stage-report).
