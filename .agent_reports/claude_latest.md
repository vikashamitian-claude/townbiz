# Claude Code Report — Multi-business vision: stabilization + Phase 1-2 foundation

Date: 2026-07-04

- STAGE: Response to the long-term vision directive (walkable 3D multi-business
  world). Phases 1-2 of the requested priority order executed this session;
  Phase 3 partially done; Phase 4 (this report) below.
- STATUS: PASS WITH MINOR FIXES — real bug found and fixed during
  stabilization re-verification; new architecture foundation built and
  statically verified; on-device confirmation still pending (unchanged since
  session start — nothing has executed anywhere yet).

## What was implemented

### Phase 1 — Stabilization re-verification (static, no Godot available)

Re-checked, by reading the actual code rather than assuming prior fixes held:
- `project.godot` autoload order (`GameState, Events, Sim, Missions,
  SaveManager`) and main scene (`Town3D.tscn`) — correct.
- `MissionManager.gd` still connects only to the five explicit Sim events,
  never generic `Sim.changed` — confirmed, no regression.
- The `flow_button` permanent-freeze fix from the prior PR#4 review round —
  confirmed still intact after all subsequent edits.
- `GameState.to_dict()`/`from_dict()` field parity — every key written is
  read back (checked programmatically), including all fields added this
  session.
- `scenes/Town3D.tscn` — minimal, correctly references
  `scripts/world3d/Town3D.gd` (everything else built in code, matching the
  established pattern).

