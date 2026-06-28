# Active Tasks

## Sprint 1A - Repo Hygiene and Project Alignment

Status: **Complete**

1. [x] Add Godot 4 `.gitignore` - covers `.godot/`, `build/`, `android/`, export artifacts, OS noise.
2. [x] Stop tracking local/editor/build artifacts - `.godot/` removed from tracking; `build/` ignored.
3. [x] Align `README.md` with active scene (`Game.tscn`), active script (`Game.gd`), autoloads, and stack.
4. [x] Mark legacy prototype files in documentation - `Main`, `MissionUI`, `MissionTest`, `SimTest` documented as legacy/test in README.

### Sprint 1A Audit Findings

- Active entry point: `scenes/Game.tscn` with `scripts/Game.gd`.
- Three autoloads: `GameState`, `Sim`, `MissionManager`.
- `SimConfig.gd` and `MissionData.gd` are active support scripts.
- Legacy files (`Main.tscn`, `Main.gd`) are not referenced by any active code.
- Test files (`MissionTest`, `SimTest`) and unused files (`MissionUI`) are not loaded at runtime.
- `export_presets.cfg` contains a Web preset only. No Android preset exists yet.
- No sensitive data found in tracked files.
- `build/` directory exists on disk with web export artifacts; correctly ignored by `.gitignore`.

## Sprint 1 - Stabilization

Status: **Blocked at Human Approval Gate**

Validation note: Godot was located at `C:\Users\pglra\godot_tmp\Godot_v4.7-stable_win64.exe`.
`Game.tscn` completed headless GUI validation with exit code 0. The console binary crashes while opening `user://logs`, so console log capture remains an environment/tooling issue.

1. [x] Run Godot headless scene/script validation. **Complete: no confirmed project runtime errors from `Game.tscn` GUI headless run.**
2. [x] Fix confirmed runtime errors. **Complete: no confirmed project runtime errors to fix.**
3. [ ] Stabilize mission progression events. *(Human approval required - gameplay; awaiting approval before work starts)*
4. [ ] Align Chapter 1 mission flow with `PROTOTYPE_SPEC.md`. *(Human approval required - gameplay)*
5. [ ] Add Android export preset and device-readiness checks. *(Human approval required - release)*
6. [ ] Add save/load system. *(Human approval required - save system)*

## Backlog

- Staff hiring
- Inventory
- Warehouse
- Factory
