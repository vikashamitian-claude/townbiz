# BizTown Development Automation

Autonomous development workflow for BizTown. All agents follow this document alongside CODING_RULES.md, AGENTS.md, and TASKS.md.

---

## 1. Agent Roles

| Agent | Tool | Role | Scope |
|-------|------|------|-------|
| Architect | ChatGPT | Sprint planning, task breakdown, scope control | Plans only. Never writes code. |
| Developer | Codex | Implements assigned tasks | Code changes only within assigned task. |
| Reviewer | Claude Code | Code review, bug fixes, refactoring, testing | Reviews, fixes, and validates. |
| Human | Owner | Final approval on gated items | Approves or rejects at gates. |

Rules:
- Each agent works only within its defined role.
- No agent may assume another agent's responsibilities.
- If a task is ambiguous, the agent stops and asks the Human.

---

## 2. Sprint Workflow

```
1. Architect defines sprint tasks in TASKS.md
2. Developer picks the next unfinished task (top-down order)
3. Developer executes: Inspect → Plan → Implement → Test → Report
4. Reviewer reviews the output
5. If Reviewer approves → task marked done in TASKS.md
6. If Reviewer rejects → Developer fixes and resubmits
7. Human approves at gates (see Section 7)
8. Repeat until sprint is complete
```

One task at a time. No parallel task execution. No skipping ahead.

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

Reviewer (Claude Code) checks every task output before it merges.

Checklist:
1. Does the change match the assigned task exactly? No more, no less.
2. Does it follow CODING_RULES.md?
3. Does it break any existing functionality?
4. Are files that should not be modified left untouched?
5. Is the commit message correct?
6. Does the task report include: files inspected, files changed, what was implemented, how to test, known limitations?

Reject if any check fails. Provide specific reason.

---

## 6. Testing Rules

Every task must be validated before review.

| Test Type | When | How |
|-----------|------|-----|
| File existence | Always | Verify referenced files exist in the repo |
| Syntax check | Code changes | Run Godot headless: `godot --headless --check-only` |
| Scene load | Scene changes | Run Godot headless: `godot --headless --path . -s scripts/Game.gd --quit` |
| Manual play | Gameplay changes | Human runs in Godot editor and confirms behavior |

Rules:
- No task is marked done without at least a syntax check.
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
6. Changes to PROTOTYPE_SPEC.md or ROADMAP.md
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
10. Never create documentation that contradicts PROTOTYPE_SPEC.md or ROADMAP.md.
11. Never add dependencies, plugins, or addons without Human approval.
12. Never commit `.godot/` directory contents, build artifacts, or credentials.

---

## 10. Sprint 1 Execution Order

From TASKS.md. Execute strictly in this order.

### Sprint 1A — Repo Hygiene

| # | Task | Agent | Gate |
|---|------|-------|------|
| 1 | Add Godot 4 `.gitignore` | Developer | None |
| 2 | Stop tracking local/editor/build artifacts | Developer | None |
| 3 | Align `README.md` with active scene and script | Developer | None |
| 4 | Mark legacy prototype files in documentation only | Developer | None |

### Sprint 1 — Stabilization

| # | Task | Agent | Gate |
|---|------|-------|------|
| 1 | Run Godot headless scene/script validation | Reviewer | None |
| 2 | Fix confirmed runtime errors | Developer | None |
| 3 | Stabilize mission progression events | Developer | Human (gameplay) |
| 4 | Align Chapter 1 mission flow with PROTOTYPE_SPEC.md | Developer | Human (gameplay) |
| 5 | Add Android export preset and device-readiness checks | Developer | Human (release) |
| 6 | Add save/load system | Developer | Human (save system) |

No task starts until the previous task is merged. No exceptions.
