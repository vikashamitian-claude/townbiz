---
name: playtest-results
description: Interpret and act on BizTown test or playtest results from Vikash's Android device — TestRunner/BalanceSweep screenshots, FAIL lines, crash or parse errors, or gameplay feedback.
---

# Acting on on-device results

Vikash runs everything in the Godot Android editor (see ANDROID_TESTING.md) and reports via screenshots or typed text. This is the project's only runtime — treat his reports as ground truth.

## TestRunner (tests/TestRunner.tscn) — where each suite's failures point

| Suite | Covers | Failures usually mean fixing |
|---|---|---|
| SIGNALS | five-event mission wiring, no cascades, state-final-on-day_ended | `scripts/mission/MissionManager.gd`, signal/emit order in `Sim.run_day()` |
| ECONOMY 60-DAY | cash band, rent on days 30/60, regulars growth | `Sim.run_day()` steps, economy values in `SimConfig.gd` |
| EVENTS SEED SWEEP | weight frequencies, effect expiry, telegraph exactly 1 day ahead | `scripts/events/EventEngine.gd`, `pending_event` flow in Sim |
| CREDIT | grant/refuse paths, due-day resolution | credit funcs in `Sim.gd`, `maybe_roll_credit_request` |
| SAVE/LOAD | byte-identical round-trip | `GameState.to_dict/from_dict`, `SaveManager.gd` |
| MISSION PLAYTHROUGH | Chapter 1 completes in order; expansion refused when broke | `MissionData.gd` conditions, `MissionManager.gd` |

## BalanceSweep (tests/BalanceSweep.tscn) — targets from BIZTOWN_BUILD_SPEC.md §9

- ~70% of seeds survive Month-End WITHOUT the lender
- Median day expansion becomes affordable: 40–55

Off-target → tune values in `SimConfig.gd` ONLY (never Sim.gd logic). Record before/after numbers in the report.

## Crashes / parse errors on import

Ask for the exact red error text or a screenshot of it. Fix the API/syntax mismatch; never guess silently. Remember the project targets Godot 4.x on Android.

## After acting

If a failure reveals a genuine DESIGN flaw (a spec rule that cannot work as written), do not redesign — write options to HUMAN_DECISIONS.md and stop with HUMAN APPROVAL REQUIRED.

Otherwise: fix, update TASKS.md and `.agent_reports/` (use /stage-report), commit, and push to the working branch so Vikash can re-download and re-test.
