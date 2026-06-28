#!/usr/bin/env python3
"""BizTown AutoDev Agent.

This safe local controller uses repository files as the coordination layer. Optional
external command hooks can be configured later, but they are disabled by default.
"""

from __future__ import annotations

import argparse
import fnmatch
import json
import os
import re
import shlex
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CONFIG = ROOT / "orchestrator" / "config.json"


@dataclass
class Task:
    line_number: int
    text: str
    human_gate: bool


def load_config(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as file:
        return json.load(file)


def repo_path(raw_path: str) -> Path:
    return ROOT / raw_path


def read_text(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8")


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def append_text(path: Path, text: str) -> None:
    if path.parent.exists() and path.parent.is_file():
        legacy_path = path.parent.with_name(path.parent.name + "_legacy")
        if legacy_path.exists():
            legacy_path = path.parent.with_name(path.parent.name + f"_legacy_{int(time.time())}")
        path.parent.replace(legacy_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as file:
        file.write(text)


def log(config: dict[str, Any], message: str) -> None:
    paths = config["paths"]
    log_path = repo_path(paths.get("autodev_log", paths.get("orchestrator_log", ".agent_logs/autodev.log")))
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    append_text(log_path, f"[{timestamp}] {message}\n")


def modification_time(path: Path) -> float:
    return path.stat().st_mtime if path.exists() else 0.0


def find_next_unfinished_task(tasks_text: str, gate_markers: list[str]) -> Task | None:
    checkbox = re.compile(r"^\s*\d+\.\s+\[\s\]\s+(.+?)\s*$")
    markers = [marker.lower() for marker in gate_markers]
    for index, line in enumerate(tasks_text.splitlines(), start=1):
        match = checkbox.match(line)
        if not match:
            continue
        task_text = match.group(1)
        lower_text = task_text.lower()
        human_gate = any(marker in lower_text for marker in markers)
        return Task(line_number=index, text=task_text, human_gate=human_gate)
    return None


def parse_claude_status(report_text: str) -> str:
    patterns = [
        re.compile(r"^\s*(?:\*\*)?Status(?:\*\*)?\s*:\s*(.+?)\s*$", re.IGNORECASE | re.MULTILINE),
        re.compile(r"^\s*(?:\*\*)?Review status(?:\*\*)?\s*:\s*(.+?)\s*$", re.IGNORECASE | re.MULTILINE),
    ]
    for pattern in patterns:
        match = pattern.search(report_text)
        if match:
            status = match.group(1).strip()
            status = re.sub(r"[*`]", "", status)
            status = status.splitlines()[0].strip()
            return status.upper()
    return "BLOCKER"


def wait_for_update(path: Path, previous_mtime: float, poll_seconds: int, timeout_seconds: int) -> bool:
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        if path.exists() and modification_time(path) > previous_mtime:
            return True
        time.sleep(poll_seconds)
    return False


def normalize_command(command: Any) -> list[str] | None:
    if command is None:
        return None
    if isinstance(command, str):
        command = command.strip()
        if not command:
            return None
        return shlex.split(command, posix=(os.name != "nt"))
    if isinstance(command, list):
        parts = [str(part) for part in command if str(part).strip()]
        return parts or None
    raise TypeError("Command hook must be null, a string, or a list of strings.")


def run_command_hook(config: dict[str, Any], hook_name: str, dry_run: bool) -> bool:
    command = normalize_command(config.get(hook_name))
    if not command:
        log(config, f"{hook_name}: disabled; using manual file handoff.")
        return True
    if dry_run:
        log(config, f"{hook_name}: dry-run would execute: {command}")
        return True

    log(config, f"{hook_name}: executing: {command}")
    try:
        result = subprocess.run(
            command,
            cwd=ROOT,
            capture_output=True,
            text=True,
            timeout=int(config.get("command_timeout_seconds", 3600)),
            check=False,
        )
    except FileNotFoundError as exc:
        log(config, f"{hook_name}: executable not found: {exc}")
        return False
    except subprocess.TimeoutExpired as exc:
        log(config, f"{hook_name}: timed out: {exc}")
        return False

    if result.stdout:
        log(config, f"{hook_name}: stdout:\n{result.stdout.rstrip()}")
    if result.stderr:
        log(config, f"{hook_name}: stderr:\n{result.stderr.rstrip()}")
    log(config, f"{hook_name}: exit code {result.returncode}")
    return result.returncode == 0


def run_command(config: dict[str, Any], label: str, command: list[str], dry_run: bool) -> bool:
    if dry_run:
        log(config, f"{label}: dry-run would execute: {command}")
        return True
    log(config, f"{label}: executing: {command}")
    try:
        result = subprocess.run(
            command,
            cwd=ROOT,
            capture_output=True,
            text=True,
            timeout=int(config.get("command_timeout_seconds", 3600)),
            check=False,
        )
    except FileNotFoundError as exc:
        log(config, f"{label}: executable not found: {exc}")
        return False
    except subprocess.TimeoutExpired as exc:
        log(config, f"{label}: timed out: {exc}")
        return False

    if result.stdout:
        log(config, f"{label}: stdout:\n{result.stdout.rstrip()}")
    if result.stderr:
        log(config, f"{label}: stderr:\n{result.stderr.rstrip()}")
    log(config, f"{label}: exit code {result.returncode}")
    return result.returncode == 0


def maybe_git_pull(config: dict[str, Any], dry_run: bool) -> bool:
    if not bool(config.get("git_pull_enabled", False)):
        log(config, "git pull disabled.")
        return True
    command = normalize_command(config.get("git_pull_command", ["git", "pull"]))
    if not command:
        log(config, "git_pull_enabled is true but git_pull_command is empty.")
        return False
    return run_command(config, "git_pull", command, dry_run)


def git_changed_files(config: dict[str, Any]) -> list[str]:
    result = subprocess.run(
        ["git", "status", "--porcelain"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        log(config, f"git status failed: {result.stderr.rstrip()}")
        return []

    files: list[str] = []
    for line in result.stdout.splitlines():
        if not line:
            continue
        path = line[3:].strip()
        if " -> " in path:
            path = path.split(" -> ", 1)[1].strip()
        files.append(path.strip('"'))
    return files


def matches_any_pattern(path: str, patterns: list[str]) -> bool:
    normalized = path.replace("\\", "/")
    for pattern in patterns:
        clean_pattern = pattern.replace("\\", "/")
        if clean_pattern.endswith("/") and normalized.startswith(clean_pattern):
            return True
        if fnmatch.fnmatch(normalized, clean_pattern):
            return True
    return False


def has_protected_gameplay_changes(config: dict[str, Any], files: list[str]) -> bool:
    protected_paths = config.get("protected_change_paths", ["scripts/", "scenes/"])
    return any(matches_any_pattern(path, protected_paths) for path in files)


def has_forbidden_commit_files(config: dict[str, Any], files: list[str]) -> bool:
    forbidden = config.get(
        "forbidden_commit_patterns",
        [".godot/", "build/", "exports/", "*.apk", "*.aab", "*.pck", ".env", ".env.*", "*.key", "*.pem"],
    )
    return any(matches_any_pattern(path, forbidden) for path in files)


def filter_excluded_commit_files(config: dict[str, Any], files: list[str]) -> list[str]:
    excluded = config.get("excluded_commit_patterns", [".agent_logs/"])
    return [path for path in files if not matches_any_pattern(path, excluded)]


def task_commit_message(config: dict[str, Any], task: Task) -> str:
    prefix = str(config.get("commit_message_prefix", "[AutoDev]"))
    summary = re.sub(r"\s+", " ", task.text).strip()
    summary = re.sub(r"[^A-Za-z0-9 ._:/#-]", "", summary)
    return f"{prefix} {summary[:72]}".strip()


def commit_and_push_if_enabled(config: dict[str, Any], task: Task, status: str, dry_run: bool) -> bool:
    if not bool(config.get("git_commit_enabled", False)):
        log(config, "git commit disabled.")
        return True

    all_files = git_changed_files(config)
    if not all_files:
        log(config, "No changed files to commit.")
        return True

    if has_forbidden_commit_files(config, all_files):
        log(config, f"Commit blocked: forbidden credential/build artifact pattern in changed files: {all_files}")
        return False

    files = filter_excluded_commit_files(config, all_files)
    if not files:
        log(config, "Only excluded files changed; nothing to commit.")
        return True

    if has_protected_gameplay_changes(config, files) and status != "PASS":
        log(config, "Commit blocked: scripts/scenes changes require exact Claude PASS.")
        return False

    message = task_commit_message(config, task)
    add_command = ["git", "add", "--", *files]
    commit_command = ["git", "commit", "-m", message]

    if dry_run:
        log(config, f"dry-run would stage files: {files}")
        log(config, f"dry-run would commit with message: {message}")
    else:
        if not run_command(config, "git_add", add_command, dry_run=False):
            return False
        if not run_command(config, "git_commit", commit_command, dry_run=False):
            return False

    if bool(config.get("git_push_enabled", False)):
        push_command = normalize_command(config.get("git_push_command", ["git", "push"]))
        if not push_command:
            log(config, "git_push_enabled is true but git_push_command is empty.")
            return False
        return run_command(config, "git_push", push_command, dry_run)

    log(config, "git push disabled.")
    return True


def render_codex_task(task: Task) -> str:
    return f"""# Codex Task

## Task Source
`TASKS.md` line {task.line_number}

## Assigned Task
{task.text}

## Required Reading
- `AGENTS.md`
- `DEVELOPMENT_AUTOMATION.md`
- `CODING_RULES.md`
- `TASKS.md`
- `.agent_reports/SPRINT_STATUS.md`

## Instructions
- Execute only this task.
- Do not modify gameplay, scripts, scenes, economy, architecture, save system design, new gameplay systems, roadmap, or prototype specification unless this task explicitly allows it and has human approval.
- Write the task report to `.agent_reports/codex_latest.md`.
- Update `.agent_reports/SPRINT_STATUS.md`.
- Update `TASKS.md` only if task state changes.
- After implementation, instruct Claude Code to review.
"""


def render_claude_task(task: Task) -> str:
    return f"""# Claude Code Review Task

## Task Under Review
{task.text}

## Required Reading
- `AGENTS.md`
- `DEVELOPMENT_AUTOMATION.md`
- `CODING_RULES.md`
- `TASKS.md`
- `.agent_reports/codex_latest.md`
- `.agent_reports/SPRINT_STATUS.md`

## Instructions
- Review Codex output for the assigned task only.
- Fix only allowed in-scope bugs.
- Do not independently change economy, architecture, save system design, new gameplay systems, roadmap, or prototype specification.
- Write your report to `.agent_reports/claude_latest.md`.

## Required Status
Use exactly one:
- `PASS`
- `PASS WITH MINOR FIXES`
- `REJECTED`
- `BLOCKER`
- `HUMAN APPROVAL REQUIRED`
"""


def update_sprint_status(config: dict[str, Any], message: str) -> None:
    path = repo_path(config["paths"]["sprint_status"])
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    text = f"""# BizTown Sprint Status

## Last Orchestrator Update
{timestamp}

## Status
{message}

## Communication Files
- Codex task: `{config["paths"]["codex_task"]}`
- Codex latest report: `{config["paths"]["codex_latest"]}`
- Claude task: `{config["paths"]["claude_task"]}`
- Claude latest report: `{config["paths"]["claude_latest"]}`

## Continue Rule
- Continue automatically on `PASS` or `PASS WITH MINOR FIXES`.
- Send back to Codex on `REJECTED`.
- Stop on `BLOCKER`, `HUMAN APPROVAL REQUIRED`, or task-level human approval gates.
"""
    write_text(path, text)
    log(config, f"SPRINT_STATUS updated: {message}")


def write_human_decisions(config: dict[str, Any], reason: str, task: Task | None, dry_run: bool) -> None:
    path = repo_path(config["paths"].get("human_decisions", "HUMAN_DECISIONS.md"))
    task_text = task.text if task else "No active task"
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    text = f"""# Human Decisions Required

## Created
{timestamp}

## Reason
{reason}

## Task
{task_text}

## Required Human Action
Review the gate reason and approve, reject, or revise the task before AutoDev continues.
"""
    if dry_run:
        log(config, f"dry-run would write {path.relative_to(ROOT)} for human decision: {reason}")
        return
    write_text(path, text)
    log(config, f"Human decision file written: {path.relative_to(ROOT)}")


def write_manual_git_status(config: dict[str, Any], status: str) -> None:
    if status not in config["statuses"]["continue"]:
        return
    path = repo_path(config["paths"]["sprint_status"])
    current = read_text(path)
    commands = config["manual_commands"]
    current += f"""
## Reviewed Task Success
Claude status: `{status}`

Automatic commit/push is disabled unless `git_commit_enabled` and `git_push_enabled` are explicitly enabled.

Suggested manual commands after verifying the diff:

```powershell
{commands["commit"]}
{commands["push"]}
```
"""
    write_text(path, current)
    log(config, f"Manual git status written for Claude status {status}.")


def run_once(config: dict[str, Any], dry_run: bool = False) -> int:
    paths = config["paths"]
    log(config, f"run_once started; dry_run={dry_run}")
    if not maybe_git_pull(config, dry_run):
        if not dry_run:
            update_sprint_status(config, "BLOCKER: git pull failed.")
        return 2

    tasks_path = repo_path(paths["tasks"])
    tasks_text = read_text(tasks_path)
    if not tasks_text:
        if not dry_run:
            update_sprint_status(config, "BLOCKER: TASKS.md not found or empty.")
        log(config, "BLOCKER: TASKS.md not found or empty.")
        return 2

    task = find_next_unfinished_task(tasks_text, config["human_gate_markers"])
    if task is None:
        if not dry_run:
            update_sprint_status(config, "No unfinished task found.")
        log(config, "No unfinished task found.")
        return 0

    if task.human_gate:
        if not dry_run:
            update_sprint_status(config, f"HUMAN APPROVAL REQUIRED before task: {task.text}")
            write_human_decisions(config, "Task contains a human approval gate.", task, dry_run=False)
        log(config, f"HUMAN APPROVAL REQUIRED before task: {task.text}")
        if dry_run:
            write_human_decisions(config, "Task contains a human approval gate.", task, dry_run=True)
            print(f"DRY RUN: would stop for human approval gate before task: {task.text}")
            return 0
        return 3

    codex_latest = repo_path(paths["codex_latest"])
    claude_latest = repo_path(paths["claude_latest"])
    codex_previous = modification_time(codex_latest)
    claude_previous = modification_time(claude_latest)

    if dry_run:
        log(config, f"dry-run would write {paths['codex_task']} for task: {task.text}")
        print(f"DRY RUN: would write {paths['codex_task']} for task: {task.text}")
    else:
        write_text(repo_path(paths["codex_task"]), render_codex_task(task))
        update_sprint_status(config, f"Codex task written. Manual action required: {config['manual_commands']['codex']}")

    if not run_command_hook(config, "codex_command", dry_run):
        if not dry_run:
            update_sprint_status(config, "BLOCKER: codex_command failed.")
        return 2
    if dry_run:
        log(config, "dry-run complete before Codex wait.")
        return 0
    if not wait_for_update(codex_latest, codex_previous, config["poll_seconds"], config["timeout_seconds"]):
        update_sprint_status(config, "BLOCKER: Timed out waiting for Codex latest report.")
        return 2

    write_text(repo_path(paths["claude_task"]), render_claude_task(task))
    update_sprint_status(config, f"Claude review task written. Manual action required: {config['manual_commands']['claude']}")

    if not run_command_hook(config, "claude_command", dry_run):
        update_sprint_status(config, "BLOCKER: claude_command failed.")
        return 2
    if not wait_for_update(claude_latest, claude_previous, config["poll_seconds"], config["timeout_seconds"]):
        update_sprint_status(config, "BLOCKER: Timed out waiting for Claude latest report.")
        return 2

    status = parse_claude_status(read_text(claude_latest))
    if status in config["statuses"]["continue"]:
        update_sprint_status(config, f"Claude status `{status}`. Continue to next task.")
        write_manual_git_status(config, status)
        if not commit_and_push_if_enabled(config, task, status, dry_run):
            update_sprint_status(config, "BLOCKER: reviewed git commit/push safety check failed.")
            return 2
        return 0
    if status in config["statuses"]["rejected"]:
        write_text(repo_path(paths["codex_task"]), render_codex_task(task) + "\n## Review Result\nClaude rejected this task. Read `.agent_reports/claude_latest.md` and fix only the assigned task.\n")
        update_sprint_status(config, "REJECTED: Sent task back to Codex.")
        return 1
    update_sprint_status(config, f"{status}: stopping orchestration.")
    write_human_decisions(config, f"Claude status requires stop: {status}", task, dry_run=False)
    return 3


def print_status(config: dict[str, Any]) -> None:
    tasks_text = read_text(repo_path(config["paths"]["tasks"]))
    task = find_next_unfinished_task(tasks_text, config["human_gate_markers"])
    if task is None:
        print("No unfinished task found.")
        return
    gate = "yes" if task.human_gate else "no"
    print(f"Next task line {task.line_number}: {task.text}")
    print(f"Human gate: {gate}")
    print(f"codex_command configured: {'yes' if normalize_command(config.get('codex_command')) else 'no'}")
    print(f"claude_command configured: {'yes' if normalize_command(config.get('claude_command')) else 'no'}")
    print(f"git_pull_enabled: {'yes' if bool(config.get('git_pull_enabled', False)) else 'no'}")
    print(f"git_commit_enabled: {'yes' if bool(config.get('git_commit_enabled', False)) else 'no'}")
    print(f"git_push_enabled: {'yes' if bool(config.get('git_push_enabled', False)) else 'no'}")


def main() -> int:
    parser = argparse.ArgumentParser(description="BizTown file-based agent orchestrator")
    parser.add_argument("--config", default=str(DEFAULT_CONFIG), help="Path to config.json")
    parser.add_argument("--once", action="store_true", help="Run one orchestration cycle")
    parser.add_argument("--loop", action="store_true", help="Run cycles until stopped")
    parser.add_argument("--status", action="store_true", help="Print detected next task")
    parser.add_argument("--dry-run", action="store_true", help="Show/log actions without writing task files, waiting, or running commands")
    args = parser.parse_args()

    config = load_config(Path(args.config))

    if args.status:
        print_status(config)
        return 0
    if args.loop:
        while True:
            code = run_once(config, dry_run=args.dry_run)
            if code != 0:
                return code
    if args.once:
        return run_once(config, dry_run=args.dry_run)

    parser.print_help()
    return 0


if __name__ == "__main__":
    sys.exit(main())
