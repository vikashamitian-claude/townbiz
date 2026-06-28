# BizTown AutoDev Agent

Safe local automation controller for the BizTown Codex / Claude Code workflow.

AutoDev uses repository files as the primary coordination layer. Optional external command hooks,
git pull, commit, and push can be configured later, but they are disabled by default.

## Files

- `orchestrator.py` - AutoDev orchestration loop.
- `config.json` - paths, statuses, command placeholders, and safety guards.
- `prompts/codex_pm_prompt.md` - prompt template for Codex Project Manager / Developer.
- `prompts/claude_review_prompt.md` - prompt template for Claude Code review.

## How To Run

From the repository root:

```powershell
python orchestrator/orchestrator.py --once
```

Useful options:

```powershell
python orchestrator/orchestrator.py --status
python orchestrator/orchestrator.py --once --dry-run
python orchestrator/orchestrator.py --loop
```

Dry-run mode logs what would happen without writing task files, waiting for reports, or running
external commands.

## Current Automation

AutoDev can:

1. Optionally pull latest repo changes with `git pull`.
2. Read `TASKS.md`.
3. Detect the next unfinished checkbox task.
4. Stop if the task line contains a human approval gate.
5. Write `.agent_reports/codex_task.md`.
6. Optionally run `codex_command` if configured.
7. Wait for `.agent_reports/codex_latest.md` to update.
8. Write `.agent_reports/claude_task.md`.
9. Optionally run `claude_command` if configured.
10. Wait for `.agent_reports/claude_latest.md` to update.
11. Parse Claude status.
12. Continue on `PASS` or `PASS WITH MINOR FIXES`.
13. Stage, commit, and push reviewed changes only when git automation is enabled.
14. Send rejected work back to Codex on `REJECTED`.
15. Write `HUMAN_DECISIONS.md` and stop on `BLOCKER` or `HUMAN APPROVAL REQUIRED`.
16. Update `.agent_reports/SPRINT_STATUS.md`.
17. Log activity to `.agent_logs/autodev.log`.

## Command Hooks

Command hooks are disabled by default:

```json
"git_pull_enabled": false,
"git_pull_command": ["git", "pull"],
"codex_command": null,
"claude_command": null,
"git_commit_enabled": false,
"git_push_enabled": false,
"git_push_command": ["git", "push"]
```

If a command is `null` or an empty string, the orchestrator keeps using manual file handoff.

To configure hooks later, use either a command list:

```json
"codex_command": ["example-codex-command", "--task", ".agent_reports/codex_task.md"],
"claude_command": ["example-claude-command", "--task", ".agent_reports/claude_task.md"]
```

or a quoted string:

```json
"codex_command": "example-codex-command --task .agent_reports/codex_task.md"
```

Do not put credentials or API keys in `config.json`. Use your tool's normal secure authentication
outside this repo when real CLI integration is approved.

Git pull is also disabled by default. To enable it after reviewing the local workflow:

```json
"git_pull_enabled": true,
"git_pull_command": ["git", "pull"]
```

## Manual Agent Commands

When hooks are disabled, use the generated files manually:

- Give `.agent_reports/codex_task.md` to Codex.
- Give `.agent_reports/claude_task.md` to Claude Code.

## Commit And Push

Commit and push are disabled by default:

```json
"git_commit_enabled": false,
"git_push_enabled": false
```

After Claude returns `PASS` or `PASS WITH MINOR FIXES`, the orchestrator writes suggested manual git
commands to the sprint status.

Automatic commit/push should only be enabled after the team approves real CLI integration and the
configured command has been reviewed.

If commit/push are enabled later, AutoDev stages changed files, creates a task-based commit message,
and runs `git push` only when `git_push_enabled` is true:

```json
"git_commit_enabled": true,
"git_push_enabled": true,
"git_push_command": ["git", "push"]
```

Safety rules:

- AutoDev only commits after Claude status is `PASS` or `PASS WITH MINOR FIXES`.
- Changes under `scripts/` or `scenes/` require exact Claude `PASS` before commit.
- Credential and build artifact patterns block commit.
- Files matching `excluded_commit_patterns`, such as `.agent_logs/`, are not staged.
- Human approval gates are never bypassed.

## Continuous Mode

Continuous mode runs one reviewed task cycle at a time until a stop condition is reached:

```powershell
python orchestrator/orchestrator.py --loop
```

Use dry-run first:

```powershell
python orchestrator/orchestrator.py --loop --dry-run
```

## Logs

All orchestrator activity is appended to:

```text
.agent_logs/autodev.log
```

## Stop Conditions

The orchestrator stops when:

- Claude status is `BLOCKER`.
- Claude status is `HUMAN APPROVAL REQUIRED`.
- The next task contains a human approval gate.
- No unfinished task is found.
- A report file does not update before timeout.
- Git pull, command hook, commit, or push fails.
