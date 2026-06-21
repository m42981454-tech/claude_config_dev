# Claude Code Global Baseline

> Cross-project baseline. Project-level `CLAUDE.md` may override or extend these rules.

---

## 1. Communication Language

- Respond to the user in **Chinese** by default (questions, answers, explanations, suggestions)
- Code, variable names, and commands in English
- Commit message body in Chinese; technical terms wrapped in English backticks

---

## 2. Session & Context Management

### Three Iron Rules

1. **Context isolation via multiple clients + `git worktree`** — never split context within a conversation (subagents must return; they are not independent sessions)
2. **Cross-session continuity via `progress.md` + `memory/` + `CLAUDE.md`** — do not cling to a single session
3. **Heavy output (long logs / large searches / full file dumps) always goes to a subagent** — the main session receives summaries only

### Scenario Playbook

| Scenario | Action |
|---|---|
| Same task, context growing large | `/compact <what to preserve>` |
| Multiple independent tasks in parallel | Open separate Claude panels + isolate with `git worktree` |
| Switching tasks (serial) | Update `progress.md` → `/clear` or new session |
| Heavy research / large logs | Dispatch `Explore` / `general-purpose` subagent |
| Resume prior session | `claude --resume <id>` |

### Required Trio Per Project

- **`CLAUDE.md`**: project conventions, role boundaries, prohibitions (stable rules)
- **`progress.md`**: single source of truth for task state (update immediately after each merge)
- **`memory/`**: cross-session user preferences / external resource pointers (non-derivable from code)

### Key Discipline

- Always pass a prompt to `/compact` — state explicitly what to preserve
- Update `progress.md` immediately after a sprint or task completes, before opening the next session
- When dispatching subagents, specify "return summary only — do not pipe raw output back"
- **Never run two Claude instances in the same directory simultaneously** (parallel work = different worktrees + different sessions)

---

## 3. Priority Order (on conflict)

1. Explicit user instruction
2. Project-level `CLAUDE.md`
3. This global baseline
4. Default system prompt

---

## 4. Git Workflow Baseline

- Never commit directly to the main branch (unless the user explicitly instructs it); all changes go through a feature branch
- Use `--no-ff` on merges to preserve topology
- Never bypass hooks (`--no-verify` / `--no-gpg-sign`)
- Never amend pushed history, rebase merged history, or force-push
- Run `git status` / `git diff` before committing; stage only files relevant to the current task

Branch naming, main branch name, and PR targets are defined by the project-level `CLAUDE.md`.

---

## 5. Testing Discipline

- Never delete existing tests or use skip markers to hide failures
- **Run commands and verify** before declaring anything complete — evidence before assertions
- Changes that affect shared contracts, routes, API clients, or UI shells require broader verification scope

---

## 6. Plugin Configuration

Installation policy, tier classification, and conflict boundaries are in the file below (auto-loaded via `@import`):

- @~/.claude/rules/plugins.md

---

## 7. Superpowers Skill Mandatory Trigger Rules

The following trigger conditions are **non-negotiable** and take priority over a skill's own internal judgment.

### 7.1 brainstorming — when to trigger

Invoke `superpowers:brainstorming` **before any response** when the user message meets any of the following:

- Proposes a new feature / module / system ("I want to build X" / "Can we support Y" / "Design Z for me")
- Asks "how should we approach this" / "how do I implement" / "what are the options" (design discussion)
- Starts any sprint or task ("kick off phN" / "start the XXX feature")
- Says "brainstorm" / "let's discuss" / "what do you think"

**Hard gate**: Do NOT begin implementation or write any code until brainstorming is complete and the user has approved the design.

### 7.2 writing-plans — when to trigger

- After brainstorming completes and the user approves the design → **must invoke `superpowers:writing-plans`**
- User says "write a plan" / "create an implementation plan" / "make a plan"

### 7.3 systematic-debugging — when to trigger

- User reports a bug / test failure / unexpected behavior ("why does X not work" / "there's a bug here")
- **Hard gate**: Do NOT guess the cause and edit code directly — always follow the debugging process first

### 7.4 verification-before-completion — when to trigger

- Before declaring any task "done"
- User asks "is it done?" / "ready to merge?"

### 7.5 Do NOT trigger

- Pure factual questions ("what does this function do" / "where is the file")
- Execution phase when a plan already exists (use `superpowers:executing-plans`)

---

## 8. Subagent Model Hierarchy (体制配置)

When dispatching subagents via the Agent tool, set the `model` parameter according to this hierarchy:

| Role | Model | Scope |
|---|---|---|
| **PM** (main session) | fable / opus — whichever the user currently has selected; never downgrade | Orchestration, decisions, review arbitration, merges |
| **Leader** | `opus` | High-judgment tasks: architecture/design review, final code review before merge, complex root-cause analysis |
| **Worker — complex** | `sonnet` | Dev/test/ops execution with integration or judgment: multi-file implementation, non-trivial fixes, spec/quality reviews of substantial diffs |
| **Worker — light** | `haiku` | Investigation & retrieval only: Explore searches, fact lookups, re-review of tiny verified diffs, mechanical single-file edits |

Principles:

- Day-to-day execution runs on **sonnet/haiku**; escalate to **opus (Leader)** only when the task genuinely needs high-level judgment
- The PM role is the main session itself — subagents do NOT inherit the main session's model; always specify explicitly from this table
- If a worker reports BLOCKED and the cause is reasoning capacity (not missing context), re-dispatch one tier up (haiku→sonnet→opus)
