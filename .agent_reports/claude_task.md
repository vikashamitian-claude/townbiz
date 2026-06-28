# Claude Code Review Task

## Task Under Review
Turn the orchestrator into the BizTown AutoDev Agent.

## Required Reading
- `AGENTS.md`
- `DEVELOPMENT_AUTOMATION.md`
- `CODING_RULES.md`
- `TASKS.md`
- `orchestrator/README.md`
- `orchestrator/orchestrator.py`
- `orchestrator/config.json`
- `.agent_reports/codex_latest.md`
- `.agent_reports/SPRINT_STATUS.md`

## Review Scope
Review only the orchestrator and automation-documentation changes.

Do not modify:
- gameplay
- Godot scenes
- Godot scripts
- economy
- architecture
- save system design
- new gameplay systems
- roadmap
- prototype specification

## Required Checks
- Confirm command hooks are disabled by default.
- Confirm dry-run does not execute external commands.
- Confirm git pull, commit, and push require explicit config enablement.
- Confirm Claude status parsing supports `PASS`, `PASS WITH MINOR FIXES`, `REJECTED`, `BLOCKER`, and `HUMAN APPROVAL REQUIRED`.
- Confirm blockers or human approval gates write/require `HUMAN_DECISIONS.md`.
- Confirm commit safety blocks credentials/build artifacts.
- Confirm scripts/scenes changes are not committed without exact Claude `PASS`.

## Suggested Validation
```powershell
python -m py_compile orchestrator/orchestrator.py
python -m json.tool orchestrator/config.json
python orchestrator/orchestrator.py --once --dry-run
python orchestrator/orchestrator.py --status
```

## Report Instructions
Write your review/fix report to `.agent_reports/claude_latest.md`.

Use exactly one status:
- `PASS`
- `PASS WITH MINOR FIXES`
- `REJECTED`
- `BLOCKER`
- `HUMAN APPROVAL REQUIRED`

Include:
- bug found
- files changed
- fix applied
- test result
- whether Codex can continue
