# Claude Code Report — Sprint 3D, Phase 3D-1 follow-up (self-review pass)

Date: 2026-07-03

- STAGE: 3D-1 — self-directed develop/review/fix pass on the walkable town (PR #3)
- STATUS: PASS WITH MINOR FIXES — real bug found and fixed; static verification
  tooling upgraded; full on-device confirmation still pending (see below)

## What changed and why

Asked to develop, test, review, and fix autonomously. Godot itself remains
unavailable in this cloud sandbox (no binary, no network path to fetch one —
confirmed again this session), but two things are newly available and used:

1. **`gdtoolkit` (pip-installable, PyPI is reachable)** — `gdlint`/`gdformat`
   run a real independent GDScript grammar parser. Not a Godot API checker
   (doesn't know Node3D/Camera3D/etc. exist), but it DOES catch real syntax
   errors, and running it project-wide gives a genuine (not fabricated)
   verification signal: **`gdformat --check` parses all 14 `.gd` files in
   `scripts/` and `tests/` with zero parse failures.** Documented for future
   sessions in `CLAUDE.md`.
2. `godot3` is `apt`-installable but is Godot 3.x — a different, incompatible
   GDScript dialect from this Godot-4.x project. Confirmed unusable for
   testing this codebase; noted so no future session wastes time on it.

## Bug found and fixed (via gdlint review, not on-device report)

**`scripts/world3d/Town3D.gd`** — the "Ravi" 3D label was built by a helper
that unconditionally parented it to the town root, then the call site tried
to re-parent it under `ravi_npc`. Godot does not allow adding a node that
already has a parent, so the label never actually followed Ravi around —
it likely explains the "Ravi" text you saw floating away from his character
in the last screenshot. Fixed by making the label builder take an explicit
parent and passing `ravi_npc` directly (no reparenting needed).

## Refactor (triggered by a real lint flag, not cosmetic)

`gdlint` flagged `Town3D.gd` at 1070 lines (over its 1000-line guideline).
Extracted the six stateless graybox mesh-builder functions (`_static_box`,
`_visual_box`, `_label3d`, `_tree`, `_person`, `_tint_person`) into a new
**`scripts/world3d/GrayboxKit.gd`** (`class_name GrayboxKit`, static
functions, no game state/autoload references). This is also exactly the
swap point Phase 3D-2 needs when replacing boxes with real low-poly assets
(see `HUMAN_DECISIONS.md`) — one file to change, not scattered call sites.
Town3D.gd is now 976 lines. All call sites updated; every one traced by
hand against the extracted signatures (parent param added where the
original called `add_child` on `self`).

Also fixed two `gdlint` "declaration order" flags (cosmetic, zero behavior
change): `SaveManager.gd` (signals before the const), `Player3D.gd` (public
var before private `_`-prefixed vars).

## Also fixed (from the prior on-device screenshot report)

Already pushed in the prior commit on this PR: the flat-color seam where the
old 44x44 ground plane ended (enlarged to 200x200 + blended sky ground
colors), and pulled the follow camera back for a wider establishing view.

## FILES CHANGED

- `scripts/world3d/GrayboxKit.gd` — NEW
- `scripts/world3d/Town3D.gd` — extraction, bug fix, ordering fix, line-wrap cleanup
- `scripts/world3d/Player3D.gd` — ordering fix only
- `scripts/save/SaveManager.gd` — ordering fix only
- `CLAUDE.md` — documents the gdtoolkit verification capability for future sessions

## TEST OUTPUT

```
$ gdformat --check $(find scripts tests -name "*.gd")
would reformat scripts/sim/Sim.gd
would reformat scripts/sim/SimConfig.gd
would reformat scripts/sim/GameState.gd
would reformat scripts/mission/MissionData.gd
would reformat scripts/mission/MissionManager.gd
would reformat scripts/events/EventEngine.gd
would reformat scripts/Game.gd
would reformat scripts/world3d/Town3D.gd
would reformat scripts/world3d/Player3D.gd
would reformat scripts/Main.gd
would reformat tests/BalanceSweep.gd
would reformat tests/TestRunner.gd
12 files would be reformatted, 2 files would be left unchanged.
EXIT: 1
```
Exit 1 here means "some files aren't gdformat-styled" (cosmetic), NOT a parse
failure — no file threw a parse error. That's the real signal: all 14 `.gd`
files are syntactically valid GDScript. Remaining `gdlint` output is only
line-length style warnings on lines I didn't touch (pre-existing in the
original code drop) — not pursued, to avoid unrelated churn on approved-spec
files.

**Still not verified by execution:** whether the game actually runs/looks
right on-device. This static pass narrows the risk window; it is not a
substitute for the phone playtest.

## OPEN QUESTIONS

none — next real signal is Vikash re-testing PR #3 on-device.
