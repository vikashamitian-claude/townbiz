# BizTown: Build Your Empire - Prototype

A Stage 1 prototype of the BizTown business tycoon game, built in **Godot 4.x / GDScript** with an
**Android-first** target.

The current active prototype is Chapter 1, "Save My First Shop": set a soap price, serve customers,
manage stock, hire Ravi, survive month-end, and decide whether to expand.

## What's in the prototype

- One playable portrait screen using a 720x1280 base viewport.
- Active scene: `scenes/Game.tscn`.
- Active script: `scripts/Game.gd`.
- Autoloaded simulation state and rules in `scripts/sim/`.
- Autoloaded mission flow and Chapter 1 mission data in `scripts/mission/`.
- Live HUD for day, cash, reputation, stock, price, mission state, and shop diary.
- Simple built-in placeholder visuals for the shop, customers, Ravi, and completion overlay.

## How to run it

1. Install **Godot 4.x** (standard build, not Mono/C#) from <https://godotengine.org/download>.
2. Open Godot, choose **Import**, and select this `biztown` folder, the one with `project.godot`.
3. Press **F5**. Godot runs `scenes/Game.tscn`.

The project is configured for Godot 4.x, GDScript, portrait layout, and the GL Compatibility renderer.

## Try it on Android

1. In Godot, use **Editor -> Manage Export Templates -> Download** for your Godot version.
2. Use **Project -> Export -> Add... -> Android**. Install the Android SDK and set up the
   debug keystore when Godot prompts (one-time).
3. Plug in a phone with USB debugging on and click **Run on device**, or **Export Project**
   to build an APK.

Note: the current repo hygiene pass does not add an Android export preset.

## Files

| File | Purpose |
|------|---------|
| `project.godot` | Engine config: portrait, mobile (GL Compatibility) renderer |
| `scenes/Game.tscn` | Active game scene |
| `scripts/Game.gd` | Active gameplay presentation and UI script |
| `scripts/sim/` | Simulation state, rules, and tunable numbers |
| `scripts/mission/` | Mission manager and Chapter 1 mission data |
| `icon.svg` | App icon |

## Legacy files

`scenes/Main.tscn` and `scripts/Main.gd` are legacy Stage 1 prototype files. They are kept for now
but are not the active game entry point.

## Tuning knobs

Most Chapter 1 tuning lives in `scripts/sim/SimConfig.gd`.
