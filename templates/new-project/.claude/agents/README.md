# Project Agents

Claude Code registers agent files that live directly under `.claude/agents/`.

## Default State

Template agents are stored under `_available/` so they are documented but not active by default. Claude Code should not auto-register nested `_available/*.md` files.

## Enable An Agent

Copy only the agents needed by the project:

```bash
cp .claude/agents/_available/api-tester.md .claude/agents/
cp .claude/agents/_available/security-engineer.md .claude/agents/
```

Alternatively, create `.enabled` from `.enabled.example` and keep only the desired kebab-case IDs. On SessionStart, `agent-loader` copies missing agents from `_available/` first, then from the shared user-level pool:

```bash
cp .claude/agents/.enabled.example .claude/agents/.enabled
```

This keeps project agents disabled by default while making opt-in activation deterministic.

## Files

| Path | Purpose |
|---|---|
| `_available/` | template-local agent reference pool, inactive by default |
| `.enabled.example` | recommended optional agent list with comments |
| `.enabled` | project activation list, created by the user and usually gitignored |
| `<name>.md` | active project-local agent registered by Claude Code |
| `README.md` | this guide |
