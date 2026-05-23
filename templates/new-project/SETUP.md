# New Project Setup

Use this checklist after copying `templates/new-project/` into a real project.

## 0. Prerequisites

Required tools:

| Tool | Why |
|---|---|
| Git | repository initialization and hooks |
| Git Bash | runs `init.sh`, git hooks, and Claude Code shell hooks on Windows |
| jq | parses Claude Code hook payloads safely |

On Windows, make sure Git Bash is available as `bash` before the WSL launcher. If `where bash` shows `C:\Windows\System32\bash.exe` first, move Git Bash earlier in `PATH` or call Git Bash explicitly while validating.

## 1. Fill `project.env`

Edit `project.env` first. It controls project name, main branch, repository owner/name, directory names, and stack summaries.

Important fields:

| Field | Used By |
|---|---|
| `PROJECT_NAME`, `PHASE`, `MAIN_BRANCH` | `CLAUDE.md`, git workflow rules, progress |
| `REPO_OWNER`, `REPO_NAME` | issue examples and repo references |
| `BACKEND_DIR`, `FRONTEND_DIR` | path-scoped stack rules |
| stack fields | backend/frontend/project context rules |
| `TASK_QUEUE`, `I18N` | optional stack rows; delete rows later if unused |

## 2. Initialize

Preferred shell path:

```bash
bash init.sh
```

Claude Code path:

```text
/project:init
```

The command performs the same replacement steps and points you to validation.

## 3. Review Project-Specific Files

After initialization:

1. Review `.claude/rules/stack-backend.md` and delete unused rows.
2. Review `.claude/rules/stack-frontend.md` and delete unused rows.
3. Delete the backend or frontend stack rule if the project does not have that side.
4. Review `.claude/agents/.enabled`; keep only optional agents needed by this project.
5. Review `progress.md` and update the initial work state.

## 4. Install Git Hooks

After `git init`:

```bash
bash .githooks/install.sh
```

This sets:

```text
core.hooksPath=.githooks
```

The pre-commit hook blocks direct commits to protected main branches while allowing merge, cherry-pick, and revert commits.

## 5. Validate

After initialization and cleanup:

```bash
.claude/scripts/validate.sh
```

On Windows PowerShell:

```powershell
.claude\scripts\validate.ps1
```

Template maintainers can validate before cleanup with:

```bash
.claude/scripts/validate.sh --force
```

```powershell
.claude\scripts\validate.ps1 -Force
```

## 6. Clean Up Before First Commit

Delete template-only files unless your team intentionally keeps them:

```bash
rm project.env init.sh SETUP.md
```

Then create the first real project commit from a work branch, not directly from the protected main branch.

## 7. Agent Files

Default template agents are stored in:

```text
.claude/agents/_available/
```

They are disabled by default. To activate one:

```bash
cp .claude/agents/_available/api-tester.md .claude/agents/
```

Or create `.claude/agents/.enabled` from `.enabled.example` and let the SessionStart loader copy enabled shared agents from the configured user-level pool.

See `.claude/agents/README.md` for details.
