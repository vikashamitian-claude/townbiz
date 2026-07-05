# Design Vision — Construction-First, Player-Built Economy

**Status:** Long-term *direction*, not an approved build spec. Captured from a
design discussion with Vikash on 2026-07-05. This does **not** override
`FOUNDATION.md` or `BIZTOWN_BUILD_SPEC.md`, which still scope what is *playable
today* to Chapter 1 (one soap shop). This is the Chapter 2+ north star and the
reasoning behind it, written down so it survives across sessions/devices. Where
this doc states a fact about the current engine, it has been verified against
the code; everything else is intended design, not yet built.

---

## 1. The keystone law

> **What is built in the game stays in the game as basic structure.**

Everything the player constructs becomes permanent, load-bearing world that the
rest of the game runs on top of. The town only ever accretes — no resets, no
level wipes. Session N is built on session N-1. This is the emotional hook (it
becomes *your* town because nothing you built disappears) and the structural
spine (every later system stands on the world the player already built).

**This is currently a slogan the code does not yet back — see §7.**

## 2. Why construction is the first business

Vikash's thesis: in the real world, everything commercial is built on
infrastructure first — roads, buildings, markets, logistics. So the game's
foundational business is **construction**, and the player begins by building the
virtual world that every later business will occupy.

Refined so it is a *game* and not a spreadsheet: the unit of play is **one
contract**, not "run a construction empire." The player is a **contractor** who
takes a single build job, buys materials, delivers a finished structure, and
gets paid. That is a small, teachable money loop (inputs → build → payment) and
it doubles as the mechanism that populates the world.

## 3. The contractor loop

- The player is a **contractor** hired to build a structure (shop, house, road,
  market, residential complex, township, etc.).
- **Materials come from in-game shops** — cement, TMT (steel), bricks, and other
  materials. These material shops are themselves businesses (NPC-run at first,
  player-ownable later — a natural second business tier).
- **Margin must be legible:** materials cost X, labor cost Y, contract pays Z,
  profit = Z − X − Y. If that math is visible, procurement (buy cheap this week,
  from which shop) becomes a real decision instead of a click.
- **Don't over-simulate buying.** Ordering materials is a *decision* (bundle,
  prices vary by shop/week), not a chore of many trips.

### The self-reinforcing recursion (the reason construction is business #1)

```
contractor buys materials from material shops
        → builds more shops/buildings
        → those shops sell more materials / create demand
        → funds more builds → ...
```

The contractor **manufactures the rest of the game.** Every building it puts up
is a future business location. This is the cleanest expression of the keystone
law: the player isn't decorating a pre-made town, they are producing the town's
economy one commissioned building at a time.

## 4. Dependency chains (what makes "build one by one" a game)

Infrastructure has prerequisites — the player's own opening point. Bake it into
the projects so ordering becomes strategy, not a checklist:

- **Roads** open access to an area — no road → shops there can't be built or earn
  nothing.
- **A market** nearby raises the value/viability of surrounding shops.
- **Utilities/buildings** gate which businesses can exist.

With limited cash and time, "what do I build first to unlock the most value?"
becomes the core strategic question.

### Government vs private demand (a real tension, not flavor)

- **Govt contracts** (roads, public markets, civic buildings): steadier, often
  lower margin, but they *open up areas* and build reputation.
- **Private contracts** (shops, buildings): higher margin, but frequently only
  possible/valuable *after* the govt infrastructure exists.

The player constantly weighs: take the low-margin govt road that unlocks a whole
district of lucrative private work, or grab quick private cash now? That single
choice teaches the whole thesis — *infrastructure enables commerce* — as a felt
mechanic, not a lecture.

## 5. Township planning with a split evaluation system

The **teaching/onboarding layer**: before (or as) the player builds, they **plan
a township** — place residential complexes, houses, roads, markets, etc. — and
the plan is scored, with feedback and corrections, so the player *learns how a
town fits together*.

**The evaluation system is defined first, and scoring is split** so it stays fair
where it must and smart where it helps:

- **Measurable criteria → computed by the engine.** Road access, walkability
  distance, residential/commercial balance, green-space ratio, cost efficiency,
  traffic. Deterministic, instant, identical every time — no AI needed, so a
  given plan always scores the same and the player can *learn the rules*.
- **Judgment criteria → AI judges against the written rubric.** Coherence, "does
  it read like a real town," creativity. The AI is good here *because* it is
  handed an explicit rubric to judge against, not vibes.

