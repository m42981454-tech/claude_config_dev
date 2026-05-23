---
description: Initialize a new project from project.env by replacing template placeholders and reviewing optional cleanup.
---

# /project:init

Initialize this project template. Prefer the deterministic shell path when possible:

```bash
bash init.sh
```

If shell execution is unavailable, perform the same steps with Read/Edit tools.

## Steps

1. Read `project.env`.
2. Confirm required values are present:
   - `PROJECT_NAME`, `PHASE`, `MAIN_BRANCH`
   - `REPO_OWNER`, `REPO_NAME`
   - `BACKEND_DIR`, `FRONTEND_DIR`
   - backend stack fields
   - frontend stack fields
   - `TASK_QUEUE`, `I18N`
3. Replace placeholders in:
   - `CLAUDE.md`
   - `progress.md`
   - `.claude/rules/git-workflow.md`
   - `.claude/rules/behavioral-rules.md`
   - `.claude/rules/project-context.md`
   - `.claude/rules/stack-backend.md`
   - `.claude/rules/stack-frontend.md`
   - `.claude/rules/README.md`
   - `.githooks/pre-commit`
4. Review optional stack rows:
   - Remove `TASK_QUEUE` row if no task queue exists.
   - Remove `I18N` row if no i18n library exists.
   - Remove backend/frontend stack rule files if the project does not have that side.
5. Review `.claude/agents/.enabled` and keep only project-needed optional agents.
6. Install Git hooks after `git init`:

```bash
bash .githooks/install.sh
```

7. Run validation:

```bash
.claude/scripts/validate.sh --force
```

On Windows PowerShell:

```powershell
.claude\scripts\validate.ps1 -Force
```

## Completion Checklist

- Placeholder replacement is complete.
- `validate.sh` or `validate.ps1` exits 0 after initialization and cleanup.
- `project.env`, `init.sh`, and `SETUP.md` are deleted before the first real project commit, unless the team intentionally keeps them as docs.
- The first commit is made on a work branch, not directly on the protected main branch.

## Template Maintenance Notes

`docs/superpowers/specs/`, `docs/bak/`, and `docs/claude-code-best-practices.md` are template maintenance references. They are ignored by template `.claudeignore` where appropriate and should not be treated as project working context.
