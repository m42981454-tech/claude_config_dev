# Session Review Command Design

> **Date**: 2026-05-24
> **Status**: Draft, waiting for user review
> **Scope**: `new-project` template manual session review command

---

## 0. TL;DR

Add a manually triggered command:

```text
/project:session-review
```

The command reviews the previous session summary, git state, progress state, and recent work evidence, then produces a human-reviewable report. It must not automatically update rules, `CLAUDE.md`, agents, plugins, or project files.

Core principle:

```text
Automatic capture, manual review, human-approved promotion.
```

This keeps session learning useful without turning it into hidden context growth or silent rule mutation.

---

## 1. Background

The template already has `SessionEnd` learning support:

- `SessionEnd` hook calls `.claude/scripts/session-end-learn.sh`.
- The script writes local session records under `.claude/session-memory/`.
- `.claude/session-memory/` is ignored by git.
- The hook avoids LLM calls, agent calls, network access, and transcript-body ingestion.

This is intentionally conservative. It records session state, but it does not deeply learn user behavior or promote preferences into rules.

The next step should not be automatic learning. It should be a manually triggered review flow.

---

## 2. Goals

1. Summarize the previous session in a structured way.
2. Identify candidate user habits and working-style preferences.
3. Separate facts, inferred habits, and rule-promotion suggestions.
4. Require human confirmation before any rule or template change.
5. Keep context bounded by reading only high-signal files.
6. Avoid automatic long-term memory mutation.

---

## 3. Non-Goals

- Do not call the command automatically from `SessionEnd`.
- Do not read full Claude transcript bodies by default.
- Do not auto-edit `.claude/rules/`, `CLAUDE.md`, `.enabled`, plugin config, or agent prompts.
- Do not commit automatically.
- Do not promote one-off user preferences into permanent rules.
- Do not scan the whole repository.

---

## 4. Proposed Files

| File | Purpose |
|---|---|
| `.claude/commands/project/session-review.md` | Claude Code command entry point and review instructions |
| `.claude/scripts/session-review-context.sh` | Small bounded context collector |
| `.claude/rules/user-working-style.md.example` | Optional format for promoted working-style preferences |

`user-working-style.md.example` should be included in the template. A real `user-working-style.md` should be created only after explicit user approval.

---

## 5. Input Sources

The command should read inputs in this order:

| Priority | Source | Purpose |
|---|---|---|
| 1 | `.claude/session-memory/latest.md` | Most recent session summary or metadata |
| 2 | `.claude/session-memory/YYYY-MM-DD-session.md` | Same-day session continuity |
| 3 | `git status --short --branch` | Dirty state and current branch |
| 4 | `git log -5 --oneline` | Recent commit trail |
| 5 | `progress.md` | Current work state |
| 6 | Known report/spec paths when explicitly relevant | Evidence for larger template or project changes |

The command must not default to reading every file under `docs/`.

---

## 6. Context Collector Behavior

`session-review-context.sh` should:

1. Resolve the git project root.
2. Print a compact markdown bundle.
3. Include only existing files.
4. Cap long files with conservative line limits.
5. Avoid secrets and transcript bodies.
6. Exit `0` even when optional files are missing.

Recommended output sections:

```markdown
# Session Review Context

## Latest Session Memory
...

## Git Status
...

## Recent Commits
...

## Progress Snapshot
...

## Candidate Reports
...
```

Line caps:

| Section | Limit |
|---|---|
| latest session memory | 120 lines |
| day session memory | 180 lines |
| progress.md | 160 lines |
| report/spec excerpts | 120 lines each |

---

## 7. Command Output Format

`/project:session-review` should answer in Chinese for human-facing sections. Machine-oriented labels can stay in English.

Recommended output:

```markdown
# Session Review

## 1. 本次会话事实
- 做了什么
- 改了哪些路径
- 运行了哪些验证
- 还有什么未完成

## 2. 用户使用习惯候选

| Confidence | Habit | Evidence | Suggested Rule |
|---|---|---|---|
| high | ... | ... | ... |
| medium | ... | ... | ... |

## 3. 可固化规则建议

### 建议写入项目规则
- ...

### 建议只保留为本地偏好
- ...

### 不建议固化
- ...

## 4. 风险
- ...

## 5. 下一步建议
- ...
```

---

## 8. Promotion Policy

Not every observed behavior should become a rule.

| Type | Example | Handling |
|---|---|---|
| Stable working preference | Chinese human-facing output, review before merge | Candidate for `user-working-style.md` |
| Project governance rule | Manual plugin enablement, agent disabled by default | Candidate for project rules or template specs |
| One-off decision | "Do not do plugin policy today" | Keep in session review only |
| Ambiguous behavior | User accepted something once | Do not promote |

Promotion requires explicit user approval.

Approved rules can be written to:

```text
.claude/rules/user-working-style.md
```

Template should only ship:

```text
.claude/rules/user-working-style.md.example
```

---

## 9. Safety Rules

The command must explicitly follow these constraints:

- Do not modify files unless the user separately approves an implementation step.
- Do not update `CLAUDE.md` automatically.
- Do not update `.claude/rules/` automatically.
- Do not enable agents or plugins automatically.
- Do not read full transcripts unless the user provides a path and explicitly asks for that.
- Do not commit automatically.
- Treat all habit detection as inference, not fact.
- Prefer "candidate preference" over "user always wants".

---

## 10. Expected Workflow

1. `SessionEnd` writes local session memory.
2. User starts a later session and runs:

   ```text
   /project:session-review
   ```

3. Command gathers bounded context.
4. Assistant produces a structured session review.
5. User decides whether any preference should be promoted.
6. A separate task implements approved promotions.

---

## 11. Verification Plan

Before considering the command ready:

1. Run `bash -n .claude/scripts/session-review-context.sh`.
2. Run the collector in a temporary initialized project.
3. Confirm missing optional files do not fail the command.
4. Confirm it does not print transcript bodies.
5. Confirm output stays compact.
6. Confirm `.claude/session-memory/` remains ignored.
7. Confirm `/project:session-review` never instructs the assistant to edit files automatically.

---

## 12. Open Questions

1. Should the report be written to a file automatically, or only printed in chat?
2. Should approved long-term preferences be project-local or user-level by default?
3. Should the command include the latest report under `templates/report/` when present, or only when the user names it?

Recommended defaults:

- Print in chat by default.
- Write files only after explicit approval.
- Treat user-level preference promotion as a separate manual step.
