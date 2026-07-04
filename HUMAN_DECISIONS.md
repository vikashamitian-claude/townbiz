# Human Decisions Log

## 2026-07-03 — Presentation pivot: 3D walkable town (APPROVED by Vikash)

**Trigger:** First real playtest (Godot Android editor, on-device). The Living
Business engine worked, but Vikash rejected the gray-box 2D presentation:
"rewrite everything... I want a virtual 3d game like PUBG, not the way it is shown."

**Clarified with owner (chip choice):** He wants the *feel of a walkable 3D
world*, NOT combat/battle-royale, NOT an engine switch. Chosen option:
**"3D walkable town in Godot"** — keep the verified sim engine and the
phone-based workflow, replace only the presentation layer.

**Decision record:**
- Presentation becomes a stylized 3D town (graybox first, low-poly assets later).
  A small, intimate town — the founder's own street, not an open world — which
  keeps FOUNDATION.md's "intimate, a founder's rise" law intact. FOUNDATION.md
  itself is unchanged (its bans on combat/open-world bloat still stand).
- The simulation engine (`scripts/sim/`, `scripts/events/`, `scripts/mission/`,
  `scripts/save/`) is NOT modified. The 3D world is a new view layer speaking to
  the same autoloads and signals.
- CODING_RULES.md stack line "2D Isometric" is superseded → "3D stylized
  low-poly" (this log is the authority for that edit).
- Combat, guns, battle-royale: explicitly NOT approved. Asked and declined.
- Engine/platform switch (Unity/Unreal): explicitly NOT approved. Godot stays
  (only engine with an Android editor — required by the phone-only workflow).
- Android export remains gated.
- Old 2D scene (`scenes/Game.tscn` + `scripts/Game.gd`) is kept in the repo as
  a working fallback until the 3D town reaches feature parity, then retires.

**Phased plan:**
1. **Phase 3D-1 (now):** graybox 3D town — walkable player (touch joystick),
   soap shop, road, customers as 3D figures, contextual interactions (manage
   shop at the counter, hire Ravi in person, expand next door in person), all
   existing modals/HUD. Same sim, same missions, same save.
2. **Phase 3D-2:** replace graybox with free CC0 low-poly assets (e.g. Kenney
   packs; Vikash can download on phone and upload via GitHub web).
3. **Phase 3D-3:** character/animation polish, interiors, town life.

## 2026-07-04 — Customer-experience content expansion (APPROVED by Vikash)

**Trigger:** Vikash asked whether ML could "automatically give the customer
experience." Clarified via two rounds of AskUserQuestion: not literal ML
(no practical on-device runtime for a mobile Godot game, and the existing
noise/archetype system already delivers "feels alive" without it) — he wants
richer/more varied customer behavior. He picked all three options offered:
more day events, customers who feel like recurring people, and demand/regulars
feedback surfaced as felt patterns rather than raw numbers.

**Decision record:**
- Two new day events added (`local_holiday`, `wedding_season`), reusing the
  existing one-day/multi-day effect mechanisms exactly — no new mechanic.
- Named credit customers now have persistent memory
  (`GameState.customer_relationships`): repeat payers nudge more trustworthy,
  repeat defaulters nudge less, both clamped to a wider range than the
  fresh-roll band so the effect is actually felt. Persisted in saves.
- Regulars growth/loss surfaced as diary lines (first regular, +5 milestones,
  drops) in both `Game.gd` and `Town3D.gd`.
- Architecture boundaries preserved: all new tunables in `SimConfig.gd`;
  `EventEngine.gd` still only supplies data, `Sim.gd` still owns all
  mutation; `GameState`'s new helper is bookkeeping only (same shape as the
  existing `add_trait()`).
- This is content growth beyond the original `BIZTOWN_BUILD_SPEC.md` mission
  set — approved directly by the product owner in this exchange, not guessed.
- Real ML (on-device inference, LLM-generated text, a model that trains on
  player behavior): NOT approved, not built. If wanted later, that's a
  separate, larger architectural decision.
- Balance impact flagged, not silently absorbed: adding two new weighted
  events shifts every other event's relative frequency (including "none")
  down slightly. `tests/BalanceSweep.gd`'s §9 targets should be re-checked
  once it can actually run.
