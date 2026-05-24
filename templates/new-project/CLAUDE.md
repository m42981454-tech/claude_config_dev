# [PROJECT_NAME] Project Conventions

> Phase: **[PHASE]**
> Updated: **[DATE]**
> Summary: [Brief project and current work]

This is the quick entry point for Claude Code. Keep it short. Detailed behavior lives in `.claude/rules/`, commands in `.claude/commands/`, and skills in `.claude/skills/`.

## 1. Repository

```text
[project-root]/
|-- [backend-dir]/        # [BACKEND_STACK] backend
|-- [frontend-dir]/       # [FRONTEND_STACK] frontend
|-- docs/                 # project documentation
|-- progress.md           # current work state
|-- CLAUDE.md             # this file
`-- .claude/              # Claude Code project config
```

Remove unused placeholder directories and rules during project initialization.

## 2. Stack

| Area | Stack | Rule |
|---|---|---|
| Backend | `[BACKEND_STACK]` | `.claude/rules/stack-backend.md` |
| Frontend | `[FRONTEND_STACK]` | `.claude/rules/stack-frontend.md` |
| Infrastructure | `[INFRA]` | add `stack-infra.md` only when needed |

After setup, replace placeholders from `project.env`, then remove `project.env` and `SETUP.md`.

## 3. Current Work

Use `progress.md` as the single source for current task state.

```text
progress.md
```

Progress rules live in `.claude/rules/progress-conventions.md`.

## 4. Agents

L3 project agents are available but disabled by default. Source files live in `.claude/agents/_available/`; copy one into `.claude/agents/` or enable it through `.claude/agents/.enabled` before dispatching it. See `.claude/agents/README.md`.

Dispatch and double-signoff rules live in `.claude/rules/team-orchestration.md`.

| Layer | Agent | Use When |
|---|---|---|
| L2 user | `project-manager-senior` | scope, task breakdown, acceptance |
| L2 user | `code-reviewer` | review before merge or completion |
| L2 user | `minimal-change-engineer` | surgical fixes and contained refactors |
| L2 user | `git-workflow-master` | branch, commit, merge, release hygiene |
| L3 project | `agents-orchestrator` | multi-agent coordination |
| L3 project | `backend-architect` | backend design and data/API boundaries |
| L3 project | `frontend-developer` | UI implementation and frontend polish |
| L3 project | `reality-checker` | evidence, readiness, gap checks |
| L3 project | `project-management-jira-workflow-steward` | issue-first workflow and progress hygiene |

Optional shared agents are enabled via `.claude/agents/.enabled`. Use `.claude/agents/.enabled.example` as the reference list.

## 5. Rules

| Topic | Rule |
|---|---|
| Engineering behavior | `.claude/rules/engineering.md` |
| Required behavior and tests | `.claude/rules/behavioral-rules.md` |
| Git workflow | `.claude/rules/git-workflow.md` |
| Team orchestration | `.claude/rules/team-orchestration.md` |
| Architecture policy | `.claude/rules/architecture-policies.md` |
| Documentation | `.claude/rules/docs-conventions.md` |
| Progress | `.claude/rules/progress-conventions.md` |
| Rule catalog | `.claude/rules/README.md` |

Stack-specific rules:

| Area | Rule |
|---|---|
| Backend paths | `.claude/rules/stack-backend.md` |
| Frontend paths | `.claude/rules/stack-frontend.md` |

## 6. Commands, Skills, Hooks

| Type | Location |
|---|---|
| Commands | `.claude/commands/` |
| Skills | `.claude/skills/` |
| Hooks | `.claude/settings.json` |
| Scripts | `.claude/scripts/` |

Hook summary: `PreToolUse` blocks dangerous shell/git patterns, `PostToolUse` reminds about workflow records, `SessionStart` loads enabled agents and prints one short state line, and `SessionEnd` writes local session memory.

## 7. Project DON'Ts

- Do not commit directly to `[MAIN_BRANCH]`; use a feature or sprint branch.
- Do not bypass hooks with `--no-verify`, `--no-gpg-sign`, or equivalent config flags.
- Do not merge sprint branches unless `progress.md` is current.
- Do not use `git push --force` unless a human explicitly asks for it.
- Do not remove or rewrite `.claude/`, `docs/`, migrations, or production config without explicit approval.
- Do not skip existing tests to hide failures.
- Do not declare work complete without verification evidence.
- Do not dispatch subagents when a small direct edit is enough.

## 8. Compaction Rules

When compacting, always preserve:
- Full list of modified files (with paths)
- Current sprint name and phase (design / impl / review / test)
- All test commands run this session and their results
- Any architectural decisions made this session
- Open blockers or unresolved questions
- Error messages and their resolutions

## 9. Skill 强制触发规则

以下触发条件不可绕过，AI 在回复之前必须先调用对应 skill。

| 场景 | 必须调用 |
|---|---|
| 用户提出新功能 / 新模块需求，或问"应该怎么做" | `superpowers:brainstorming` |
| 启动任何 sprint / 任务之前 | `superpowers:brainstorming` |
| brainstorming 完成、用户批准设计后 | `superpowers:writing-plans` |
| 报告 bug / 排查异常 | `superpowers:systematic-debugging` |
| 有明确 plan 需要执行时 | `superpowers:executing-plans` 或 `superpowers:subagent-driven-development` |

**brainstorming 未完成并获得用户批准，禁止开始实现或写代码。**

## 10. Setup

1. Fill `project.env`.
2. Run `/project:init` in Claude Code, or run `bash .claude/scripts/init.sh`.
3. Remove unused stack rules and placeholder sections.
4. Review `.claude/agents/.enabled`.
5. Commit the initialized project.
