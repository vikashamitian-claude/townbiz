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

## 2026-07-04 — Long-term vision: multi-business 3D world (APPROVED by Vikash)

**Trigger:** Vikash set the long-term product direction explicitly: BizTown
becomes a walkable 3D world where players choose a business path (soap shop,
construction materials, transport, restaurant, dairy, farming, factory,
finance, real estate, hotel, pharmacy, hospital, software startup, etc.) that
eventually connect into one living economy — competition/collaboration
through business decisions, not combat. He gave an explicit, disciplined
phased instruction: stabilize first, add only a lightweight architecture
foundation now, do not jump to multi-business gameplay or multiplayer yet.

**Decision record:**
- **Long-term direction accepted.** `FOUNDATION.md` (frozen) and
  `BIZTOWN_BUILD_SPEC.md` currently scope Chapter 1 to one soap shop, and
  explicitly mark multi-product/multi-business/multiplayer as Chapter 2+.
  That boundary stands for what's *playable* today — this decision only
  authorizes building toward it, not skipping ahead into it. Neither frozen
  doc is edited; this log is the record of the direction change, same
  pattern as the 3D-pivot and customer-variety entries above.
- **Factual correction, not a silent guess:** the instruction assumed the
  current MVP is a construction materials store. It is not — every mission,
  the shop sign, `BIZTOWN_BUILD_SPEC.md`, and this whole log are built around
  a **soap** shop. Flagged to Vikash directly rather than silently reskinning
  the existing, tested, narratively-coherent game. Soap Shop stays the
  default/active business type; Construction Materials was added instead as
  the second, non-playable, architecture-proving placeholder his own
  instructions explicitly allowed ("a second placeholder... minimal data
  only").
- **What was built (Phase 1-2 of his instruction, this session):**
  `scripts/business/BusinessType.gd` (pure data: identity + Chapter-1-scale
  starting numbers — NOT the tuned demand/capacity/event formulas, which
  stay in `SimConfig.gd` and are not generalized yet) and
  `scripts/business/BusinessRegistry.gd` (static lookup, two entries: the
  real `soap_shop` mirroring current `SimConfig` values exactly, and a
  `construction_materials` placeholder with distinct minimal numbers, wired
  to nothing). `GameState.active_business_id` added and persisted, always
  `soap_shop` on reset today (no business-select screen exists yet).
  `Town3D.gd`'s shop sign, counter title, expanded-shop sign, and the
  new-game diary opener now read from the active business type instead of
  hardcoded strings — zero behavior change for the current game, but a real,
  working proof that swapping identity flows through the game.
- **Explicitly NOT done this session** (each is real future work, not
  forgotten): a business-select screen/menu, multi-business gameplay
  (missions/economy/NPCs per business type), connecting businesses into one
  economy, and any multiplayer/networking. Building any of these before the
  current Chapter 1 loop has been confirmed working on-device would be
  exactly the premature complexity his own instructions warned against.

## 2026-07-05 — Construction-first vision + persistence law (DIRECTION set by Vikash)

**Trigger:** First session from the Windows desktop (prior work was phone-only
from the Android editor). Vikash laid out the long-term game vision across a
design discussion and asked to capture it. Full write-up:
`DESIGN_CONSTRUCTION_ECONOMY.md`. This entry records the decision and the one
verified engine fact that matters.

**Decision record (direction, not an approved build spec — Chapter 2+):**
- **Keystone law stated by Vikash:** *"What is built in the game stays in the
  game as basic structure."* Everything the player constructs is permanent,
  load-bearing world; the town only accretes across sessions. This is now the
  north-star principle for the multi-business direction (consistent with the
  2026-07-04 multi-business entry above, which it extends — it does not replace
  the disciplined "stabilize Chapter 1 first" stance).
- **Construction is the foundational business,** because commerce is built on
  infrastructure first. The playable unit is **one contract**: the player is a
  contractor who buys materials (cement/TMT/etc. from in-game material shops),
  builds one structure, and gets paid. That structure persists and becomes a
  future business location — the contractor manufactures the rest of the game.
- **Dependency chains + govt/private demand** turn "build one by one" into an
  ordering strategy (roads unlock districts that make private contracts viable).
- **Township planning is the teaching layer,** scored by a **split evaluation
  system**: engine computes the *measurable* criteria (fair, deterministic,
  reproducible); AI judges *subjective* criteria against a written rubric and
  **coaches/corrects** — the AI does NOT hold the scoreboard. Same discipline as
  the 2026-07-04 "no real ML deciding outcomes" stance.
- **Arc:** plan → build (manual contractor loop; auto-mode is a time-skip only,
  never the default) → run businesses. **New businesses emerge from demand**
  (deterministic thresholds; AI narrates, does not decide), and the causal chain
  must be visible to the player.
- **Co-op/multiplayer: PARKED, not approved.** Networking is a scope bomb; design
  for serializable state so it's possible later, but do not build netcode until
  single-player is proven fun.

**Verified engine fact (checked against code this session, load-bearing):**
- The keystone law is **NOT true in the engine yet.** `SaveManager.gd` persists
  only sim state (`GameState` numbers/flags + `Missions`); the 3D town is
  **regenerated from code** in `Town3D.gd::_ready()` every launch. Shop expansion
  and Ravi are booleans flipping mesh visibility, not saved structures. **Nothing
  the player builds currently persists, because nothing built is recorded.**
- **Named prerequisite:** the town must become **data, not code** — a
  serializable "built world" registry (structure type/position/state) that the
  save writes/reads and `Town3D` rebuilds from, mirroring the existing
  `BusinessRegistry`/`BusinessType` pattern. This is the one architectural
  foundation everything else in the vision stands on; build it before piling art
  or new businesses on the hardcoded town.

**Art direction (this session):** target is **stylized low-poly** (not realistic).
The real-asset swap was blocked on Android (no network to asset sites, no Godot to
verify imports). The Windows desktop unblocks it — Godot 4.7 is present locally, so
CC0/low-poly packs (Kenney free; Synty POLYGON as a paid step up) can be imported
*and verified in the editor* here. `GrayboxKit.gd` remains the single swap point;
the procedural low-poly upgrade already lives on the unmerged Phase 3D-2 branch.
