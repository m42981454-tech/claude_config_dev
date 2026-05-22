# [PROJECT_NAME] Project Conventions

> Current phase: **[PHASE]**
> Last updated: **[DATE]**
> Summary: [Brief project and phase description]

This file is the project-specific quick entry point. Detailed behavior, engineering, git, testing, orchestration, and documentation rules live under `.claude/rules/` and are loaded by scope.

---

## 1. Repository Structure

```text
[project-root]/
|-- [backend-dir]/              # [BACKEND_STACK] backend
|   |-- app/                    # application code
|   |-- tests/                  # backend tests
|   `-- ...
|-- [frontend-dir]/             # [FRONTEND_STACK] frontend
|   |-- app/                    # pages/routes
|   |-- components/             # UI components
|   |-- lib/                    # utilities
|   `-- ...
|-- docs/                       # project documentation
|-- progress.md                 # single source of task status
|-- CLAUDE.md                   # this file
`-- .claude/                    # project Claude Code configuration
```

Remove unused placeholder directories and rules during project initialization.

---

## 2. Technology Stack

| Area | Stack | Detailed Rule |
|---|---|---|
| Backend | `[BACKEND_STACK]` | `.claude/rules/stack-backend.md` |
| Frontend | `[FRONTEND_STACK]` | `.claude/rules/stack-frontend.md` |
| Infrastructure | `[INFRA]` | Add `stack-infra.md` only when needed |

When initializing a real project, replace placeholders from `project.env`, then remove `project.env`, `init.sh`, and `SETUP.md` after setup.

---

## 3. Current Task Pointer

Use `progress.md` as the single source of current task state.

```text
progress.md
```

Keep it concise and current. Detailed progress conventions are in `.claude/rules/progress-conventions.md`.

---

## 4. Agent Layers

Detailed dispatch rules and double-signoff requirements live in `.claude/rules/team-orchestration.md`.

### L2 User-Level Baseline Agents

These are expected to be available from the user-level Claude config and should not be duplicated into every project by default.

| Agent | Use When |
|---|---|
| `project-manager-senior` | scope, task breakdown, roadmap, acceptance criteria |
| `code-reviewer` | review before merge or before declaring work complete |
| `minimal-change-engineer` | small fixes, contained refactors, surgical changes |
| `git-workflow-master` | branch, commit, merge, release, and git hygiene |

### L3 Project Template Agents

These live in `.claude/agents/` for new projects.

| Agent | Use When |
|---|---|
| `agents-orchestrator` | coordinate multiple agents or route work |
| `backend-architect` | backend design, API shape, data boundaries |
| `frontend-developer` | UI implementation, component structure, frontend polish |
| `reality-checker` | readiness checks, evidence, gap finding |
| `project-management-jira-workflow-steward` | Jira-linked workflow and progress hygiene |

### Optional Shared Agents

Enable optional shared agents in `.claude/agents/.enabled`, one kebab-case ID per line. Missing enabled agents are copied from the shared dev pool by the SessionStart loader.

Use `.claude/agents/.enabled.example` as the reference list.

---

## 5. Rule Index

Do not duplicate full rule text in this file. Use these loaded rule files instead:

| Topic | Rule File |
|---|---|
| Engineering behavior | `.claude/rules/engineering.md` |
| Required behavior and testing | `.claude/rules/behavioral-rules.md` |
| Git workflow | `.claude/rules/git-workflow.md` |
| Team dispatch and agent orchestration | `.claude/rules/team-orchestration.md` |
| Architecture policy | `.claude/rules/architecture-policies.md` |
| Documentation conventions | `.claude/rules/docs-conventions.md` |
| Progress conventions | `.claude/rules/progress-conventions.md` |
| Rule catalog | `.claude/rules/README.md` |

Path-scoped stack rules:

| Area | Rule File |
|---|---|
| Backend paths | `.claude/rules/stack-backend.md` |
| Frontend paths | `.claude/rules/stack-frontend.md` |

---

## 6. Commands, Skills, And Hooks

Descriptions are defined in each command or skill file. Keep this section as an index only.

| Type | Location |
|---|---|
| Commands | `.claude/commands/` |
| Skills | `.claude/skills/` |
| Hooks | `.claude/settings.json` |
| Project-local scripts | `.claude/scripts/` |

Important hooks:

| Hook | Purpose |
|---|---|
| `PreToolUse` | block dangerous git/shell patterns |
| `PostToolUse` | remind about progress updates after workflow actions |
| `SessionStart` | copy enabled agents and show short project state |
| `SessionEnd` | write local session memory without calling a model |

---

## 7. Project-Specific DON'T List

General behavior rules are in `.claude/rules/behavioral-rules.md`. Keep only project-specific prohibitions here.

- Do not commit directly to `[MAIN_BRANCH]`; use a feature or sprint branch.
- Do not bypass hooks with `--no-verify`, `--no-gpg-sign`, or equivalent config flags.
- Do not merge sprint branches unless `progress.md` is current.
- Do not use `git push --force` unless a human explicitly asks for it.
- Do not remove or rewrite `.claude/`, `docs/`, migrations, or production configuration without explicit approval.
- Do not skip existing tests to hide failures.
- Do not declare work complete without verification evidence.
- Do not dispatch subagents when a small direct edit is enough.

---

## 8. Initialization Notes

For a new project:

1. Fill `project.env`.
2. Run `/project:init` in Claude Code, or run `bash init.sh` from a shell.
3. Remove unused stack rules and placeholder sections.
4. Review `.claude/agents/.enabled`.
5. Commit the initialized project.

Full setup details live in `SETUP.md`.
