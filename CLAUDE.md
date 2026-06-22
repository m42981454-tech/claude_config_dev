# Claude Code Global Baseline

> Cross-project baseline. Project-level `CLAUDE.md` may override or extend these rules.
> Full original (with all example phrases, pre-2026-06-21 version) see `~/.claude/archive/claude-md-full-v1-20260621.md`.

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
| New feature/module/system proposed; "how should we approach"/design discussion; starting any sprint/task; "brainstorm"/"discuss"/"what do you think" | `superpowers:brainstorming` | No code before brainstorming complete + design approved |
| Brainstorming approved; or user says "write a plan"/"make a plan" | `superpowers:writing-plans` | — |
| Bug / test failure / unexpected behavior reported | `superpowers:systematic-debugging` | No guess-and-fix before following the debugging process |
| Before declaring any task "done"; "is it done?"/"ready to merge?" | `superpowers:verification-before-completion` | — |
| Pure factual question ("what does X do"/"where is the file"); executing an already-approved plan | Skip (use `superpowers:executing-plans` for the latter) | — |

## 8. Subagent Model Hierarchy

When dispatching subagents via the Agent tool, set the `model` parameter according to this hierarchy:

| Role | Model | Scope |
|---|---|---|
| **PM** (main session) | fable / opus — whichever the user currently has selected; never downgrade | **Do as little as possible**: only orchestration, task dispatch, final merge decisions. Always delegate verification/review/investigation/implementation — don't keep opus working. Allocate flexibly to minimize token cost |
| **Leader / acceptance** | `sonnet` (default) → `opus` (fallback only) | **Default to sonnet**: architecture/design review, code review, **acceptance, quality gates**, root-cause analysis. Escalate to opus only for high-stakes judgment that sonnet Leader clearly can't handle (major architecture decisions, final-review disagreements, complex root-cause) |
| **Worker — complex** | `sonnet` | Dev/test/ops execution with integration or judgment: multi-file implementation, non-trivial fixes, spec/quality reviews of substantial diffs. **Investigation/exploration also defaults here** (codebase exploration, Explore searches, judgment-requiring retrieval) — investigation quality matters more than cost |
| **Worker — light** | `haiku` | ONLY truly trivial mechanical work: finding files, grepping content, mechanical single-file read/edit, re-review of tiny already-verified diffs. Escalate to sonnet once cross-file synthesis or judgment is needed |

- Day-to-day execution AND acceptance/review run on **sonnet/haiku**; **opus is a fallback only when sonnet clearly can't cope**. Default assumption is that sonnet suffices — dispatch sonnet first, escalate to opus only if it isn't enough
- Goal: minimize opus main-session token usage. Delegate everything delegable (implementation/investigation/acceptance/review/screenshot judgment) — the main thread receives text summaries only
- **Pre-action gate** (run before ANY non-read-only Bash / Edit / deploy / investigation): (1) Is this strict-opus — a *decision*, *subagent-orchestration judgment* (decomposition / prompt-writing / arbitrating results), or something genuinely needing a high-level model? If NO → delegate. (2) Is shipping the needed context to a subagent cheaper than handling it inline? If YES → delegate to sonnet/haiku; if NO (e.g. it would require dumping a long conversation) → keep inline. Optimize total token cost, not dogmatic delegation.
- Conversation introspection/reflection may ALSO run on a **sonnet** leader (subject to the context-length check above), not just verification/review/investigation. opus is reserved for genuine high-judgment work — never for routine reflection or zero-context ops like deploys.
- The PM role is the main session itself — subagents do NOT inherit the main session's model; always specify explicitly from this table
- If a worker reports BLOCKED and the cause is reasoning capacity (not missing context), re-dispatch one tier up (haiku→sonnet→opus)
