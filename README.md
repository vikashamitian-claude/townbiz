# BizTown: Build Your Empire — Prototype

A Stage 1 prototype of the BizTown business tycoon game, built in **Godot 4.x / GDScript**.

The whole point of this prototype: **prove the core loop is fun.** Earn money → upgrade
your business through four stages:

```
Small Shop  →  Big Shop  →  Warehouse  →  Factory
```

## What's in the prototype

- One playable screen, portrait (Android-first, 720×1280 base).
- 2D isometric cartoon buildings (placeholder vector art, drawn in code).
- Core loop: tap the shop to **SELL**, or let walk-in customers buy automatically.
- **UPGRADE** button advances you to the next, bigger, higher-earning business stage.
- Live HUD: cash, business name, net worth, and a progress bar to the next upgrade.
- Juice: floating `+₹` popups on every sale, an upgrade flash, a factory chimney puff.

## How to run it

1. Install **Godot 4.x** (standard build, not Mono/C#) from <https://godotengine.org/download>.
2. Open Godot → **Import** → select this `biztown` folder (the one with `project.godot`).
3. Press **F5** (Play). The game runs in a portrait window — click the shop to sell.

> Godot is not installed on this machine, so the project hasn't been run here yet.
> It's authored to the Godot 4.3 project format and should import cleanly.

## Try it on Android

1. In Godot: **Editor → Manage Export Templates → Download** (matches your Godot version).
2. **Project → Export → Add… → Android.** Install the Android SDK / set up the
   debug keystore when Godot prompts (one-time).
3. Plug in a phone with USB debugging on and click **Run on device**, or **Export Project**
   to build an APK.

## Files

| File | Purpose |
|------|---------|
| `project.godot` | Engine config: portrait, mobile (GL Compatibility) renderer |
| `scenes/Main.tscn` | The single game scene (just hosts the script) |
| `scripts/Main.gd` | All game logic, isometric rendering, and UI |
| `icon.svg` | App icon |

## Tuning knobs (top of `scripts/Main.gd`)

- `STAGES` — name, income per sale, upgrade cost, and size/colour of each building.
- `CUSTOMER_INTERVAL` — how often walk-in customers arrive.
- `CUSTOMER_SPEED` — how fast they walk to the door.
- `cash` (starting money), `BUILDING_CENTER` (where the shop sits).

## Next steps once it feels fun

Stock/inventory, daily goals, staff, and the 20-level run from the design doc — but only
after the first 15 minutes are genuinely addictive.
