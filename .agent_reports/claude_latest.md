# Claude Code Report — /code-review high-effort pass on the 3D town (post-merge)

Date: 2026-07-03

- STAGE: 3D-1 follow-up — full 8-angle code review (--fix) against `git diff 00617f1...HEAD`
- STATUS: PASS WITH MINOR FIXES — 10 real findings fixed (one severe game-freeze bug); several lower-priority findings knowingly skipped (see below); on-device confirmation still pending.

## What this was

Ran the bundled `/code-review --fix high` skill against the full Sprint 3D diff
(before-3D-work base `00617f1` to current `HEAD`): 8 parallel finder angles
(line-by-line scan, removed-behavior audit, cross-file trace against the sim
autoloads, reuse, simplification, efficiency, altitude, CLAUDE.md conventions),
then verified and fixed the survivors directly in the working tree. Full
findings recorded via the `ReportFindings` tool.

## Fixed (10, most severe first)

1. **Game-breaking**: `_show_next_decision()`'s empty-queue branch never called
   `_refresh_all()`, so `flow_button.disabled` (set true while a decision was
   showing) never reset to false — the day-advance loop froze permanently
   after the very first credit/bulk/lender decision resolved with nothing
   queued behind it. This would have hit almost every playthrough.
2. Customer-spawn tween was bound to `Town3D` (`self`), not the spawned NPC —
   pressing Reset mid-animation left tweens running against freed instances.
   Fixed by binding via `npc.create_tween()` instead.
3. The Manage-shop panel didn't pause `running`/`day_timer` or block
   background touch input, unlike every other modal in the file — days could
   advance and Hire/Expand could fire underneath it while open.
4. Boot "Continue" ignored `SaveManager.load_game()`'s failure return —
   a corrupt/incompatible save left default state with no mission ever shown.
5. Continue-from-save never restored the neighbor shop's expanded visual
   even when `GameState.has_expanded_shop` was true.
6. The entire end-of-chapter feedback form (3 questions + submit-to-file),
   present in the 2D fallback UI, was missing from the 3D build entirely.
7. The completion screen's "final price / price changes / reputation" stats
   were dropped, and price changes were never tracked in the first place
   (`price_slider.drag_ended` wasn't connected).
8. `BUY_QUANTITY`/`LOW_STOCK` were hardcoded in the view layer, violating the
   project's literal rule that every tunable lives only in `SimConfig.gd` —
   moved there, both `Game.gd` and `Town3D.gd` now reference `SimConfig.*`.
9. The "drag to walk" hint tween never replayed after Reset/Play Again.
10. Three modal-overlay builders (decision/boot/complete) duplicated the same
    dim+panel scaffold, and the neighbor-shop repaint logic was duplicated
    with fragile `get_child(1)` indexing in two places — both extracted into
    shared helpers (`_build_modal_shell`, `_paint_neighbor`).

## Knowingly skipped (with reasons)

- **Cross-file duplication vs `scripts/Game.gd`** (story text, stylebox/button
  helpers, palette constants, float-feedback tween): `Game.gd` is documented
  as a legacy fallback slated for retirement once the 3D build reaches parity
  — building a shared UI-kit module now duplicates effort against code that's
  leaving, and touching Game.gd's still-shipping fallback blind (no Godot to
  test) adds risk for a transitional file.
- **Efficiency items** (per-frame `Label3D` text rewrite even when unchanged,
  fresh mesh/material allocated per spawned customer instead of shared,
  per-frame `Missions.get_current_mission()` poll): real but perf-only, and
  the graybox meshes/materials are explicitly temporary (Phase 3D-2 swaps
  them for real assets) — would likely be thrown away; deferred until
  on-device profiling shows an actual problem.
- **Hardcoded mission-id string branching** (`"long_queue"`, `"shop_next_door"`)
  driving Ravi/expand availability: a real architectural point (a generic
  "interactable" concept would be more robust) but Chapter 1's mission set is
  fixed at 5 beats and isn't expected to be renamed — a bigger redesign than
  is safe to do blind right now; worth revisiting in Phase 3D-3.
- **`decision_active` redundant with `decision_overlay.visible`**, and the
  **three-way decision-kind match statements** (per-kind data table would
  consolidate them): both true but low-value/higher-risk simplifications
  given no Godot to confirm no edge case was missed; deferred (YAGNI until a
  4th decision kind is actually added).

## Verification method (still no Godot binary available)

`gdformat --check` on every touched file parses clean before and after every
edit (12/14 files "would reformat" = style only, same count throughout —
confirms no new parse errors introduced by any fix). `gdlint` confirms the
file-length flag on `Town3D.gd` (1044 lines) persists after the dedup — the
feature-parity additions (feedback form, decision stats) outweighed the
dedup savings; accepted as reasonable for a single-scene script with clear
section banners rather than risking a bigger, unverifiable split.

**Still not verified by execution.** This narrows the risk window
considerably (a real freeze-the-game bug is now fixed before it ever reached
a player) but the phone playtest is still the only thing that can confirm
the game actually runs.

## OPEN QUESTIONS

none — next real signal is Vikash re-testing on-device.
