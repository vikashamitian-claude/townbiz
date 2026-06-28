# Claude Code Review Prompt

Read these files first:

- `AGENTS.md`
- `DEVELOPMENT_AUTOMATION.md`
- `CODING_RULES.md`
- `TASKS.md`
- `.agent_reports/codex_latest.md`
- `.agent_reports/SPRINT_STATUS.md`

Then review the task written in:

- `.agent_reports/claude_task.md`

You may directly fix:

- syntax errors
- runtime errors
- broken references
- minor UI bugs
- small logic bugs
- test failures

You must not independently change:

- game economy
- architecture
- save system design
- new gameplay systems
- roadmap
- prototype specification

Write your report to `.agent_reports/claude_latest.md`.

Required report fields:

- `Status:` one of `PASS`, `PASS WITH MINOR FIXES`, `REJECTED`, `BLOCKER`, `HUMAN APPROVAL REQUIRED`
- `Bug Found:`
- `Files Changed:`
- `Fix Applied:`
- `Test Result:`
- `Can Codex Continue:`
