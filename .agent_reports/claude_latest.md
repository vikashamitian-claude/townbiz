# Claude Code Report — Sprint 3D, Phase 3D-1 (walkable town graybox)

Date: 2026-07-03

- STAGE: 3D-1 — graybox walkable 3D town presentation
- STATUS: PASS WITH MINOR FIXES pending on-device verification (no Godot in the
  cloud session — Vikash verifies on his Android device per ANDROID_TESTING.md)

## Why this exists

First on-device playtest: the Living Business engine worked (verified by
Vikash's screenshots — regulars, cost drift, bulk offers, range hints all
live), but the owner rejected the flat 2D presentation and asked for a 3D
world. Clarified via choice prompt: he wants a walkable 3D town in Godot, NOT
combat, NOT an engine switch. Decision recorded in HUMAN_DECISIONS.md. The
sim engine is untouched — this is a new view layer on the same autoloads.

## FILES CHANGED

- `HUMAN_DECISIONS.md` — NEW: decision record for the presentation pivot
- `scripts/world3d/Player3D.gd` — NEW: CharacterBody3D founder; floating touch
  joystick (left 60% of screen), mouse fallback, graybox capsule visual
- `scripts/world3d/Town3D.gd` — NEW: the town scene — sky/sun/follow-camera,
  graybox street (shop, FOR-RENT neighbor, houses, trees, road), customers as
  3D figures walking to the door (red = turned away), contextual interactions
  (Manage shop at counter / Hire Ravi in person / Expand next door in person),
  HUD chips + mission line + telegraph banner + mini diary + decision modals +
  boot Continue/New Game + chapter-complete mirror — all identical sim
  contracts as Game.gd (same signals, same Sim calls, no business logic)
- `scenes/Town3D.tscn` — NEW: root scene (everything built in code)
- `project.godot` — main scene → Town3D.tscn
- `scenes/Game.tscn` / `scripts/Game.gd` — UNCHANGED, kept as 2D fallback
- `CODING_RULES.md` — stack line 2D→3D per owner decision
- `CLAUDE.md`, `.claude/skills/biztown-rules/SKILL.md`, `TASKS.md`,
  `ANDROID_TESTING.md` — updated to reflect the pivot

## EDITS TO SIM/ENGINE CODE

None. `scripts/sim/`, `scripts/events/`, `scripts/mission/`, `scripts/save/`,
`tests/` untouched. TestRunner/BalanceSweep still valid and still pending
their first on-device run.

## TEST OUTPUT

None — no Godot binary in this session (known env limitation). On-device
checklist for Vikash: import fresh main, Play → walk with left-drag, manage
at counter, run days, watch customers, hire Ravi during Long Queue by walking
to him, expand next door, and ALSO still run tests/TestRunner.tscn (engine
suites — never yet executed anywhere).

## OPEN QUESTIONS

none — Phase 3D-2 (real low-poly assets) starts after 3D-1 verifies on-device.
