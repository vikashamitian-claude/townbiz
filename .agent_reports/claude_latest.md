# Claude Code Report — /code-review high-effort pass on the core sim engine

Date: 2026-07-04

- STAGE: post-3D-1 — full 8-angle code review (--fix) against the core engine
  (`scripts/sim/`, `scripts/events/`, `scripts/mission/`, `scripts/save/`)
- STATUS: PASS WITH MINOR FIXES — 6 real bugs fixed (one is a confirmed
  violation of the project's own signal-ordering hard rule), 3 lower-priority
  findings knowingly deferred with reasons. On-device confirmation still
  pending — nothing has executed the engine yet, anywhere.

## Why this pass

The previous review targeted the new 3D UI. The core engine (`Sim.gd`,
`EventEngine.gd`, `MissionManager.gd`, `SaveManager.gd`) came from the
original code drop and had only ever had a manual read-through during Stage 1
integration — never a rigorous adversarial review. Given the last pass found
a severe bug in the UI, it seemed likely the engine deserved the same
treatment. One of 8 finder-agent angles (cross-file tracer) failed mid-run on
a session-limit error; the other 7 (line-by-line, invariant audit, reuse,
simplification, efficiency, altitude, conventions) completed and were
verified directly against the code (reading the exact lines, tracing the
existing `tests/TestRunner.gd` suites against each proposed fix by hand,
since Godot itself still isn't available to actually run them).

## Fixed (6)

1. **Signal-ordering rule violation** — `Sim.run_day()`'s own comment says
   "all mutation completes before any event is emitted (§2.3)," but
   `Events.offer_lender()` (which mutates `lender_offer_pending` and fires
   its own signal) ran *after* `month_ended.emit()` had already fired. A
   `month_ended` listener reading that flag synchronously would see it
   stale. Fixed by reordering within the same `is_month_end` block.
2. **Credit repaid one day late, every time** — `due_day` is stamped using
   the *post-increment* day at grant time, but `_process_credit_dues()` runs
   *before* that call's day increment, so the comparison was off by one.
   Every credit resolved a day after what the UI's "repaying in N days" text
   promised. Traced the fix against `tests/TestRunner.gd`'s `_test_credit`
   by hand (due_day=3, 4 `run_day()` calls) — the existing assertion still
   passes, resolution now just happens one call earlier (on time).
3. **Event effects stacked instead of refreshing** — re-rolling
   `supplier_hike`/`supplier_deal`/`competitor_discount` while a prior
   instance was still active appended a second entry to
   `GameState.active_effects`, doubling `cost_delta`/`demand_mult` in
   `get_active_cost_delta()`/`get_active_demand_mult()` instead of resetting
   the effect's duration. Fixed by removing any existing same-id entry
   before appending — the credit-request path already had an equivalent
   guard; this event class didn't.
4. **A second bulk offer silently destroyed the first** — `pending_bulk_offer`
   was overwritten unconditionally with no guard, unlike the credit-request
   path which explicitly checks `is_empty()` first. Added the same guard.
5. **Reloading a finished-Chapter-1 save never showed the completion
   screen** — `MissionManager.from_dict()`'s guard only covered
   `current_index < missions.size()`; loading a save from after the chapter
   was already done fell through and emitted nothing at all. Now emits
   `chapter_completed` in that case. (Caveat: Town3D's ephemeral reflection
   stats — total revenue, Ravi-hire day, price-change count — aren't part of
   the persisted save format, so they'll show as zero/default if reached
   this way; this is a pre-existing, narrower gap that reaching the screen
   at all now makes newly visible, not a regression.)
6. **`SaveManager.load_game()` didn't re-telegraph a pending event** the
   player may not have seen this session (e.g. they quit right after it
   fired) — added a re-telegraph call. The event still applied on schedule
   either way; this only concerned whether the warning was shown.

Also added a defensive `push_warning` default arm to `EventEngine.apply_pending()`'s
match — a telegraphed event with no matching case there previously applied
as a silent no-op. This doesn't fix a live bug (all 6 current event types are
handled) but narrows a real design gap the altitude angle flagged: event
identity is a bare string duplicated independently across
`SimConfig.EVENT_WEIGHTS`, `_make_event()`, and `apply_pending()` with no
shared registry, so a future addition or typo in any one of them would
otherwise degrade silently.

## Knowingly skipped (2, both are economy/balance questions, not bugs)

- **`REP_MAX_DAILY_DROP` only caps the demand-loss reputation penalty** —
  bulk-commitment failures (uncapped, -3 each) and a lender month-end
  rollover (uncapped, -10) can stack well past what the constant's name
  implies on a single bad day. This is a real design tension, but fixing it
  means changing how reputation deltas accumulate across a day — an economy
  change, which `AGENTS.md` explicitly gates behind human approval. Flagging
  for a design decision rather than changing behavior unasked.
- **`GameState.credit_ledger` never prunes resolved entries** (unlike
  `bulk_commitments`, which does) — real unbounded growth over a very long
  save, but low severity in practice given a realistic Chapter 1 playthrough
  length (tens of entries at most), and pruning would break
  `tests/TestRunner.gd`'s `_test_credit`, which explicitly reads
  `credit_ledger[0]` *after* it resolves. Not worth the test-contract risk
  for a non-urgent perf concern.

## Verification method

Same as the previous pass: no Godot binary available in this sandbox.
`gdformat --check` across every `.gd` file in `scripts/`+`tests/` before and
after all edits shows the same 12/14 "would reformat" (style-only) count
throughout — confirms no fix introduced a parse error. Each fix was also
traced by hand against the specific `tests/TestRunner.gd` assertions it could
plausibly affect (credit timing, mission save/load) to catch a fix that
"looks right" but would silently break the one real (if unexecuted) test
suite this project has.

**Still not verified by execution.** Every fix here is reasoned from reading
the code and tracing test logic by hand — genuinely careful, but not the
same as watching it run. The phone playtest remains the only thing that can
actually confirm this.

## OPEN QUESTIONS

The two skipped findings above are economy/balance judgment calls, not
implementation questions — surfaced for Vikash's awareness, not blocking.
