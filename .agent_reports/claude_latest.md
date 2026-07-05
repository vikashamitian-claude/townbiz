# Claude Code Report — Contractor loop MVP (the §9 causal loop, playable)

Date: 2026-07-05

- STAGE: first gameplay slice of the construction-first vision, per Vikash's
  "let's develop the whole game in the new guideline" (recorded in
  HUMAN_DECISIONS.md as explicit owner authorization).
- STATUS: PASS WITH MINOR FIXES — implemented end-to-end with a new test
  suite; parse-verified; execution pending (Windows machine has Godot 4.7
  and can run the whole thing headless now).

## What this is

DESIGN_CONSTRUCTION_ECONOMY.md §9 defines the smallest thing worth building:
*build one thing → watch one economic number move → the town visibly,
permanently grows.* This implements exactly that loop on top of the
built-world registry (same PR branch):

1. A **build-contract offer** arrives (10%/day when none is active and empty
   plots remain — same decision-modal pattern as credit/bulk/lender):
   "<Name> wants a house built. Materials Rs X now; pays Rs Z in N days.
   Profit: Rs Z−X." Margin legible per §3.
2. **Accept** → materials cost leaves cash immediately (fails politely if
   cash is short). **Decline** → nothing, trait recorded.
3. N days later, inside `run_day()` (all mutation before signals, same
   day+1 timing pattern as credit dues): the finished house is **appended to
   `GameState.built_structures`** — the persistent registry — payout lands,
   reputation +2.
4. Town3D rebuilds: **a real house appears on a previously-empty plot and
   stands in every save thereafter.** Diary narrates the causality: "X's
   house is finished — paid Rs Z. It stands as long as the town does."
   (§9: surface the chain.)

Offers stop when all 6 configured plots are built — the street is full;
growing the map is Chapter 2's problem.

## Where everything lives (architecture unchanged in shape)

- `SimConfig.gd`: all `CONTRACT_*` tunables (offer chance, materials range,
  margin range, build days, rep reward, plot list, house size/colors).
- `EventEngine.gd`: `maybe_roll_contract_offer()` — data + signal only,
  all randomness through `GameState.rng`.
- `Sim.gd`: `accept_contract()`/`decline_contract()` actions;
  `_process_contract()` completion inside `run_day()` step 7b, before the
  day increment and long before any signal fires.
- `GameState.gd`: `pending_contract_offer` / `active_contract` /
  `contracts_completed`, all persisted (parity re-verified). Structure
  entries are JSON-safe (floats/arrays) like everything else in the
  registry.
- Both UIs (`Town3D.gd` + `Game.gd` fallback): "contract" decision kind
  wired into the existing modal queue; Town3D also rebuilds structures and
  celebrates on completion.
- Missions untouched: contracts add NO mission-driving signals; the five
  events remain the only mission triggers.
- `tests/TestRunner.gd`: new suite 7 — accept pays materials, completion
  adds the structure + reports payout + advances the counter, decline is
  free, accept refused when cash < materials.

## Deliberate MVP simplifications (named, per the design doc's own §3/§10)

No material-shop entities yet (materials cost is one legible number), no
govt/private contract split, no deadline/failure on an accepted build, fixed
plot list. Each is real future work listed in TASKS.md — not scope creep
fodder for this slice.

## Verification

`gdformat --check`: all 18 `.gd` files parse, zero errors. `gdlint`: only
pre-existing/known flags. Save-format parity re-checked programmatically.
Timing of contract completion hand-traced against the credit-dues
off-by-one lesson (uses the same `day + 1` comparison). **Not executed
here** — but the Windows machine can now run
`godot --headless --path . res://tests/TestRunner.tscn` (suite 7 included)
and then Play: accept a contract, run ~4 days, watch a house appear, quit,
Continue, confirm the house is still there. That last check is the keystone
law working for the first time.

## Exact next recommended step

Windows: run the headless suite, then the playtest above. After that, the
natural next slices in order: contract deadlines/failure (stakes), material
shops with moving prices (procurement decisions), govt vs private contracts
(the strategic tension), then §6's demand-driven business emergence.
