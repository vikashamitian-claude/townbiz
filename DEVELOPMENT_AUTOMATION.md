# BizTown Development Automation

Autonomous development workflow for BizTown. All agents follow this document alongside
`CODING_RULES.md`, `AGENTS.md`, and `TASKS.md`.

---

## 1. Agent Roles

| Agent | Tool | Role | Scope |
|-------|------|------|-------|
| Project Manager | Codex | Maintains roadmap, chooses next task, updates `TASKS.md`, rejects scope drift | Process control and task assignment. |
| Architect | ChatGPT | Sprint planning, task breakdown, scope control | Product and architecture direction. |
| Developer | Codex | Implements assigned tasks | Code changes only within assigned task. |
| Reviewer / Tester | Claude Code | Code review, bug fixing, refactoring, testing | Reviews, tests, fixes in-scope bugs, and reports back. |
| Human | Owner | Final approval on gated items | Approves or rejects at gates. |

Rules:
- Codex has full permission to act as Project Manager and Developer for normal sprint tasks.
- Codex may act as Project Manager and Developer, but planning/reporting must stay separate from implementation.
- Claude Code may fix confirmed bugs found during review/testing if the fix is inside the assigned task scope.
- No agent may assume responsibilities outside this workflow.
- If a task is ambiguous, the agent stops and asks the Human.

---

## 2. Sprint Workflow

```
1. Project Manager reads governance files and TASKS.md
2. Project Manager chooses the next unfinished task in top-down order
3. Project Manager assigns the task to Developer
4. Developer executes: Inspect -> Plan -> Implement -> Test -> Report
5. Developer writes the task report to .agent_reports/codex_latest.md
6. Reviewer / Tester reviews and tests the output
7. Reviewer / Tester writes the review/fix report to .agent_reports/claude_latest.md
8. Project Manager reads .agent_reports/claude_latest.md before continuing
9. If Claude status is PASS or PASS WITH MINOR FIXES, Project Manager continues automatically
10. If Claude status is BLOCKER or a Human Approval Gate is hit, Project Manager stops
11. Project Manager updates .agent_reports/SPRINT_STATUS.md and TASKS.md
12. Repeat until sprint is complete
```

Repository files are the agent communication system. Do not depend on the Human manually copying
agent conversations between tools.

One task at a time. No parallel task execution. No skipping ahead.

---

## 2A. Repository Communication Files

- Codex writes every task report to `.agent_reports/codex_latest.md`.
- Claude Code writes every review/fix report to `.agent_reports/claude_latest.md`.
- Sprint progress is tracked in `.agent_reports/SPRINT_STATUS.md`.
- Codex must read `.agent_reports/claude_latest.md` before continuing after implementation.
- Codex continues automatically only when Claude status is `PASS` or `PASS WITH MINOR FIXES`.
- Codex stops for `BLOCKER` or any Human Approval Gate.
- `TASKS.md` remains the source of truth for sprint task state.

The optional local AutoDev controller lives in `orchestrator/`. It may write task files,
run configured Codex/Claude command hooks, parse Claude results, and commit/push reviewed
work only when those features are explicitly enabled in `orchestrator/config.json`.
All command hooks, git pull, git commit, and git push are disabled by default.
AutoDev must write `HUMAN_DECISIONS.md` and stop when a blocker or human approval gate is hit.

---

## 3. Branching Rules

| Branch | Purpose | Who Creates |
|--------|---------|-------------|
| `main` | Stable, human-approved code only | Protected |
| `sprint-{N}/{task-slug}` | One branch per task | Developer |

Rules:
- Never commit directly to `main`.
- Every task gets its own branch: `sprint-1a/add-gitignore`, `sprint-1/fix-runtime-errors`, etc.
- Branch from `main` at the start of each task.
- Delete the branch after merge to `main`.
- No long-lived feature branches.

---

## 4. Commit Rules

- One logical change per commit.
- Commit message format: `[Sprint X] Short description of what changed`
- Examples:
  - `[Sprint 1A] Add Godot 4 .gitignore`
  - `[Sprint 1] Fix null reference in Game.gd line 42`
- No empty commits.
- No commits with unrelated changes bundled together.
- Every commit must leave the project in a runnable state.
- Never commit `.godot/`, build artifacts, or editor-local files.

---

## 5. Review Rules

Reviewer / Tester (Claude Code) checks every task output before it merges.

Checklist:
1. Does the change match the assigned task exactly? No more, no less.
2. Does it follow `CODING_RULES.md`?
3. Does it break any existing functionality?
4. Are files that should not be modified left untouched?
5. Is the commit message correct?
6. Does the task report include: files inspected, files changed, what was implemented, how to test, known limitations?

