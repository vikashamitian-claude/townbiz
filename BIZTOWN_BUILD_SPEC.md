# BizTown — Chapter 1 "Living Business" Build Spec (v1.0)

> **Status:** APPROVED BY HUMAN (Vikash). This document clears the Sprint 1 Task 3/4
> human gameplay approval gates and defines the full rebuild of Chapter 1 into a
> living, uncertain, realistic business simulation.
>
> **Governed by:** FOUNDATION.md (frozen), PROTOTYPE_SPEC.md, CODING_RULES.md.
> Nothing here violates the 80% Rule, the Design Laws, or the no-game-over rule.
> Where this spec conflicts with older sprint tasks, THIS SPEC WINS.

---

## 0. The Problem This Build Solves

The current sim is deterministic: same demand formula, same customers, same day,
every day. Design Law 7 defines BizTown's core verb as *"allocate scarce resources
under uncertainty"* — and there is currently **zero uncertainty**. This build adds:

1. **Uncertainty** — demand noise, random day events, fluctuating supplier costs
2. **Living customers** — archetypes, regulars, credit requests, bulk orders
3. **Real stakes** — rent actually charged, expansion actually costs money
4. **Event-driven missions** — no more re-checks on every `changed` signal
5. **Save/load** — so a run persists

Multi-product, multi-business, ranks, and multiplayer are explicitly **OUT OF SCOPE**
(Chapter 2+). One soap shop that feels ALIVE is the whole goal.

---

## 1. Architecture Rules (unchanged, restated)

- `SimConfig.gd` — every tunable number lives here and only here
- `GameState.gd` — data only, no logic
- `Sim.gd` — pure `calculate_*` functions + mutating actions; never reads missions
- `MissionManager.gd` — reads GameState, never does business math
- `MissionData.gd` — missions as plain data
- **NEW** `EventEngine.gd` (autoload "Events") — daily event rolls; emits to Sim
- **NEW** `CustomerBook.gd` (autoload "Customers") — regulars & credit ledger data
- **NEW** `SaveManager.gd` (autoload "SaveManager") — save/load to `user://save_v1.json`

All randomness MUST go through one seeded RNG (`GameState.rng: RandomNumberGenerator`)
so headless tests can run with a fixed seed and be deterministic.

---

## 2. Signal Redesign (fixes the re-entrancy bug — Sprint 1 Task 3)

### 2.1 Remove
- `MissionManager` must **stop** connecting to generic `Sim.changed`.
- `Sim.changed` remains ONLY for HUD refresh. It must never drive mission logic.

### 2.2 The five mission-driving events (the only ones)
```gdscript
signal day_ended(result: Dictionary)      # end of a full trading day, state final
signal inventory_purchased(qty: int, unit_cost: float)
signal ravi_hired
signal shop_expanded
signal month_ended(rent_paid: float, cash_after: float)
```

### 2.3 Ordering guarantee inside run_day()
`run_day()` must fully finish ALL state mutation (sales, costs, reputation,
day increment, month-end rent if applicable) BEFORE emitting anything.
Emission order at the end: `month_ended` (if day % MONTH_LENGTH_DAYS == 0),
then `day_ended`, then `changed`. Internal helpers like
`apply_reputation_change()` must gain a `silent: bool = false` parameter;
`run_day()` calls them silently.

### 2.4 Acceptance test
A headless test must prove: starting mission "month_end" and running 30 days
completes missions in order with no same-instant cascade, and `changed` alone
never completes a mission.

---

## 3. Layer 1 — Uncertainty Engine

### 3.1 Demand noise
Every day, actual demand = `calculate_demand(price, reputation) * noise`,
where `noise = rng.randf_range(NOISE_MIN, NOISE_MAX)`.

```gdscript
# SimConfig additions
const NOISE_MIN: float = 0.75
const NOISE_MAX: float = 1.25
```

The pure `calculate_demand()` stays deterministic (used by the pricing-dial hint).
A new `roll_daily_demand(price, reputation)` in Sim applies noise. The HUD hint
should show a RANGE ("18–30 customers likely"), never a single fake-precise number.

### 3.2 Day events
At the start of each `run_day()`, EventEngine rolls **at most one** event
(P(no event) must stay high so events feel special).

| id | weight | effect | telegraph (shown the evening BEFORE, per Fairness law) |
|---|---|---|---|
| none | 55 | — | — |
| festival_rush | 8 | demand ×1.6 today | "Festival tomorrow — the whole town will be out shopping." |
| heavy_rain | 8 | demand ×0.6 today | "Dark clouds gathering. Tomorrow looks wet." |
| supplier_hike | 7 | PRODUCT unit cost +₹4 for next 5 days | "Your supplier warns: soap prices are rising." |
| supplier_deal | 6 | unit cost −₹5 for next 3 days | "A wholesaler is clearing stock cheap this week." |
| competitor_discount | 8 | demand ×0.75 for next 3 days | "The shop across the road put up a SALE board." |
| bulk_order_offer | 8 | see 4.3 | (arrives as a choice, not a telegraph) |

