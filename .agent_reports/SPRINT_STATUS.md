# BizTown Sprint Status

## Current Sprint
"Living Business" Chapter 1 rebuild (`BIZTOWN_BUILD_SPEC.md`, supersedes Sprint 1
Tasks 3/4/6). See `.agent_reports/claude_latest.md` for the full stage-by-stage report.

## Current Blocker
Godot is not installed in the Claude Code build session's sandbox, and the session's
GitHub scope does not include `godotengine/godot` (no path to download a binary either).
`tests/TestRunner.gd`/`tests/BalanceSweep.gd` have not been executed by anyone yet —
engine integration and UI wiring are code-complete and statically reviewed, but Stage 2
("all tests green") and Stage 4 ("balance sweep numbers") are open until someone runs:
```
godot --headless --path . res://tests/TestRunner.tscn
godot --headless --path . res://tests/BalanceSweep.tscn
```

## Current Communication Mode
Repository files are the agent communication system.

- Codex latest report: `.agent_reports/codex_latest.md`
- Claude latest report: `.agent_reports/claude_latest.md`
- Sprint status: `.agent_reports/SPRINT_STATUS.md`
- Task source of truth: `TASKS.md`

## Latest Codex Action
Turned the orchestrator into the BizTown AutoDev Agent with disabled-by-default command hooks,
optional git pull, reviewed commit/push flow, human decision output, dry-run support, and
`.agent_logs/autodev.log` logging.

## Latest Validation
```powershell
python -m py_compile orchestrator/orchestrator.py
python -m json.tool orchestrator/config.json
python orchestrator/orchestrator.py --once --dry-run
python orchestrator/orchestrator.py --status
```

Result: passed. No Godot scripts or scenes modified.

## Awaiting
Claude Code review of the AutoDev Agent change.

## Continue Rule
- Continue automatically if Claude status is `PASS` or `PASS WITH MINOR FIXES`.
- Send back to Codex if Claude status is `REJECTED`.
- Stop for `BLOCKER`, `HUMAN APPROVAL REQUIRED`, or any Human Approval Gate.

## Sprint 1 Task State (historical — see `TASKS.md` for current state)
1. Godot headless scene/script validation: complete via GUI binary headless run. No confirmed project runtime errors from `Game.tscn`.
2. Fix confirmed runtime errors: complete. No confirmed project runtime errors to fix.
3. Stabilize mission progression events: superseded, cleared by `BIZTOWN_BUILD_SPEC.md` human approval; implemented, execution-verification blocked (see "Current Blocker" above).
4. Align Chapter 1 mission flow with `PROTOTYPE_SPEC.md`: superseded — Chapter 1 flow now follows `BIZTOWN_BUILD_SPEC.md` instead.
5. Add Android export preset and device-readiness checks: pending, Human release approval gate. Still gated.
6. Add save/load system: superseded, cleared by `BIZTOWN_BUILD_SPEC.md` human approval; implemented, execution-verification blocked (see "Current Blocker" above).