Rules:
- Reject if any check fails. Provide specific reason.
- Reviewer may directly fix confirmed bugs found during review/testing when the fix is inside the assigned task scope.
- Claude Code has full permission to review, test, debug, and fix bugs found during review.
- Claude Code may directly fix syntax errors, runtime errors, broken references, minor UI bugs, small logic bugs, and test failures.
- Claude Code must not independently change game economy, architecture, save system design, new gameplay systems, roadmap, or prototype specification.
- Reviewer must report fixes back to Project Manager with bug found, files changed, fix applied, test result, and whether Codex can continue.
- Reviewer report status must be exactly one of: `PASS`, `PASS WITH MINOR FIXES`, or `BLOCKER`.
- Codex must read Claude Code's review/fix report before continuing to the next task.
- Bugs outside task scope become new tasks. Do not fix them opportunistically.

---

## 6. Testing Rules

Every task must be validated before review.

| Test Type | When | How |
|-----------|------|-----|
| File existence | Always | Verify referenced files exist in the repo |
| Syntax check | Code changes | Run Godot headless validation |
| Scene load | Scene changes | Run Godot headless against the affected scene |
| Manual play | Gameplay changes | Human runs in Godot editor and confirms behavior |

Rules:
- No task is marked done without validation or a documented blocker.
- Never claim a test passed without actually running it.
- If Godot is not available in the environment, state that explicitly. Do not fake results.

---

## 7. Human Approval Gates

The following changes require Human approval before merging to `main`:

1. Architecture changes (new systems, new autoloads, scene tree restructuring)
2. Save system changes
3. Economy changes (pricing, costs, demand curves, cash values)
4. New gameplay systems or mechanics
5. Release builds or export presets
6. Changes to `PROTOTYPE_SPEC.md` or `ROADMAP.md`
7. Deletion of any existing script or scene file

Process:
- Agent flags the gate in its task report.
- Work pauses on that task until Human responds.
- Human approval is recorded in the task report or commit message.

---

## 8. Anti-Hallucination Rules

1. Before editing a file, read it first. Never assume file contents.
2. Before referencing a file, confirm it exists with a file listing.
3. Never invent function names, signal names, node paths, or APIs.
4. Never claim Godot supports a feature without verifying it.
5. Never fabricate test results. If you cannot run a test, say so.
6. If a task references a file or system that does not exist, stop and report.
7. Use exact file paths from the repo. Never guess paths.
8. Quote actual code when reporting changes. Never paraphrase from memory.

---

## 9. What Agents Must Never Do

1. Never modify gameplay logic without an assigned task.
2. Never modify existing scripts unless the task explicitly requires it.
3. Never modify existing scenes unless the task explicitly requires it.
4. Never add features outside the assigned task scope.
5. Never change the technology stack (Godot 4.x, GDScript, 2D Isometric).
6. Never redesign existing systems without Human approval.
7. Never delete files without Human approval.
8. Never push directly to `main`.
9. Never skip the Inspect step before making changes.
10. Never create documentation that contradicts `PROTOTYPE_SPEC.md` or `ROADMAP.md`.
11. Never add dependencies, plugins, or addons without Human approval.
12. Never commit `.godot/` directory contents, build artifacts, or credentials.

---

## 10. Sprint 1 Execution Order

From `TASKS.md`. Execute strictly in this order.

### Sprint 1A - Repo Hygiene

| # | Task | Agent | Gate |
|---|------|-------|------|
| 1 | Add Godot 4 `.gitignore` | Developer | None |
| 2 | Stop tracking local/editor/build artifacts | Developer | None |
| 3 | Align `README.md` with active scene and script | Developer | None |
| 4 | Mark legacy prototype files in documentation only | Developer | None |

### Sprint 1 - Stabilization

| # | Task | Agent | Gate |
|---|------|-------|------|
| 1 | Run Godot headless scene/script validation | Reviewer / Tester | None |
| 2 | Fix confirmed runtime errors | Developer or Reviewer / Tester | None |
| 3 | Stabilize mission progression events | Developer | Human (gameplay) |
| 4 | Align Chapter 1 mission flow with `PROTOTYPE_SPEC.md` | Developer | Human (gameplay) |
| 5 | Add Android export preset and device-readiness checks | Developer | Human (release) |
| 6 | Add save/load system | Developer | Human (save system) |

No task starts until the previous task is merged. No exceptions.