Weights in `SimConfig.EVENT_WEIGHTS: Dictionary`. Multi-day effects tracked in
`GameState.active_effects: Array[Dictionary]` (`{id, days_left, ...}`), ticked
down inside `run_day()`.

**Telegraph rule (Design Law 6):** every non-choice event is announced one day
ahead via `Events.event_telegraphed(event: Dictionary)`; the effect applies the
next day. The player must always get one pricing/stock decision between warning
and impact.

### 3.3 Fluctuating supplier cost
`GameState.current_unit_cost` replaces the constant in `buy_inventory()` default.
It drifts: each day `current_unit_cost += rng.randf_range(-0.5, 0.5)`, clamped
to `[COST_MIN=16, COST_MAX=26]`, plus event modifiers. Restock timing becomes a
real decision. The buy screen shows today's cost and yesterday's, so the player
can FEEL the movement (never a chart).

---

## 4. Layer 2 — Living Customers

### 4.1 Customer mix (replaces the single demand number)
Daily demand is split into archetypes (percentages in SimConfig):

| archetype | share | behavior |
|---|---|---|
| walk_ins | 55% | current demand-curve behavior |
| bargainers | 20% | only buy if price ≤ `BARGAIN_CEILING` (₹32 at rep 50, shifts with reputation like the main curve) |
| regulars | grows 0→25% | buy at any price ≤ PRICE_MAX; count = `GameState.regular_count` |
| bulk/one-timers | event-driven | see 4.3 |

Regulars are the compounding asset: every "clean day" (nobody turned away)
adds +1 regular (cap 40). Every day a regular is turned away (stockout/queue),
lose 2 regulars AND take the reputation hit. This makes stockouts *hurt in the
future*, not just today — the real-life lesson.

### 4.2 Credit requests (the trust mechanic — India-real)
With probability `CREDIT_REQUEST_CHANCE = 0.15` per day, a named customer asks
for goods on credit: `{name, qty (5–15), price_offered (today's price), repay_in_days (5–10), reliability (hidden, 0.6–0.95)}`.
Names from a Barpali-flavored pool: Sharma-ji, Meena didi, Raju bhai, Panda babu,
Gita mausi, etc.

Player choice → `Sim.grant_credit(request)` or `Sim.refuse_credit(request)`:
- **Grant:** inventory −qty now; entry added to `GameState.credit_ledger`.
  On the due day, roll reliability: paid in full (cash +amount, reputation +1,
  that customer becomes a regular) or partial default (pay 50%, reputation −0,
  trait "people/trusting" recorded either way).
- **Refuse:** reputation −0.5 (word gets around), trait "people/cautious".
No labels shown. No "trust score." Consequences only. (Design Laws 3 & 9.)

### 4.3 Bulk order offers
Event `bulk_order_offer`: "A lodge wants `qty (30–60)` soaps at `₹(cost+4..cost+8)`
— below your price, above your cost. Deliver in 2 days or decline."
Accept → inventory reserved; if you can't cover it by the deadline, reputation −3
and the deal cancels. Teaches: volume vs margin, and over-commitment risk.

---

## 5. Real Stakes (fixes two shipped bugs)

### 5.1 Rent is actually charged
Inside `run_day()`: `if GameState.day % SimConfig.MONTH_LENGTH_DAYS == 0:`
charge `SimConfig.RENT`, emit `month_ended`. If cash goes negative: NO game-over
(Design Law 6). Instead, next day Events fires `lender_offer`: "Mahajan offers
₹5,000 now, repay ₹6,000 by next month-end." Accept → cash +5000, ledger entry;
miss the repayment → reputation −10 and the debt rolls with +₹500. Broke = a
harder path, never death. Trait "risk" recorded on the choice.

### 5.2 Expansion costs real money
`Sim.expand_shop()` must require and deduct `SimConfig.EXPANSION_COST = 8000.0`
(return `false` + no-op if cash < cost is FINE — the mission simply isn't
completable yet, which creates the endgame push). Expansion effect in Chapter 1:
capacity ×1.5 (rounded) and `daily_costs += 50` (bigger shop, bigger bills).
It's a real trade, not a flag.

---

## 6. Mission Rework (Chapter 1 stays 5 beats, now with teeth)

