# BizTown: Build Your Empire

A business tycoon game built in **Godot 4.x / GDScript** with an **Android-first** target.

The current active prototype is Chapter 1, "Save My First Shop": set a soap price, serve
customers, manage stock, hire Ravi, survive month-end, and decide whether to expand.

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

## Active files

| File | Purpose |
|------|---------|
| `project.godot` | Engine config: portrait, mobile renderer, autoloads |
| `scenes/Game.tscn` | Active game scene (main scene) |
| `scripts/Game.gd` | Active gameplay presentation and UI script |
| `scripts/sim/GameState.gd` | Autoload: simulation state (cash, reputation, day, traits) |
| `scripts/sim/Sim.gd` | Autoload: simulation rules and day processing |
| `scripts/sim/SimConfig.gd` | Tuning knobs for Chapter 1 |
| `scripts/mission/MissionManager.gd` | Autoload: mission flow and beat progression |
| `scripts/mission/MissionData.gd` | Chapter 1 mission data (beats, options, outcomes) |
| `icon.svg` | App icon |

## Legacy and test files

These files are kept in the repo for reference but are **not** part of the active game.
None are loaded by `project.godot` or referenced by the active scene.

| File | Status | Notes |
|------|--------|-------|
| `scenes/Main.tscn` | Legacy | Old Stage 1 prototype scene |
| `scripts/Main.gd` | Legacy | Old Stage 1 prototype script |
| `scenes/MissionUI.tscn` | Unused | Standalone mission UI scene, not referenced by Game |
| `scripts/MissionUI.gd` | Unused | Script for MissionUI scene |
| `scenes/MissionTest.tscn` | Test | Standalone test scene for mission system |
| `scripts/MissionTest.gd` | Test | Script for MissionTest scene |
| `scenes/SimTest.tscn` | Test | Standalone test scene for simulation system |
| `scripts/SimTest.gd` | Test | Script for SimTest scene |

## Governance documents

| Document | Purpose |
|----------|---------|
| `FOUNDATION.md` | Frozen design charter: pillars, design laws, 80% rule |
| `PROTOTYPE_SPEC.md` | Frozen Chapter 1 spec: 5 beats, economy model, guardrails |
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

Most Chapter 1 tuning lives in `scripts/sim/SimConfig.gd`.
