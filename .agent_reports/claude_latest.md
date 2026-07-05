# Claude Code Report — Built-world registry (the §7 persistence prerequisite)

Date: 2026-07-05

- STAGE: implementing the one architectural prerequisite named in
  `DESIGN_CONSTRUCTION_ECONOMY.md` §7 (which landed on main from Vikash's
  Windows session): make the town DATA, not code, so the keystone law
  ("what is built stays") has a mechanism.
- STATUS: PASS WITH MINOR FIXES — implemented, parse-verified, zero behavior
  change today; on-device confirmation pending as always.

## Context

Vikash's Windows-desktop session captured the construction-first vision and
verified the engine gap: SaveManager persisted only sim numbers, and Town3D
regenerated the whole physical town from hardcoded code every launch —
nothing built could ever persist. §7 named the fix (a serializable
built-world registry mirroring the BusinessRegistry pattern) and called it
the strategic priority BEFORE more content. This session implemented exactly
that and nothing more.

## What was built

- **`GameState.built_structures: Array`** — the town as JSON-safe data
  (dicts with `type`, `pos [x,y,z]`, per-type fields; arrays not
  Vector3/Color because saves round-trip through JSON). Seeded on every
  reset from `DefaultTown.layout()`, persisted in `to_dict()`/`from_dict()`
  (parity re-verified programmatically). Old saves without the field get the
  default town — identical to what their game hardcoded when they were
  written.
- **`scripts/world3d/DefaultTown.gd`** — the previously-hardcoded town
  layout (shop, neighbor, 5 houses, 6 trees, 4 lamps) as pure data. All
  numeric literals deliberately floats, because JSON parsing floats all
  numbers and the save test compares JSON-visible state.
- **`scripts/world3d/StructureCatalog.gd`** — data → meshes bridge
  (`building`/`tree`/`pine`/`lamp`/`crate` via GrayboxKit), with a loud
  `push_warning` on unknown types (same discipline as EventEngine's
  unmatched-event guard: a saved structure must never silently vanish).
- **`Town3D`** — registry structures now live under one `structures_root`;
  `_rebuild_structures()` clears and rebuilds from `GameState.built_structures`,
  re-grabs the `shop`/`neighbor` refs by entry id, and re-applies the
  expansion repaint. Called from scene start, **Continue** (the loaded
  registry is the truth, not what `_ready()` seeded — this ordering matters
  and was the subtle part), and **Reset**. Storefront dressing (door,
  window, signs, counter, awning, crates) stays code-side, tied to the
  shop's default spot.
- **`tests/TestRunner.gd` `_test_save`** — comparison now normalizes both
  sides through a JSON round-trip before comparing. This fixes a **latent
  pre-existing test bug** my change would have made deterministic: JSON has
  no int/float distinction, so ints inside nested containers (credit_ledger
  qty/due_day, and now built_structures) legitimately come back as floats
  after save/load; the old exact-string compare would have flagged that as
  corruption. The test still checks full JSON-visible state equality —
  which is precisely what the save preserves.

## What this makes possible (and what it doesn't)

Any structure appended to `GameState.built_structures` now persists across
saves and rebuilds physically on load — the keystone law is mechanically
true. What does NOT exist yet, on purpose (per §11's boundaries): any
gameplay that places new structures (contracts, building UI), material
shops, planning tools. Those are the next chapters, standing on this floor.

## Known limitation (flagged, not hidden)

Storefront dressing positions assume the shop at its default spot. If a
future save ever relocates the `shop` entry, the dressing won't follow —
acceptable while nothing can move it; becomes real work when contracts
arrive.

## Verification

`gdformat --check`: all 18 `.gd` files parse, zero errors (style-only
diffs). `gdlint`: only the long-standing `Town3D.gd` file-length note.
Save/load field parity re-checked programmatically. Save round-trip traced
by hand against `_test_save` including the int/float JSON subtlety above.
**Not executed** — same standing gap; note the Windows machine now HAS
Godot 4.7 per §8, so both `tests/TestRunner.tscn` and a desktop playtest
are now one double-click away there, no phone required.

## Exact next recommended step

On the Windows machine (which has Godot 4.7):
`godot --headless --path . res://tests/TestRunner.tscn` — the suite's
first-ever execution, now with the registry round-trip included. Then Play
to eyeball the Phase 3D-2 town + confirm Continue rebuilds it correctly.
