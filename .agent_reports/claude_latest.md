# Claude Code Report — Contract variety: the town-planning curriculum begins

Date: 2026-07-05

- STAGE: extension of the contractor loop per Vikash's framing — "a learning
  and fun platform of real business... town planning is also a course."
- STATUS: PASS WITH MINOR FIXES — implemented, parse-verified; execution
  pending on the Windows machine's Godot 4.7.

## What Vikash asked and how it was scoped

He named the full town vocabulary (houses, shops, warehouses, factories,
agriculture, roads, bridges, offices, drainage, water channels) as things
players should LEARN through play. Split into:

1. **Captured as curriculum** — DESIGN_CONSTRUCTION_ECONOMY.md §12: the
   vocabulary IS the syllabus; a table maps each element to the economic
   lesson it teaches. Terrain-shaped infrastructure (roads, bridges,
   drainage, water channels, agriculture) is explicitly assigned to the
   township-planner phase, where measurable scoring makes them teach rather
   than decorate. Not built now — on purpose, recorded.
2. **Implemented now** — the plot-buildable subset through the existing,
   just-built contract loop.

## What was built

- `SimConfig.CONTRACT_PROJECTS`: four commissionable types — House, Shop,
  Warehouse, Office — each with size, materials-cost range, and a one-line
  "teach" sentence (the lesson). Replaces the single hardcoded house
  project; the now-redundant `CONTRACT_MATERIALS_MIN/MAX` and
  `CONTRACT_HOUSE_SIZE` constants were removed (no dead tunables).
- `GrayboxKit.warehouse()` (flat overhung roof, wide loading door) and
  `GrayboxKit.office()` (taller block, height-scaled window grid), sharing
  a new `_walled_box()` helper with the existing gabled `building()`. Wall
  meshes named "Wall" throughout — the repaint contract holds.
- `StructureCatalog`: `warehouse`/`office` cases + optional `label` field —
  contracted structures now carry a floating name label ("WAREHOUSE"), so
  the growing town reads as WHAT it is.
- `EventEngine.maybe_roll_contract_offer()` picks a project via
  `GameState.rng`, carries `label` + `teach` through the offer.
- `Sim.gd` threads label/teach through `active_contract` into the
  completion result (persisted mid-contract saves included).
- Both UIs: the offer modal is typed ("Build contract: Warehouse... wants a
  warehouse built... Profit: Rs N"), and on completion the diary teaches:
  "Warehouses let goods wait for the right price instead of flooding the
  market." The 2D fallback also gained completion diary lines (it had
  none — contracts finished silently there; gap found while wiring this).

## Verification

`gdformat --check`: all 18 files parse, zero errors. `gdlint`: only
pre-existing known flags. No stale references to the removed constants
(grepped). Suite 7 still passes by construction (it builds its own offer
dicts; `label`/`teach` are read with safe `.get()` defaults everywhere).
Not executed here — Windows can run the full suite + playtest.

## Exact next recommended step

Same as before, one command on Windows:
`godot --headless --path . res://tests/TestRunner.tscn` (7 suites), then
Play — take contracts until a warehouse or office comes up, watch the town
gain labeled, varied buildings, and check the diary teaches its line.
