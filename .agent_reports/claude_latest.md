# Claude Code Report — "Living Business" content expansion (customer variety)

Date: 2026-07-04

- STAGE: post-review content pass — more day-event variety, recurring customer
  memory, and felt regulars feedback (Vikash's explicit request, scoped via
  AskUserQuestion to "smarter/varied customer behavior" — not real ML)
- STATUS: PASS WITH MINOR FIXES — new content wired end-to-end and statically
  verified; on-device confirmation still pending (nothing has executed yet,
  same as every prior stage this session)

## What was asked and why this shape

Vikash asked whether ML could give an "automatic customer experience."
Clarified via two rounds of AskUserQuestion: he wants richer/more varied
customer behavior, not literal machine learning (Godot has no practical
on-device ML runtime for mobile, and the existing noise/archetype system
already achieves "feels alive" without it — see BIZTOWN_BUILD_SPEC.md). He
picked all three concrete options offered:

1. More day events
2. Customers who feel like recurring people (credit history/memory)
3. Demand/regulars feedback surfaced as felt diary patterns, not just numbers

## What was built

### 1. Two new day events (`SimConfig.gd`, `EventEngine.gd`)
- `local_holiday` — one-day demand ×0.65 (shutters half-down), same mechanism
  as `festival_rush`/`heavy_rain`.
- `wedding_season` — 2-day demand ×1.35, same mechanism as
  `supplier_hike`/`supplier_deal`/`competitor_discount`.
Both reuse existing effect machinery exactly — no new mechanic, no Sim.gd
changes needed for these two. Added at weight 6 each to `EVENT_WEIGHTS`.

**Balance note:** adding two new weighted events (total weight 100→112)
proportionally lowers every other event's frequency, including `none`
(55/100→55/112, ~49%). This is an inherent, expected consequence of "add
more variety," not a hidden tuning change — but it does mean
`tests/BalanceSweep.gd`'s targets (~70% survive Month-End without the lender,
expansion affordable day 40-55) should be re-checked once it can actually run,
since the event mix shifted.

### 2. Recurring customer memory (`GameState.gd`, `EventEngine.gd`, `Sim.gd`)
- New `GameState.customer_relationships: Dictionary` (name → `{paid,
  defaulted, refused}` counts), persisted in `to_dict()`/`from_dict()`.
- New `GameState.record_customer_outcome(name, outcome)` — thin bookkeeping,
  same shape as the existing `add_trait()` helper.
- `EventEngine.maybe_roll_credit_request()` now nudges a freshly-rolled
  reliability value by that customer's history (`CREDIT_HISTORY_PAID_BONUS`
  = +0.05/past payment, `CREDIT_HISTORY_DEFAULT_PENALTY` = -0.12/past
  default — both new `SimConfig` constants), clamped to a wider
  `CREDIT_RELIABILITY_HARD_MIN/MAX` range (0.05-0.99) than the fresh-roll
  range (0.6-0.95) — deliberately wider, so a serial defaulter can actually
  read as untrustworthy instead of snapping back to the same band. The
  request dict now also carries `is_repeat: bool` for the UI.
- `Sim.gd`'s `grant_credit()`/`refuse_credit()`/`_process_credit_dues()` now
  call `record_customer_outcome()` on refuse/paid/defaulted.
- Both `Game.gd` and `Town3D.gd`'s credit modal text now reads differently
  for a repeat vs. new name ("X is back, wanting..." vs. "A new face, X,
  wants...").

### 3. Regulars trend surfaced as diary/log lines (`Game.gd`, `Town3D.gd`)
New `_note_regulars_trend()` in both UIs (mirrored, since `Game.gd` is the
2D fallback and `Town3D.gd` is the active 3D build): logs "your first regular
customer" on the first one, "N regulars now count on your shop" on every
+5 milestone, and "a regular gave up waiting today" on any drop. Pure
presentation — reads `result.regulars` from the existing `Sim.run_day()`
result dict, no engine changes.

## Architecture notes (kept inside existing boundaries)

- All new tunables live in `SimConfig.gd` only.
- Reputation/cash/regular-count mutation still happens exclusively in
  `Sim.gd`; `EventEngine.gd` only supplies data (the reliability roll,
  `is_repeat` flag) — it doesn't mutate reputation or cash itself.
- `GameState.record_customer_outcome()` is bookkeeping only (same shape as
  the pre-existing `add_trait()`), not decision logic.
- Verified by hand against `tests/TestRunner.gd`'s `_test_credit()`: it
  constructs `pending_credit_request` directly (bypassing
  `maybe_roll_credit_request()`), so the new history-nudge path isn't
  exercised by that test and doesn't change its assertions; `grant_credit()`/
  `refuse_credit()` gained a new side effect (recording history) that no
  existing assertion checks, so nothing breaks.

## FILES CHANGED

`scripts/sim/SimConfig.gd`, `scripts/sim/GameState.gd`, `scripts/sim/Sim.gd`,
`scripts/events/EventEngine.gd`, `scripts/Game.gd`, `scripts/world3d/Town3D.gd`

## Verification method

Same as every stage this session: no Godot binary available. `gdformat
--check` across every `.gd` file shows the same 12/14 "would reformat"
(style-only) count as before these changes — confirms no new parse error.
`gdlint` flags are the expected consequences of adding real content
(`_make_event`'s return-statement count went up; `Town3D.gd` is back over
1000 lines) — not addressed further this round to avoid speculative
extraction on top of an already-large diff; noted rather than hidden.

**Still not verified by execution.** This is genuinely new gameplay content on
top of everything else this session — the on-device test run matters more
than ever now. Recommend, in order: run `tests/TestRunner.tscn` first (still
its first-ever execution), then play through at least one credit cycle twice
(grant it, let it resolve, then get offered credit by the *same* name again)
to feel whether the repeat-customer nudge reads as intended.

## OPEN QUESTIONS

None blocking — the balance-sweep re-check noted above is a "do when you can
run it" item, not a decision needed now.
