# BizTown Code Drop — Integration Guide & Claude Code Kickoff

## What's in this package

Complete, ready-to-integrate engine code for the "Living Business" build
(per BIZTOWN_BUILD_SPEC.md). Written by Claude.ai as product architect;
Claude Code integrates, wires the UI, runs tests, and fixes.

```
scripts/sim/SimConfig.gd        # ALL tunables (replaces existing)
scripts/sim/GameState.gd        # data + RNG + ledger/effects (replaces existing)
scripts/sim/Sim.gd              # full sim core rewrite (replaces existing)
scripts/events/EventEngine.gd   # NEW — autoload "Events"
scripts/save/SaveManager.gd     # NEW — autoload "SaveManager"
scripts/mission/MissionData.gd  # updated Chapter 1 (replaces existing)
scripts/mission/MissionManager.gd  # event-driven (replaces existing)
tests/TestRunner.gd             # all 6 suites from spec §8
tests/TestRunner.tscn           # run as a SCENE so autoloads initialize
```

## Autoload registration (project.godot → [autoload])

Order matters — dependencies first:

1. `GameState`  → res://scripts/sim/GameState.gd
2. `Events`     → res://scripts/events/EventEngine.gd
3. `Sim`        → res://scripts/sim/Sim.gd
4. `Missions`   → res://scripts/mission/MissionManager.gd
5. `SaveManager`→ res://scripts/save/SaveManager.gd

## Test command (document in README)

```
godot --headless --path . res://tests/TestRunner.tscn
```

Exit code 0 = all pass. Do NOT use `-s script` mode — autoloads won't load.

---

# KICKOFF PROMPT — paste below into Claude Code in the townbiz repo root

You are the lead developer and tester for BizTown. A complete engine code drop
has been placed in this repo (see the file list in INTEGRATION.md) alongside
BIZTOWN_BUILD_SPEC.md. The gameplay design is HUMAN-APPROVED by Vikash; this
clears the Sprint 1 Task 3/4/6 approval gates. Android export stays gated.

Read in order: FOUNDATION.md, BIZTOWN_BUILD_SPEC.md, INTEGRATION.md, then every
file in the code drop, then the existing Game.gd/Game.tscn.

Your job, in this order — STOP for my "continue" after each numbered stage:

**Stage 1 — Integrate & compile.**
Replace the old sim/mission scripts with the drop, add the two new autoloads in
the order specified, and get the project parsing clean in Godot 4.x headless.
Fix any API mismatches between the drop and the installed Godot version
(signal bind arities, typed arrays, etc.) — behavior changes require my approval,
syntax fixes don't. Report every change you make to the dropped code.

**Stage 2 — Tests green.**
Run `godot --headless --path . res://tests/TestRunner.tscn`. Debug until all
6 suites pass with exit code 0. If a test reveals a genuine DESIGN flaw (not a
bug), write it to HUMAN_DECISIONS.md and stop with HUMAN APPROVAL REQUIRED.

**Stage 3 — Wire the UI (Game.gd).**
Functional, not pretty. Required hooks:
- Demand hint shows the RANGE from Sim.calculate_demand_range() — never one number
- Buy screen shows today's unit cost (Sim.get_current_unit_cost()) AND yesterday's
- Telegraph banner on Events.event_telegraphed (evening news style)
- Modal choice on Events.credit_requested → Sim.grant_credit()/refuse_credit()
- Modal choice on Events.bulk_offered → Sim.accept_bulk_offer()/decline_bulk_offer()
- Modal choice on Events.lender_offered → Sim.accept_lender()/decline_lender()
- Month-end summary on Sim.month_ended (rent line, lender debt line if any)
- Regulars count visible on HUD ("14 regulars")
- Boot: SaveManager.has_save() → Continue / New Game choice

**Stage 4 — Balance sweep.**
Write tests/BalanceSweep.gd (+ .tscn): 100 seeds × 60 days with a naive default-
price auto-player. Verify spec §9's success test: ~70% survive Month-End without
the lender; expansion affordable day 40–55 for a competent scripted player. Tune
SimConfig values ONLY. Report the numbers before and after tuning.

**Stage 5 — Docs & handover.**
Update TASKS.md, README (test command), .agent_reports/SPRINT_STATUS.md and
claude_latest.md. Output "READY FOR HUMAN PLAYTEST" and stop.

Hard rules: no game-over ever; no magic numbers outside SimConfig; all randomness
through GameState.rng; no new gameplay systems beyond the spec; UI polish is
explicitly out of scope. When in doubt on gameplay design — stop and ask, never guess.

Begin Stage 1 now.