`MissionData.chapter_1()` updated. New condition types needed in MissionManager:
`credit_decisions_at_least`, `regulars_at_least`, `survived_event`,
`cash_at_least_on_day`. Conditions checked ONLY on the five events from §2.2.

1. **Opening Day** — serve 20 customers *(unchanged; noise now makes it non-trivial)*
2. **Running Out of Stock** — restock to 60+ *(now: supplier cost moves — buy smart)*
3. **The Long Queue** — hire Ravi *(unchanged trigger; queue now costs regulars, so it hurts until you do)*
4. **Month-End** — reach day 30 **with rent actually paid and cash ≥ 0** (condition: `cash_at_least_on_day {day:30, value:0}`); the lender path exists if it goes wrong
5. **The Shop Next Door** — expand, now genuinely ₹8,000 (condition unchanged, but it's earned)

Every mission passes the Coffee Shop Test with the new systems:
*"I gave Sharma-ji credit and he never paid"* / *"I bought 200 units right before
the price crashed"* — stories, not levels.

---

## 7. Save / Load (Sprint 1 Task 6, unblocked)

`SaveManager.gd`: `save_game()` / `load_game()` / `has_save()`.
Serialize the FULL GameState (including rng seed+state, active_effects,
credit_ledger, regular_count, current_unit_cost) + current mission id + unlocked
to `user://save_v1.json` with a `"version": 1` field. Auto-save after every
`day_ended`. Load on boot if a save exists (Game.gd offers Continue / New Game).

---

## 8. Testing Requirements (Claude Code owns these)

Create `tests/` with a headless-runnable GDScript harness (`godot --headless -s`):

1. **test_signals.gd** — `changed` never completes a mission; the five events do;
   no same-instant cascade M4→M5.
2. **test_economy.gd** — fixed seed, 60-day auto-run at default price: cash stays
   within a sane band (never > ₹60k, never < −₹10k); rent charged on days 30, 60;
   regulars grow on clean days and drop on stockouts.
3. **test_events.gd** — with seed sweep (100 seeds × 30 days): event frequency
   within ±20% of weights; every multi-day effect expires; telegraph always
   precedes effect by exactly 1 day.
4. **test_credit.gd** — grant/refuse paths mutate ledger, cash, reputation,
   regulars correctly; due-day resolution fires.
5. **test_save.gd** — save → mutate → load → state identical (deep compare).
6. **test_missions.gd** — scripted playthrough completes Chapter 1; expansion
   refused when cash < 8000.

All tests must pass headless with exit code 0. CI-style one-liner documented in
README.

---

## 9. Balancing First Pass (SimConfig deltas — tune later by playtest)

```gdscript
const NOISE_MIN := 0.75            const NOISE_MAX := 1.25
const COST_MIN := 16.0             const COST_MAX := 26.0
const COST_DRIFT := 0.5
const EXPANSION_COST := 8000.0     const EXPANSION_EXTRA_DAILY := 50.0
const EXPANSION_CAPACITY_MULT := 1.5
const CREDIT_REQUEST_CHANCE := 0.15
const REGULAR_CAP := 40            const REGULAR_GAIN_CLEAN_DAY := 1
const REGULAR_LOSS_ON_TURNAWAY := 2
const LENDER_PRINCIPAL := 5000.0   const LENDER_REPAY := 6000.0
const LENDER_ROLL_PENALTY := 500.0 const LENDER_REP_HIT := 10.0
const BULK_QTY_MIN := 30           const BULK_QTY_MAX := 60
const BULK_REP_PENALTY := 3.0
const EVENT_WEIGHTS := { "none":55, "festival_rush":8, "heavy_rain":8,
  "supplier_hike":7, "supplier_deal":6, "competitor_discount":8, "bulk_order_offer":8 }
```

Success test after build: a fresh player at default price should survive Month-End
roughly 70% of the time WITHOUT the lender, and expansion should be reachable
around day 40–55. Verify with the 100-seed sweep; tune SimConfig only.

---

## 10. Sprint Plan for Claude Code

- **Sprint L1-A:** §2 signal redesign + §5 stakes fixes + tests 1, 2 → review gate
- **Sprint L1-B:** §3 uncertainty engine (noise, events, cost drift) + test 3 → review gate
- **Sprint L2:** §4 customers (mix, regulars, credit, bulk) + §6 missions + tests 4, 6 → review gate
- **Sprint L3:** §7 save/load + test 5 + Game.gd UI hooks for events/credit choices → review gate
- **Sprint L4:** 100-seed balance sweep, tune SimConfig to §9 success test, update README/TASKS → HUMAN PLAYTEST GATE

UI in Game.gd may remain functional/ugly. Gameplay truth > polish. Android export
stays gated for after the human playtest.

---

*BizTown is not about becoming rich. It is about becoming capable.*
