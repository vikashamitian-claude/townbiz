---
name: stage-report
description: Write the required BizTown work report to .agent_reports/claude_latest.md and refresh SPRINT_STATUS.md. Use after completing a stage or sprint of work, or before handing off.
---

## Repo state

!`git log --oneline -8`

!`git status --short`

## Instructions

Replace the content of `.agent_reports/claude_latest.md` with the latest report (current state, not a running log):

- STAGE: n — name
- STATUS: PASS | PASS WITH MINOR FIXES | BLOCKER | HUMAN APPROVAL REQUIRED
- FILES CHANGED: real paths (verify each exists before listing it)
- EDITS TO EXISTING/DROPPED CODE: every one, with reason (syntax fix vs bug fix vs approved change)
- TEST OUTPUT: verbatim output + exit code, or the exact reason none exists. Never "should pass" — a false PASS is worse than an honest FAIL.
- OPEN QUESTIONS: or "none"

Then update `.agent_reports/SPRINT_STATUS.md` (current sprint, current blocker, next action) and tick/adjust `TASKS.md`. Commit together with the work and push to the current working branch.
