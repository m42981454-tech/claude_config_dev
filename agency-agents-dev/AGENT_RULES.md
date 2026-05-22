# Agency Agents Dev Rules

This directory is the curated agent pool used by the Claude Code agent loader.
It is not the upstream reference library and it is not a project-specific agent
directory.

## Directory Roles

- `<agent-reference-root>`
  - Upstream/reference source.
  - Keep read-only unless intentionally refreshing from upstream.
  - Do not use it directly as the runtime pool.

- `<agent-dev-pool>`
  - Curated runtime pool.
  - New reusable agents should be normalized here before use.
  - The project loader copies agents from here into a project only when missing.

- `<global-claude-config>/agents`
  - Global default agents available across projects.
  - Keep this set small and high-signal.

- `<project>/.claude/agents`
  - Project-local agents.
  - A project-local file with the same agent filename wins because the loader
    skips files that already exist.

## Terms

- `<agent-reference-root>`: The full upstream or vendor-provided agent
  collection. Treat it as source material, not as the active runtime pool.
- `<agent-dev-pool>`: The curated set of reusable agents that has been reviewed
  and normalized for local/project use.
- `<global-claude-config>`: The user-level Claude Code configuration directory
  that contains global settings, hooks, plugins, and global agents.
- `<project>`: Any repository or workspace using Claude Code project settings.
- `runtime pool`: The directory the loader reads from when a project asks for an
  agent by ID.
- `agent ID`: The stable kebab-case identifier used as both the filename stem
  and the frontmatter `name`.
- `project-local override`: A project-specific agent file with the same ID as a
  pool agent. It takes precedence because the loader does not overwrite existing
  project-local files.
- `.enabled`: A small manifest listing which shared agent IDs a project wants
  to bootstrap from the runtime pool.

## Agent File Rules

Each agent must be one Markdown file named with a stable kebab-case ID:

```text
security-engineer.md
api-tester.md
database-optimizer.md
```

The frontmatter `name` must match the filename without `.md`:

```yaml
---
name: security-engineer
description: Short, specific trigger description.
model: sonnet
color: red
---
```

Rules:

- Use lowercase kebab-case for `name`.
- Keep `description` concise and trigger-oriented.
- Prefer `model: sonnet` unless the agent has a strong reason to use another model.
- Do not use display names such as `Security Engineer` in `name`.
- Avoid duplicate `name` IDs across the runtime pool.
- Keep examples and templates only when they materially improve agent behavior.

## Project Enablement Rules

Projects should declare desired pool agents in:

```text
<project>/.claude/agents/.enabled
```

Use kebab-case IDs, one per line:

```text
# enabled project agents
security-engineer
api-tester
database-optimizer
```

The loader resolves each entry to:

```text
<agent-dev-pool>/<agent-id>.md
```

Then it copies the file to:

```text
<project>/.claude/agents/<agent-id>.md
```

Only missing files are copied. Existing project-local files are never
overwritten.

## Project Override Rules

For a project-specific override:

1. Keep the same filename and frontmatter `name`.
2. Place the custom file in `<project>/.claude/agents/<agent-id>.md`.
3. Keep the agent ID listed in `.enabled` for documentation and future bootstrap.
4. The loader will skip the pool version because the project file already exists.

For a project-only agent that is not in the curated pool:

1. Add `<project>/.claude/agents/<agent-id>.md`.
2. Use kebab-case `name: <agent-id>`.
3. Add the ID to `.enabled` only if the project wants it documented with the
   rest of the active agent set.
4. Expect the loader to report it missing from the pool unless the loader is
   later taught to treat project-local-only entries as valid.

## Context And Token Rules

- Keep global agents few and reusable.
- Keep project `.enabled` small; enable only agents the project actually needs.
- Do not copy the whole reference library into a project.
- Prefer short role rules over long embedded examples.
- Move long examples, checklists, and templates to docs when they are not needed
  on every invocation.
- Add `tools`, `maxTurns`, or similar boundaries only after confirming the
  target Claude Code version supports them for subagents.

## Maintenance Checklist

Before adding or updating an agent in this pool:

1. Filename is kebab-case and ends with `.md`.
2. Frontmatter starts at line 1 with `---`.
3. `name` equals the filename without `.md`.
4. `description` is concise and specific.
5. `model` is present.
6. No accidental project-specific paths, secrets, or local assumptions.
7. The prompt is not mostly reusable boilerplate copied from another agent.
8. If copied from `agency-agents-reference`, normalize the metadata before use.

Suggested validation commands:

```powershell
Get-ChildItem <agent-dev-pool> -Filter *.md |
  ForEach-Object {
    $expected = $_.BaseName
    $name = (Select-String -Path $_.FullName -Pattern '^name:' |
      Select-Object -First 1).Line -replace '^name:\s*',''
    if ($name -ne $expected) {
      "BAD $($_.Name): name is '$name', expected '$expected'"
    }
  }
```

## Current Recommended Workflow

1. Browse `<agent-reference-root>` for candidates.
2. Copy only selected candidates into `<agent-dev-pool>`.
3. Normalize metadata in `<agent-dev-pool>`.
4. Add the kebab-case agent ID to a project's `.enabled`.
5. Start or reload Claude Code so the loader can copy missing agents.
6. If a project needs custom behavior, edit the project-local copy rather than
   changing the shared pool for one-off needs.
