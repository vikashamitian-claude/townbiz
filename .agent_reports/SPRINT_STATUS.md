# BizTown Sprint Status

## Current Sprint
Sprint 1 - Stabilization

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

## Sprint 1 Task State
1. Godot headless scene/script validation: complete via GUI binary headless run. No confirmed project runtime errors from `Game.tscn`.
2. Fix confirmed runtime errors: complete. No confirmed project runtime errors to fix.
3. Stabilize mission progression events: blocked at Human gameplay approval gate.
4. Align Chapter 1 mission flow with `PROTOTYPE_SPEC.md`: pending, Human gameplay approval gate.
5. Add Android export preset and device-readiness checks: pending, Human release approval gate.
6. Add save/load system: pending, Human save-system approval gate.
