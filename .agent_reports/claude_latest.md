# Claude Code Report — Phase 3D-2: procedural low-poly town upgrade

Date: 2026-07-04

- STAGE: Sprint 3D, Phase 3D-2 (Vikash: "continue Phase 3D-2 with the
  low-poly assets")
- STATUS: PASS WITH MINOR FIXES — visual upgrade complete and parse-verified;
  on-device confirmation pending (as with everything this session, nothing
  has executed anywhere yet)

## Key decision (recorded in HUMAN_DECISIONS.md)

The original 3D-2 plan called for external CC0 packs (Kenney-style). The
cloud sandbox can't fetch them (network scoped to this repo only), and
importing binary `.glb` files blind — no Godot to check scale, materials, or
import settings — is the riskiest possible change type. Implemented 3D-2 as
a **procedural low-poly upgrade** instead: Godot built-in meshes only,
text-diffable, GL-Compatibility-safe, fully parse-verifiable. External packs
remain a later option; `GrayboxKit.gd` is still the single swap point.

## What changed

### `scripts/world3d/GrayboxKit.gd` (238 lines, rewritten)
- `building()` — NEW: colliding walls + gabled `PrismMesh` roof + door and
  window on the road-facing side. Wall mesh named `"Wall"` (a stable
  contract — Town3D repaints it on shop expansion, now by name instead of
  the old fragile `get_child(1)` index).
- `person()` — upgraded: capsule body + sphere head + two angled arms
  (`ArmL`/`ArmR`); `tint_person()` recolors arms along with the body.
- `tree()` upgraded (trunk cylinder + two-sphere crown), `pine_tree()` NEW
  (stacked cones), `lamp_post()` NEW (pole + emissive glowing head),
  `crate()` NEW. Shared `_mat()` helper for materials, with an emissive
  option.
- `static_box`/`visual_box`/`label3d` signatures unchanged.

### `scripts/world3d/Town3D.gd`
- Shop and neighbor now `building()`s with roofs (same footprints and
  colliders as before — every interaction point constant untouched).
- Counter gained a sloped awning and stacked stock crates beside it.
- All five filler houses became real houses (roofs, doors, windows, varied
  wall/roof colors; the two south-side houses face the road correctly).
- Road gained sidewalks and center dashes; four glowing street lamps along
  it; tree mix is now round + pine.
- Customers spawn with varied clothing colors (cosmetic-only `randi()`,
  which biztown-rules explicitly permits outside `GameState.rng`).
- Shop/neighbor sign labels raised to clear the new roofs.
- `_paint_neighbor()` uses `get_node_or_null("Wall")` — expansion repaint
  survives any future reordering of building children.

### `scripts/world3d/Player3D.gd`
- The founder gained arms (matching the upgraded people).

## Invariants deliberately preserved

- Every `*_POS` interaction constant unchanged; every collider footprint
  identical → walking, counter/hire/expand zones, and customer walk paths
  behave exactly as the last on-device test.
- Zero sim/engine changes. Zero save-format changes.
- No imported binary assets — repo stays all-text.

## Verification

`gdformat --check`: all 16 `.gd` files parse with zero errors (style-only
"would reformat" diffs, as always). `gdlint scripts/world3d`: only the
long-known `Town3D.gd` file-length flag (1100 lines) plus pre-existing
line-length style flags — no new structural findings; the two long lines my
own edits introduced were wrapped before commit.

**Not verified by execution** — same standing gap. The visual result
especially needs eyes: mesh proportions/colors are reasoned, not seen.
A single screenshot of the new town from Vikash's phone confirms (or
corrects) the whole phase.

## Next recommended step

1. Vikash: fresh ZIP of the branch → import → **Play** → screenshot the town
   (this phase is visual; the screenshot IS the test).
2. Still outstanding since session start: `tests/TestRunner.tscn` first-ever
   run.
3. Phase 3D-3 after visual sign-off: interiors, simple walk animation
   (arm/leg swing), ambient townsfolk.
