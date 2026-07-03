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
