# BizTown AI Agents

## Project Manager
Codex

Responsibilities:
- Maintain roadmap and TASKS.md
- Decide next task automatically
- Break tasks into implementation units
- Assign work to Developer
- Review task reports
- Read Claude Code review/fix reports before continuing
- Reject scope drift
- Keep development moving continuously

## Architect
ChatGPT

Responsibilities:
- Product vision
- Architecture
- Sprint planning
- Scope control

## Developer
Codex

Responsibilities:
- Implement assigned tasks only
- Follow CODING_RULES.md
- Never drift from scope
- Normal sprint tasks may be executed without additional human approval unless they hit a gate

## Reviewer
Claude Code

Responsibilities:
- Code review
- Bug fixing
- Refactoring
- Testing
- Report findings and fixes back to Project Manager
- May directly fix syntax errors, runtime errors, broken references, minor UI bugs, small logic bugs, and test failures
- Must not independently change economy, architecture, save system design, new gameplay systems, roadmap, or prototype specification

## Human Approval Required For
- Architecture changes
- Save system changes
- Economy changes
- New gameplay systems
- Release builds
