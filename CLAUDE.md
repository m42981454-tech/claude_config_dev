# Claude Code Global Baseline

> Cross-project baseline. Project-level `CLAUDE.md` may override or extend these rules.
> 完整原文（含全部示例短语，2026-06-21 之前版本）见 `~/.claude/archive/claude-md-full-v1-20260621.md`。

## 1. Communication Language

- Respond in **Chinese** by default; code, variable names, and commands in English
- Commit message body in Chinese; technical terms wrapped in English backticks

## 2. Session & Context Management

**Three Iron Rules:**
1. Context isolation via multiple clients + `git worktree` — never split context within one conversation (subagents must return; they are not independent sessions)
2. Cross-session continuity via `progress.md` + `memory/` + `CLAUDE.md` — do not cling to a single session
3. Heavy output (long logs / large searches / full file dumps) always goes to a subagent — main session receives summaries only

| Scenario | Action |
|---|---|
| Same task, context growing large | `/compact <what to preserve>` |
| Multiple independent tasks in parallel | Separate Claude panels + `git worktree` |
| Switching tasks (serial) | Update `progress.md` → `/clear` or new session |
| Heavy research / large logs | Dispatch `Explore` / `general-purpose` subagent |
| Resume prior session | `claude --resume <id>` |

Required per project: `CLAUDE.md`(conventions/prohibitions) + `progress.md`(task state, update immediately after each merge) + `memory/`(cross-session preferences, non-derivable from code).

- Always pass an explicit "what to preserve" prompt to `/compact`
- When dispatching subagents, specify "return summary only — do not pipe raw output back"
- Never run two Claude instances in the same directory simultaneously (parallel work = different worktrees + different sessions)

## 3. Priority Order (on conflict)

Explicit user instruction > Project-level `CLAUDE.md` > this global baseline > default system prompt

## 4. Git Workflow Baseline

- Never commit directly to the main branch (unless explicitly instructed); all changes go through a feature branch
- `--no-ff` on merges to preserve topology; never bypass hooks (`--no-verify`/`--no-gpg-sign`), amend pushed history, rebase merged history, or force-push
- `git status`/`git diff` before committing; stage only files relevant to the current task
- Branch naming, main branch name, and PR targets are defined by the project-level `CLAUDE.md`

## 5. Testing Discipline

- Never delete existing tests or use skip markers to hide failures
- **Run commands and verify** before declaring anything complete — evidence before assertions
- Changes affecting shared contracts, routes, API clients, or UI shells require broader verification scope

## 6. Plugin Configuration

@~/.claude/rules/plugins.md

## 7. Superpowers Skill Mandatory Triggers

Non-negotiable; takes priority over a skill's own internal judgment.

| Trigger condition | Must invoke | Hard gate |
|---|---|---|
| New feature/module/system proposed; "how should we approach"/design discussion; starting any sprint/task; "brainstorm"/"讨论"/"what do you think" | `superpowers:brainstorming` | No code before brainstorming complete + design approved |
| Brainstorming approved; or user says "write a plan"/"make a plan" | `superpowers:writing-plans` | — |
| Bug / test failure / unexpected behavior reported | `superpowers:systematic-debugging` | No guess-and-fix before following the debugging process |
| Before declaring any task "done"; "is it done?"/"ready to merge?" | `superpowers:verification-before-completion` | — |
| Pure factual question ("what does X do"/"where is the file"); executing an already-approved plan | Skip (use `superpowers:executing-plans` for the latter) | — |

## 8. Subagent Model Hierarchy

When dispatching subagents via the Agent tool, set the `model` parameter according to this hierarchy:

| Role | Model | Scope |
|---|---|---|
| **PM** (main session) | fable / opus — whichever the user currently has selected; never downgrade | Orchestration, decisions, review arbitration, merges |
| **Leader** | `opus` | High-judgment tasks: architecture/design review, final code review before merge, complex root-cause analysis |
| **Worker — complex** | `sonnet` | Dev/test/ops execution with integration or judgment: multi-file implementation, non-trivial fixes, spec/quality reviews of substantial diffs |
| **Worker — light** | `haiku` | Investigation & retrieval only: Explore searches, fact lookups, re-review of tiny verified diffs, mechanical single-file edits |

- Day-to-day execution runs on **sonnet/haiku**; escalate to **opus (Leader)** only when the task genuinely needs high-level judgment
- The PM role is the main session itself — subagents do NOT inherit the main session's model; always specify explicitly from this table
- If a worker reports BLOCKED and the cause is reasoning capacity (not missing context), re-dispatch one tier up (haiku→sonnet→opus)
