# BizTown: Build Your Empire

A business tycoon game built in **Godot 4.x / GDScript** with an **Android-first** target.

The current active build is Chapter 1, "Living Business": set a soap price under real
demand uncertainty, manage a drifting supplier cost, decide on credit requests and bulk
orders, serve customers, hire Ravi, survive month-end (rent is real, and going broke means
a harder path via a lender — never a game over), and decide whether to expand. See
`BIZTOWN_BUILD_SPEC.md` for the full design (wins over any older sprint doc it conflicts
with) and `FOUNDATION.md` for the frozen design laws.

## Stack

- Engine: Godot 4.x (GL Compatibility renderer)
- Language: GDScript
- Layout: Portrait 720x1280
- Target: Android first

## How to run

1. Install **Godot 4.x** (standard build, not Mono/C#) from <https://godotengine.org/download>.
2. Open Godot, choose **Import**, and select this `biztown` folder (the one with `project.godot`).
3. Press **F5**. Godot runs `scenes/Game.tscn`.

## Try it on Android

1. In Godot, use **Editor -> Manage Export Templates -> Download** for your Godot version.
2. Use **Project -> Export -> Add... -> Android**. Install the Android SDK and set up the
   debug keystore when Godot prompts (one-time).
3. Plug in a phone with USB debugging on and click **Run on device**, or **Export Project**
   to build an APK.

Note: the repo does not yet include an Android export preset.

## Running the automated tests

```
godot --headless --path . res://tests/TestRunner.tscn
```

Exit code 0 means all 6 suites (signals, 60-day economy, event seed sweep, credit,
save/load, mission playthrough) passed. Suite-by-suite output prints to stdout.

To run the 100-seed x 60-day balance sweep (reports % surviving Month-End without the
lender, and the median day expansion becomes affordable — tune only `SimConfig.gd`
against these numbers, see `BIZTOWN_BUILD_SPEC.md` §9):

```
godot --headless --path . res://tests/BalanceSweep.tscn
```

## Active files

| File | Purpose |
|------|---------|
| `project.godot` | Engine config: portrait, mobile renderer, autoloads |
| `scenes/Game.tscn` | Active game scene (main scene) |
| `scripts/Game.gd` | Active gameplay presentation and UI script |
| `scripts/sim/GameState.gd` | Autoload `GameState`: simulation data, RNG, ledgers, active effects |
| `scripts/sim/Sim.gd` | Autoload `Sim`: simulation rules, `run_day()`, player actions |
| `scripts/sim/SimConfig.gd` | Every tunable number — the only place to balance the game |
| `scripts/events/EventEngine.gd` | Autoload `Events`: daily event rolls, telegraphs, credit/bulk/lender offers |
| `scripts/mission/MissionManager.gd` | Autoload `Missions`: event-driven Chapter 1 beat progression |
| `scripts/mission/MissionData.gd` | Chapter 1 mission data (beats, conditions, debriefs) |
| `scripts/save/SaveManager.gd` | Autoload `SaveManager`: JSON save/load, auto-saves on `day_ended` |
| `tests/TestRunner.gd` / `.tscn` | Headless test suite (see "Running the automated tests") |
| `tests/BalanceSweep.gd` / `.tscn` | Headless 100-seed balance sweep |
| `icon.svg` | App icon |

## Legacy files

These files are kept in the repo for reference but are **not** part of the active game.
None are loaded by `project.godot` or referenced by the active scene.

| File | Status | Notes |
|------|--------|-------|
| `scenes/Main.tscn` | Legacy | Old Stage 1 prototype scene |
| `scripts/Main.gd` | Legacy | Old Stage 1 prototype script |

## Governance documents

| Document | Purpose |
|----------|---------|
| `FOUNDATION.md` | Frozen design charter: pillars, design laws, 80% rule |
| `BIZTOWN_BUILD_SPEC.md` | Approved "Living Business" Chapter 1 build spec — wins over older sprint docs where they conflict |
| `PROTOTYPE_SPEC.md` | Earlier Chapter 1 spec: 5 beats, economy model, guardrails |
| `INTEGRATION.md` | Code-drop integration guide (autoload order, test command) |
| `KNOWLEDGE_MAP.md` | Entrepreneur Framework: business skills and mindset curriculum |
| `MISSION_TREE.md` | Mission structure across all chapters |
| `WHY_BIZTOWN.md` | Product vision and motivation |
| `ARCHITECTURE.md` | Core systems and design principles |
| `ROADMAP.md` | 5-phase development plan |
| `AGENTS.md` | AI agent roles and human approval gates |
| `CODING_RULES.md` | Stack rules, workflow, and report format |
| `DEVELOPMENT_AUTOMATION.md` | Autonomous development workflow |
| `TASKS.md` | Active sprint tasks and backlog |

## Tuning knobs

Every tunable number lives in `scripts/sim/SimConfig.gd` — that is the only file to edit
to balance the game.