Also ran one more `/code-review --fix` pass (4 of 8 finder angles; stopped
there as a judgment call once the customer-variety diff had real findings in
hand and this session's priority shifted to the bigger vision request) against
the not-yet-merged customer-variety diff (PR #5) before you could even test
it. Found and fixed:
1. **Real bug**: `regulars_prev` (backing the regulars-trend diary line) was
   only reset on New Game, never synced when continuing a save — continuing
   an established game would falsely announce "your first regular customer."
   Fixed in both `Game.gd` and `Town3D.gd`.
2. Simplified away an `is_repeat` flag that was smuggled through the
   *persisted* credit-request dict purely for UI text, when both UI scripts
   already have direct access to `GameState.customer_relationships` and can
   compute it directly.
3. Simplified away an unused `refused` counter — only `paid`/`defaulted`
   ever fed the reliability nudge, and a refusal isn't actually a signal
   about *that customer's* trustworthiness.
4. Reviewed and knowingly left alone: the credit-history feature necessarily
   reorders the RNG draw sequence in `maybe_roll_credit_request()` (must
   know the name before looking up its history) — no test or invariant
   depends on draw-order stability across code versions.

### Phase 2 — Lightweight BusinessType architecture

- **`scripts/business/BusinessType.gd`** — a `Resource` holding pure
  identity + Chapter-1-scale starting-condition data (id, display name,
  product name, shop sign text, tagline, starting cash/inventory/cost/price
  range, customer name pool). Built via explicit property assignment, not a
  12-argument constructor (`gdlint` correctly flagged that as error-prone;
  fixed before committing).
- **`scripts/business/BusinessRegistry.gd`** — static lookup (same
  no-autoload pattern as the existing `GrayboxKit.gd`), two entries:
  - `soap_shop` — mirrors current `SimConfig.gd` values exactly. This is
    the real, only-playable business today.
  - `construction_materials` — a **non-playable placeholder** (distinct
    minimal numbers, no missions, no economy tuning, no world scene) proving
    the data shape generalizes to a different kind of business, exactly as
    the instruction allowed ("a second placeholder... minimal data only").
- **`GameState.active_business_id`** — new field, persisted in
  `to_dict()`/`from_dict()` (parity re-verified), always reset to
  `soap_shop` today (no player-facing business-select flow exists yet, so
  there's nothing else it could meaningfully be).
- **Deliberately NOT done**: generalizing `SimConfig.gd`'s tuned
  demand-curve/capacity/event formulas to be per-business-type. That's real
  Chapter-2 engineering, and touching it now would risk the carefully-tuned
  Chapter 1 economy for a business type that isn't playable yet — exactly
  the "complex system before the current loop is stable" the instruction
  said not to do.

### Phase 3 — Partial (business identity visible in-world)

`Town3D.gd`'s shop sign, the manage-panel counter title, and the
expanded-shop sign now read from `BusinessRegistry.get_active()` instead of
three separate hardcoded `"SOAP SHOP"`/`"SOAP SHOP II"` strings (which,
notably, weren't even using the pre-existing-but-unused
`SimConfig.PRODUCT_NAME` constant before this). A new-game diary now opens
with the active business's tagline. **Zero behavior change** for the current
game (the soap-shop strings are byte-identical) — this is a real, working
proof that swapping `GameState.active_business_id` would visibly change the
game's presented identity, without touching any economic formula.

Not built this round: a business-select screen, additional NPC roles beyond
what already exists (Ravi, the lender, named credit customers), and mission
text reflecting a chosen path — these need an actual second *playable*
business behind them to be meaningful, not just a placeholder data entry.

## A factual correction I made rather than silently complying with

The instruction assumed "Current MVP can remain focused on construction
material retail." That's not what's built — the entire existing game (every
mission, the shop sign, `BIZTOWN_BUILD_SPEC.md`, every prior
`HUMAN_DECISIONS.md` entry) is a **soap shop**. I flagged this directly
rather than silently reskinning a tested, narratively-coherent game, and
kept Soap Shop as the default/active business — using Construction
Materials as the second *placeholder* instead, which the instruction's own
wording explicitly permitted as an alternative.

## What was tested

Nothing was executed — this cloud sandbox still has no Godot binary and no
network path to fetch one (confirmed repeatedly this session; not
re-litigated further). What "tested" means here:
- `gdformat --check` across all 16 `.gd` files (14 pre-existing + 2 new)
  before and after every change — same "would reformat" (style-only) file
  count throughout, confirming zero new parse errors introduced.
- `gdlint` caught one real code-smell in my own new code (the 12-arg
  constructor) before commit — fixed immediately.
- `GameState.to_dict()`/`from_dict()` field parity checked programmatically
  (a small script diffing the two functions' keys), not just by eye.
- Every fix traced by hand against the specific `tests/TestRunner.gd`
  assertions it could plausibly affect.

## What failed or could not be tested

Everything that requires actually running the engine: whether the game
boots, whether the 3D scene renders without error, whether the business
sign text actually displays correctly at runtime, whether the regulars-sync
fix behaves as reasoned. This is the same gap that has existed since the
start of this session, not something new to this round.

## Known risks

- `Town3D.gd` is now clearly over `gdlint`'s 1000-line default guideline
  (not re-measured exactly this round, but it was already there before these
  changes and grew slightly more). Not addressed — further extraction risk
  outweighs the benefit without Godot to verify a bigger refactor.
- The business-identity wiring only reads `BusinessRegistry.get_active()`
  at `_build_world()`/panel-build time (i.e., once, at scene `_ready()`).
  If a save could ever set a *different* `active_business_id` than the
  default (it can't yet — no UI sets it to anything else), the shop sign
  built before `SaveManager.load_game()` runs during "Continue" would be
  stale. Not fixed, because it's not reachable today; flagged so it isn't
  forgotten when a business-select screen becomes real.
- Balance sweep still hasn't been re-run against the customer-variety
  event-weight changes from the prior round (`local_holiday`/`wedding_season`
  added 12 to `EVENT_WEIGHTS`'s total) — same open item as before, unrelated
  to this round's work but still outstanding.

## Exact next recommended step

Unchanged from every prior report this session, and now more urgent given
how much has accumulated: **run `tests/TestRunner.tscn` on-device, once.**
Every fix and every new line of code this session has been reasoned from
static analysis and hand-traced test logic — genuinely careful, but a
five-minute phone test would convert all of it from "should work" to
"confirmed working," or point at exactly what doesn't.