The AI **coaches and corrects** ("your east block has no road to the market —
that's why walkability tanked; run a road here") and can propose a corrected
plan. It does **not** hold the scoreboard. Rationale: an inconsistent score
(same plan, different result) makes players feel cheated and quit.

The rendered result ("see what's coming out") reuses the existing 3D town
(`Town3D.gd`, `GrayboxKit.gd`) as the renderer — the plan renders as the graybox
town already in the repo.

## 6. The plan → build → run arc

1. **Plan** the township — creative, scored against the split evaluation system.
   This is the cheap-iteration phase; get it right *here*, because once built it
   is permanent (§1).
2. **Build** it — manually as the contractor (the core money-loop game), with
   **auto-mode as an optional time-skip** ("auto these 20 identical houses"), NOT
   the default. Guardrail: if auto-mode builds everything, the game plays itself
   and the core loop is skipped. Manual build is where the money loop lives.
3. **Run** the businesses in the town the player built — the eventual deep game.
4. **(Later milestone) Co-op** — invite friends to build the township together.

### Economy first, then new businesses emerge

The long-term rule: **the player builds the economy, then the game introduces new
businesses into it** — and new businesses should emerge from **demand**, not
arbitrary unlocks:

- Player builds housing → population grows → demand for groceries → once demand
  and money cross a threshold, a grocery becomes available → the grocery creates
  demand for a supplier → the supplier becomes available → ...

The economy propagates itself; every new business is *caused* by the player's
construction. The **trigger is deterministic and legible** (population,
circulating wealth, unmet demand); the **AI narrates/flavors** the arrival, it
does not decide it on a whim (same discipline as §5).

**Critical for the magic to land:** the player must *see the causality* — "I built
housing → population rose → the town needed a grocery → grocery unlocked." If new
businesses just quietly appear, it feels like random loot and the elegance is
invisible. Surface the chain.

## 7. Engine reality check — the keystone law is not yet true (VERIFIED)

Verified against the code on 2026-07-05:

- `scripts/save/SaveManager.gd` persists **only sim state** —
  `GameState.to_dict()` (money, day, reputation, price, inventory, flags) plus
  `Missions.to_dict()`. There is **no saved list of built structures.**
- The physical town is **regenerated from code** in `Town3D.gd::_ready()` every
  launch. The only "structure" that reflects state is the shop expansion and
  Ravi — and those are booleans (`has_expanded_shop`, `has_ravi`) flipping a
  pre-made mesh's visibility, not persisted *structures*.

**So today, nothing the player constructs actually persists, because nothing the
player constructs is recorded.** For the keystone law to become real, the town
must become **data, not code**: a serializable registry of placed structures
(type, position, state) that (a) the save writes/reads and (b) `Town3D` rebuilds
the world from, instead of hardcoding it.

This is the same pattern already proven for businesses
(`scripts/business/BusinessRegistry.gd` / `BusinessType.gd`). The world needs its
equivalent: a "built world" registry as the single source of truth for what
stands in the town.

**Strategic priority:** build this persistence foundation *before* piling content
(art, new businesses, planning tools) on top of a hardcoded town — otherwise
retrofitting persistence later is a painful rewrite. "Everything is built on
infrastructure first" applies to the codebase too: this registry is the
infrastructure.

## 8. Art direction (see also HUMAN_DECISIONS.md, 2026-07-05)

- The current abstraction (cube people, sphere trees, box buildings) is
  intentional **graybox**; `GrayboxKit.gd` is the designed single swap point.
- Target style: **stylized low-poly** (reads as a real world, cheap to run,
  cohesive, no 3D-modeling skill required). Realistic is explicitly not the goal.
- The real-asset step was blocked on Android (sandbox couldn't fetch asset sites
  or verify `.glb` imports without Godot). **Windows unblocks it** — Godot 4.7 is
  present on the Windows machine, so real CC0/low-poly packs (Kenney free; Synty
  POLYGON as a paid step up) can be downloaded *and* verified in the editor here.
- Guardrail: a low-poly kit is "better graybox," not final polish — get the world
  representational enough to enjoy building, then get back to proving the loop.

## 9. The prototype goal — prove ONE causal loop

The smallest thing worth building to prove this whole vision works:

> **Build one thing → watch one economic number move → that movement makes one
> new business appear, legibly.**

If that single causal step feels good and readable, the entire game is that step
on repeat. If it doesn't, no amount of content saves it. The material shops
(cement/TMT) are already a built-in first example: the contractor's own demand
for materials justifies introducing supply businesses.

## 10. Explicitly parked (not forgotten, not approved)

- **Co-op / multiplayer** — networking is a scope bomb; deferred hard. Design the
  township as clean serializable state so a second player *could* join later, but
  do **not** build netcode into the prototype. Prove single-player is fun first.
- **AI holding the scoreboard** — no; AI coaches and narrates, engine scores the
  measurable parts (§5, §6).
- **Auto-mode as the default build path** — no; it's a time-skip only (§6).
- **Full art pass before the loop is proven fun** — no (§8).

## 11. Boundaries preserved

Consistent with prior decision entries: this doc records *direction and
reasoning*. It does not edit `FOUNDATION.md` or `BIZTOWN_BUILD_SPEC.md`, and it
does not authorize skipping ahead of the current Chapter 1 loop. It authorizes
*building toward* this vision when the owner chooses to, and it names the one
architectural prerequisite (§7) that everything else depends on.
