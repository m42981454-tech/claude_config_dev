# Claude Code 配置 Context 优化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> 本计划不含代码/测试，全部是 markdown 配置文件的搬移与精简。"测试"步骤替换为"验证步骤"（行数/字节统计、`claude plugin`/`grep` 检查），用于确认内容未丢失、引用未失效。

**Goal:** 降低 Claude Code 用户级 + 项目级（fifa2026）会话常驻 context 消耗，同时不丢失任何信息——全部迁移到按需加载的位置（archive / skill / 单一来源引用）。

**Architecture:** 不删除任何内容，只做"常驻 → 按需"的搬移，和"重复 → 单一来源引用"的去重。每个任务独立可验证、独立可回滚。

**Tech Stack:** 纯 markdown 文件操作 + `claude plugin` CLI 验证。

## Global Constraints

- 不删除任何文件，除非用户明确确认（来自用户原始安全原则）。
- 所有修改前必须先备份到 `.claude-backup/<timestamp>/`（项目级）和 `~/.claude-backup/<timestamp>/`（用户级）。
- 不输出 `.env`/密钥/token/credential 等敏感内容。
- 只做瘦身/拆分/归档/path 作用域化/按需触发改造，不做破坏性重构。
- 每个任务完成后必须能够独立验证"内容未丢失"。
- 关联审计：[2026-06-21-audit.md](./2026-06-21-audit.md)

---

### Task 1: 备份待修改文件

**Files:**
- Create: `~/.claude-backup/20260621/CLAUDE.md`
- Create: `~/.claude-backup/20260621/rules/plugins.md`
- Create: `D:\projects\github\origin\apps\fifa2026\.claude-backup\20260621\CLAUDE.md`
- Create: `D:\projects\github\origin\apps\fifa2026\.claude-backup\20260621\rules\vibe-workflow.md`
- Create: `~/.claude-backup/20260621/BACKUP_MANIFEST.md`
- Create: `~/.claude-backup/20260621/RESTORE_COMMANDS.md`

**Interfaces:**
- Produces: 4 个原文件的逐字节拷贝 + 1 份清单 + 1 份恢复命令文档，供 Task 2-4 修改前的安全网。

- [ ] **Step 1: 创建备份目录**

```bash
mkdir -p ~/.claude-backup/20260621/rules
mkdir -p "/d/projects/github/origin/apps/fifa2026/.claude-backup/20260621/rules"
```

- [ ] **Step 2: 拷贝用户级文件**

```bash
cp ~/.claude/CLAUDE.md ~/.claude-backup/20260621/CLAUDE.md
cp ~/.claude/rules/plugins.md ~/.claude-backup/20260621/rules/plugins.md
```

- [ ] **Step 3: 拷贝项目级文件**

```bash
cp "/d/projects/github/origin/apps/fifa2026/CLAUDE.md" "/d/projects/github/origin/apps/fifa2026/.claude-backup/20260621/CLAUDE.md"
cp "/d/projects/github/origin/apps/fifa2026/.claude/rules/vibe-workflow.md" "/d/projects/github/origin/apps/fifa2026/.claude-backup/20260621/rules/vibe-workflow.md"
```

- [ ] **Step 4: 验证备份完整（字节数对比）**

```bash
diff ~/.claude/CLAUDE.md ~/.claude-backup/20260621/CLAUDE.md
diff ~/.claude/rules/plugins.md ~/.claude-backup/20260621/rules/plugins.md
diff "/d/projects/github/origin/apps/fifa2026/CLAUDE.md" "/d/projects/github/origin/apps/fifa2026/.claude-backup/20260621/CLAUDE.md"
diff "/d/projects/github/origin/apps/fifa2026/.claude/rules/vibe-workflow.md" "/d/projects/github/origin/apps/fifa2026/.claude-backup/20260621/rules/vibe-workflow.md"
```

Expected: 4 个 `diff` 均无输出（无差异）

- [ ] **Step 5: 写 BACKUP_MANIFEST.md 和 RESTORE_COMMANDS.md，commit 无需 git（用户级目录非 git 仓库的部分跳过 commit，项目级改动走 Task 6 统一 commit）**

`BACKUP_MANIFEST.md`:
```markdown
# Backup Manifest 20260621

| 原文件 | 备份路径 |
|---|---|
| ~/.claude/CLAUDE.md | ~/.claude-backup/20260621/CLAUDE.md |
| ~/.claude/rules/plugins.md | ~/.claude-backup/20260621/rules/plugins.md |
| <repo>/CLAUDE.md | <repo>/.claude-backup/20260621/CLAUDE.md |
| <repo>/.claude/rules/vibe-workflow.md | <repo>/.claude-backup/20260621/rules/vibe-workflow.md |
```

`RESTORE_COMMANDS.md`:
```bash
# 恢复用户级
cp ~/.claude-backup/20260621/CLAUDE.md ~/.claude/CLAUDE.md
cp ~/.claude-backup/20260621/rules/plugins.md ~/.claude/rules/plugins.md

# 恢复项目级
cp "/d/projects/github/origin/apps/fifa2026/.claude-backup/20260621/CLAUDE.md" "/d/projects/github/origin/apps/fifa2026/CLAUDE.md"
cp "/d/projects/github/origin/apps/fifa2026/.claude-backup/20260621/rules/vibe-workflow.md" "/d/projects/github/origin/apps/fifa2026/.claude/rules/vibe-workflow.md"
# 若 Task 3 已创建 .claude/skills/vibe-workflow/，恢复后需手动删除该目录避免新旧并存
```

---

### Task 2: 精简 `~/.claude/rules/plugins.md`，详细说明搬到 archive

**Files:**
- Create: `~/.claude/archive/plugins-rationale.md`
- Modify: `~/.claude/rules/plugins.md`（全量替换为精简版）

**Interfaces:**
- Produces: `plugins.md` 只保留 plugin 清单表（常驻），详细原则/边界/操作说明移入 archive（按需读取，不进 context）。

- [ ] **Step 1: 创建 archive 目录并写入详细说明（原 plugins.md 中"选型原则/已知边界/常用操作"三节，逐字保留）**

```bash
mkdir -p ~/.claude/archive
```

写入 `~/.claude/archive/plugins-rationale.md`：
```markdown
# Plugin 选型与维护说明（详细版）

> 从 `~/.claude/rules/plugins.md` 拆出，按需查阅，不再常驻加载。
> 精简版清单见 `~/.claude/rules/plugins.md`。

## 选型原则

1. **按需安装，避免全家桶** — 业界共识（调研报告 §3.2），每个 plugin 都消耗 token（参考 `wshobson/agents`：1 个 plugin 装载 ≈ 1000 tokens）
2. **优先纪律性 > 工具性** — 纪律性 plugin（superpowers）让你做对的事，工具性 plugin（context7）让事做得快
3. **官方 `@claude-plugins-official` 优先** — Anthropic 维护，稳定性高
4. **检查 trigger 条件** — 装了但 CLAUDE.md 不触发 = 浪费 context

## 已知边界 / 冲突

- `superpowers` 与 `andrej-karpathy-skills` 在"工程原则"上有重叠（4 原则 vs systematic-debugging），由项目 CLAUDE.md 仲裁优先级
- `plugin-dev` 的 skill 在非 plugin 项目里基本不会 trigger，加载本身仍占 context（实测 ~1,566 tok，已禁用）
- 没有 plugin 应该改写 user CLAUDE.md 或 `~/.claude/settings.json`——若发生立即卸载

## 常用操作

```bash
# 列出当前装的 plugin
/plugin
claude plugin list

# 查看单个 plugin 的组件清单与 token 开销
claude plugin details <name>

# 禁用 / 启用（比卸载更安全，可随时恢复）
claude plugin disable <name>
claude plugin enable <name>

# 卸载
/plugin uninstall <name>@<marketplace>

# reload（无需重启 session）
/reload-plugins
```

实际配置见 `~/.claude/plugins/installed_plugins.json`。

## Token 实测记录（2026-06-21，`claude plugin details` 结果）

| Plugin | 状态 | Always-on token |
|---|---|---:|
| superpowers | 启用 | ~482 |
| claude-md-management | 启用 | ~121 |
| frontend-design | 启用 | ~54 |
| session-report | 启用 | ~48 |
| context7 | 启用 | ~0 |
| claude-hud | 启用 | ~0 |
| skill-creator | 禁用 | 0（启用后 75） |
| andrej-karpathy-skills | 禁用 | 0（启用后 64） |
| plugin-dev | 禁用 | 0（启用后 1,566） |
| github | 禁用 | 0 |
```

- [ ] **Step 2: 用精简版全量替换 `~/.claude/rules/plugins.md`**

```markdown
# Plugin 用途清单（user-level）

> 由 user-level `~/.claude/CLAUDE.md` 通过 `@import` 引用。
> 详细选型原则/已知边界/常用操作见 `~/.claude/archive/plugins-rationale.md`（按需查阅，不常驻）。
> 更新日期：2026-06-21

| Plugin | Tier | 触发场景 |
|---|---|---|
| `superpowers` | 必装 | 任何编码会话 |
| `claude-md-management` | 必装 | 改 CLAUDE.md / rules |
| `frontend-design` | 可选 | 前端项目（Next.js / React） |
| `context7` | 可选 | 查最新第三方 lib 文档 |
| `claude-hud` | 可选 | statusline 展示 |
| `session-report` | 可选 | 生成 session 用量报表 |
| `skill-creator` | 慎装（当前禁用） | 写自定义 skill 时再 enable |
| `andrej-karpathy-skills` | 慎装（当前禁用） | 强制 Karpathy 4 原则时再 enable |
| `plugin-dev` | 慎装（当前禁用） | 仅开发 Claude Code plugin 时 enable，token 开销最大 |
| `github` | 慎装（当前禁用） | 需要 gh Issue/PR 自动化时再 enable |
```

- [ ] **Step 3: 验证 — 行数下降且内容未丢失**

```bash
wc -l ~/.claude/rules/plugins.md
grep -c "选型原则" ~/.claude/archive/plugins-rationale.md
diff <(cat ~/.claude-backup/20260621/rules/plugins.md ~/.claude/archive/plugins-rationale.md) /dev/null || true
```

Expected: `plugins.md` 行数从 47 降到 ~15；`plugins-rationale.md` 包含"选型原则"字样（确认内容迁移成功）。

- [ ] **Step 4: Commit（用户级目录如果是 git 仓库）**

```bash
cd ~/.claude && git add rules/plugins.md archive/plugins-rationale.md && git commit -m "chore(claude-config): 精简 plugins.md，详细说明迁至 archive 按需查阅"
```

---

### Task 3: 项目 `CLAUDE.md` 去重"角色分工"表

**Files:**
- Modify: `D:\projects\github\origin\apps\fifa2026\CLAUDE.md`（替换"角色分工 / Model Hierarchy"整节）

**Interfaces:**
- Consumes: 用户级 `~/.claude/CLAUDE.md` §8 "Subagent Model Hierarchy" 表（已存在，作为唯一来源）
- Produces: 项目 CLAUDE.md 中该节缩短为单一引用句，硬性规则不丢失（仍在用户级 §8 中）

- [ ] **Step 1: 替换项目 CLAUDE.md 中的整节**

原文（待删除的完整内容）：
```markdown
## 角色分工 / Model Hierarchy（体制配置 — 严格遵守）

> 本节由用户 2026-06-17 明确要求固化进项目 `CLAUDE.md`，优先级高于 harness 默认。
> 派发子代理时 `Agent` 工具的 `model` 参数 **必须** 按下表显式指定——子代理不继承主会话模型。

| 角色 | 模型 | 职责范围 |
|---|---|---|
| **PM（主会话）** | `opus`（fable/opus，取当前所选，绝不降级） | 编排、决策、设计、评审仲裁、合并、可视化验收 |
| **Leader** | `opus` | 高判断任务：架构/设计评审、合并前终审 code-review、复杂根因分析 |
| **Worker — 长任务/复杂** | `sonnet` | 有集成或判断的开发/测试/运维：多文件实现、非平凡修复、实质性 diff 的规格/质量评审 |
| **Worker — 简单/轻量** | `haiku` | 仅调查与检索：Explore 搜索、事实查证、微小已验证 diff 复查、机械单文件编辑 |

**硬性规则：**
- 主会话只做 PM；**具体实现/调查任务必须按上表派发**，不在主会话里堆重活
- 每次 `Agent` 调用都要 **显式传 `model`**；缺省即违规
- worker 报 BLOCKED 且原因是推理力不足（非缺上下文）→ 上调一档重派（haiku→sonnet→opus）
- 例外（保持 INLINE，不派发）：紧密可视化迭代环（改 CSS→build→截图→验证→commit），冷启子代理重复读上下文反而更贵；以及需要持续共享状态的微小手术式编辑
- 关联记忆：`memory/delegate-tasks-to-cheaper-models.md`、`memory/role-hierarchy-strict.md`
```

替换为：
```markdown
## 角色分工 / Model Hierarchy

本项目严格执行用户级 `~/.claude/CLAUDE.md` §8「Subagent Model Hierarchy」的分工表与硬性规则，无项目级例外。
关联记忆：`memory/delegate-tasks-to-cheaper-models.md`、`memory/role-hierarchy-strict.md`
```

- [ ] **Step 2: 验证 — 用户级 §8 仍包含完整表格（单一来源未丢失）**

```bash
grep -A 8 "Subagent Model Hierarchy" ~/.claude/CLAUDE.md
```

Expected: 输出包含 PM/Leader/Worker 长任务/Worker 简单 四行角色表（确认单一来源完整存在）。

- [ ] **Step 3: 验证 — 项目 CLAUDE.md 行数下降**

```bash
wc -l "/d/projects/github/origin/apps/fifa2026/CLAUDE.md"
```

Expected: 从 64 行降到约 50 行。

- [ ] **Step 4: Commit**

```bash
cd "/d/projects/github/origin/apps/fifa2026"
git add CLAUDE.md
git commit -m "chore(claude-config): 角色分工表去重，单一来源指向用户级 CLAUDE.md §8"
```

---

### Task 4: `.claude/rules/vibe-workflow.md` 转为 `.claude/skills/vibe-workflow/SKILL.md`

**Files:**
- Create: `D:\projects\github\origin\apps\fifa2026\.claude\skills\vibe-workflow\SKILL.md`
- Modify: `D:\projects\github\origin\apps\fifa2026\CLAUDE.md`（"## Vibe Coding Workflow" 一节的引用方式）
- Delete（仅在 Task 5 验证通过后）: `D:\projects\github\origin\apps\fifa2026\.claude\rules\vibe-workflow.md`

**Interfaces:**
- Consumes: 原 `vibe-workflow.md` 全文（112 行，已在 Task 1 备份）
- Produces: 一个手动触发的 skill，内容与原 rule 逐字一致，仅追加 frontmatter

- [ ] **Step 1: 创建 SKILL.md，frontmatter + 原文件全文（仅去掉原文件首行 "> Imported by CLAUDE.md..." 说明，因为不再是 @import 关系）**

```markdown
---
name: vibe-workflow
description: Use when starting any new feature, task continuation, or bug fix in the fifa2026 project — enforces the mandatory Issue→brainstorming→spec→writing-plans→subagent-driven-development→verification→code-review chain, AUTONOMOUS_MODE behavior, milestone notifications, and subagent delegation rules. Do NOT rely on this being loaded automatically; it must be explicitly invoked via the Skill tool at the start of any new task in this project.
---

# Vibe Coding Workflow Rules

> These rules are non-negotiable for this project.

## 0. Autonomous Mode

AUTONOMOUS_MODE: true

When AUTONOMOUS_MODE is **true**:
- Skip all user-approval gates in brainstorming and writing-plans
- After spec self-review passes, directly invoke writing-plans without waiting for user confirmation
- After writing-plans completes, directly invoke **subagent-driven-development** (default execution mode — see §6) without waiting for user confirmation; fall back to `executing-plans` only if subagents are unavailable on the platform
- Post `[VIBE]` milestone notifications at: spec committed, implementation verified, PR created
- Do NOT wait for replies to `[VIBE]` notifications — continue executing immediately
- Stop only when PR is created (user merges manually)

When AUTONOMOUS_MODE is **false**:
- Pause after brainstorming spec and wait for user to confirm before invoking writing-plans
- Pause after writing-plans and wait for user to confirm before invoking executing-plans
- All other behavior identical to pre-flag state

## 1. Mandatory Skill Chain

Every new feature, task continuation, or bug fix MUST follow this chain in order.
Skipping steps is prohibited:

```
Issue 创建 → brainstorming → spec 文档 → writing-plans → subagent-driven-development
→ verification-before-completion → code-review
```

**Default execution mode = `subagent-driven-development`** (fresh subagent per task + review between tasks). Use `executing-plans` (inline) ONLY when the platform has no subagent support. See §6 for the delegation rules and guardrails.

**Hard gates:**
- Do NOT write any code before brainstorming is complete and spec self-review passes
  (AUTONOMOUS_MODE: true → proceed after self-review; false → require user approval)
- Do NOT merge before verification-before-completion runs against spec acceptance criteria
- Do NOT declare work "done" without running `code-review` skill

## 2. Issue-Driven Workflow

Before starting ANY task or bug fix, create a GitHub Issue:

```bash
# New feature
gh issue create --title "[FEAT] <feature name>" --body "Spec: docs/superpowers/specs/<date>-<name>-design.md"

# Continue existing task
gh issue create --title "[TASK] <task name>" --body "Resuming from: <last progress.md entry>"

# Bug fix
gh issue create --title "[BUG] <symptom>" --body "Repro: <steps>\n\nRoot cause (systematic-debugging output): <findings>"
```

Branch naming: `feat/<issue-number>-<short-slug>`, `fix/<issue-number>-<short-slug>`

PR body must include `Closes #<issue-number>` so the Issue auto-closes on merge.

## 3. Technical Autonomy

AI makes ALL technical decisions without asking the human:
- Library/framework selection
- Architecture patterns
- Performance tradeoffs
- Bug root-cause analysis

Record every significant technical decision in `progress.md` under "技术决策记录" with a one-line rationale. That is the only required human-readable artifact.

For bugs: always invoke `superpowers:systematic-debugging` skill before proposing any fix.

## 4. Memory Discipline

Update `progress.md` **immediately after each task or subtask completes** — do not batch updates to session end:
1. Mark the completed item with `[x]`
2. Update "当前状态" to reflect actual state (not the plan)
3. Add any new technical decisions to the decisions table
4. Advance "下一步" to reflect remaining work

The Stop hook auto-appends a session-end timestamp to `.claude/session-log.md` — this is a safety net audit trail, not a substitute for the above real-time updates.

## 5. Milestone Notifications

When AUTONOMOUS_MODE is true, post a `[VIBE]` notification at each milestone and immediately continue without waiting for a reply:

| Milestone | Message |
|-----------|---------|
| Spec committed to git | `[VIBE] spec 已完成 → docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` |
| verification-before-completion passed | `[VIBE] 实现完成 → commit <sha>，所有验收标准通过` |
| PR created | `[VIBE] PR ready → #<N> <title> — 待你 merge` |

## 6. Subagent Delegation (default-on)

This project **opts in** to aggressive delegation. This standing instruction overrides
the harness default of "don't spawn agents unless asked" — treat the cases below as
the user having already asked. Always tell each subagent **"return a summary only, not
raw output"** so the main session stays lean.

**MUST delegate to a subagent (return summary only):**
- **Plan execution** → `subagent-driven-development`: one fresh subagent per plan task, review between tasks (this is the default executor, per §1).
- **Investigation / exploration** → `Explore` (or `general-purpose`): any Phase-1 codebase investigation, OR any search/read that spans **≥3 files**. Do NOT fan out broad reads in the main session — dispatch and consume the summary.
- **Heavy output** → subagent: long logs, large search dumps, full-file reads done only to research. The main session receives conclusions, not the dump.
- **Code review** → `code-reviewer` (already part of the §1 chain). Scope its diff to the change under review, not the whole branch, to keep its token cost down.
- **2+ independent, parallelizable tasks** → `dispatching-parallel-agents`.

**Guardrail — keep INLINE in the main session (do NOT delegate):**
- Tight iterative loops: edit → build → screenshot → verify → commit. Cold subagents
  re-derive context every spawn and cost MORE than they save here.
- Small / surgical single-file edits, and anything needing continuous shared state.

**Rationale:** delegation buys context hygiene + parallelism, NOT lower token cost
(cold spawns re-read context; with high cache hit the warm main thread is cheaper).
Delegate for the cases above; stay inline for everything else.
```

- [ ] **Step 2: 修改项目 CLAUDE.md 的 "## Vibe Coding Workflow" 一节**

原文：
```markdown
## Vibe Coding Workflow

@.claude/rules/vibe-workflow.md
```

替换为：
```markdown
## Vibe Coding Workflow

完整自主实现流程（Issue 驱动、AUTONOMOUS_MODE、里程碑通知、子代理委派规则）已迁移为手动触发的 skill，**不再常驻加载**。任何新功能/任务延续/bug fix 开始前，必须显式调用 `vibe-workflow` skill（Skill 工具，skill 名 `vibe-workflow`）。
```

- [ ] **Step 3: 验证 — SKILL.md 内容与备份逐字一致（除 frontmatter 和首行说明外）**

```bash
diff <(tail -n +5 ~/.claude-backup/20260621/rules/vibe-workflow.md 2>/dev/null || tail -n +5 "/d/projects/github/origin/apps/fifa2026/.claude-backup/20260621/rules/vibe-workflow.md") \
     <(tail -n +6 "/d/projects/github/origin/apps/fifa2026/.claude/skills/vibe-workflow/SKILL.md")
```

Expected: 无实质差异（允许首行标题措辞微调，因为不再是 @import 关系）

- [ ] **Step 4: 删除原 rule 文件（确认 SKILL.md 验证通过后）**

```bash
rm "/d/projects/github/origin/apps/fifa2026/.claude/rules/vibe-workflow.md"
```

- [ ] **Step 5: 验证 — 项目 CLAUDE.md 总行数下降**

```bash
wc -l "/d/projects/github/origin/apps/fifa2026/CLAUDE.md"
```

Expected: 较 Task 3 完成后再下降（不再 @import 112 行）

- [ ] **Step 6: Commit**

```bash
cd "/d/projects/github/origin/apps/fifa2026"
git add CLAUDE.md .claude/skills/vibe-workflow/SKILL.md
git rm .claude/rules/vibe-workflow.md
git commit -m "refactor(claude-config): vibe-workflow 规则转为按需触发 skill，不再常驻加载"
```

---

### Task 5: 澄清仓库内 `memory/` 与 harness 自动 memory 的分工（小改动，不搬移内容）

**Files:**
- Modify: `D:\projects\github\origin\apps\fifa2026\CLAUDE.md`（"## Session Continuity" 一节追加一行说明）

**Interfaces:**
- Consumes: 无代码依赖，纯文档说明
- Produces: 避免未来在两套 memory 系统里重复记录同一事实

- [ ] **Step 1: 在 "## Session Continuity" 节追加说明行**

原文：
```markdown
## Session Continuity

- `progress.md` — current task state (single source of truth)
- `memory/` — cross-session preferences and external resource pointers
- Heavy output (logs, large searches) goes to a subagent; main session receives summaries only
```

替换为：
```markdown
## Session Continuity

- `progress.md` — current task state (single source of truth)
- `memory/`（仓库内，人工维护）— 给非 Claude 工具链/人类阅读的跨会话偏好与外部资源指针
- harness 自动 memory（`~/.claude/projects/<hash>/memory/`，Claude 自动维护）— 给 Claude 跨会话自动召回；新增事实优先写这里，仓库内 `memory/` 只放需要人工可读或团队共享的内容，避免两处重复记录同一事实
- Heavy output (logs, large searches) goes to a subagent; main session receives summaries only
```

- [ ] **Step 2: 验证**

```bash
grep -A 5 "Session Continuity" "/d/projects/github/origin/apps/fifa2026/CLAUDE.md"
```

Expected: 输出包含新增的"harness 自动 memory"说明行

- [ ] **Step 3: Commit**

```bash
cd "/d/projects/github/origin/apps/fifa2026"
git add CLAUDE.md
git commit -m "docs(claude-config): 澄清仓库内 memory/ 与 harness 自动 memory 的分工边界"
```

---

### Task 6: 优化后整体验证 + 写回审计文档对比表

**Files:**
- Modify: `~/.claude/docs/context-optimization/2026-06-21-audit.md`（追加"优化后对比"一节）

**Interfaces:**
- Consumes: Task 1-5 全部完成
- Produces: 优化前后对比表，写入审计文档，作为本次工作的最终交付记录

- [ ] **Step 1: 重新统计行数**

```bash
echo "用户级:"; wc -l ~/.claude/CLAUDE.md ~/.claude/rules/plugins.md
echo "项目级:"; wc -l "/d/projects/github/origin/apps/fifa2026/CLAUDE.md"
find "/d/projects/github/origin/apps/fifa2026/.claude/rules" -type f 2>/dev/null
find "/d/projects/github/origin/apps/fifa2026/.claude/skills" -type f 2>/dev/null
```

Expected: `vibe-workflow.md` 不再出现在 `.claude/rules/` 下；出现在 `.claude/skills/vibe-workflow/SKILL.md`

- [ ] **Step 2: 重新确认 plugin 状态未变（本次改造不涉及 plugin 启停）**

```bash
claude plugin list
```

Expected: 与审计时一致（6 启用 / 4 禁用）

- [ ] **Step 3: 在审计文档追加对比表**

在 `2026-06-21-audit.md` 末尾追加：
```markdown
## 7. 优化后对比（执行完 Task 1-5 后填写）

| 项目 | 优化前 | 优化后 | 变化 |
|---|---:|---:|---:|
| 用户 CLAUDE.md 行数 | 137 | <实测> | <差值> |
| 用户 plugins.md 行数 | 47 | <实测> | <差值> |
| 项目 CLAUDE.md 行数 | 64 | <实测> | <差值> |
| 项目常驻 rules 行数 | 112（vibe-workflow） | 0（已转 skill） | -112 |
| 估算常驻 token 总量 | ~6,800 | <重新估算> | <差值> |
```

- [ ] **Step 4: Commit（仅用户级，无 git 仓库则跳过 commit，文件已落盘即可）**

```bash
cd ~/.claude && git add docs/context-optimization/2026-06-21-audit.md 2>/dev/null && git commit -m "docs(claude-config): 记录配置优化前后对比" 2>/dev/null || true
```

---

## Self-Review

1. **覆盖度检查**：审计中识别的 4 个高/中优先级问题（plugins.md 冗长、角色分工重复、vibe-workflow 常驻、双 memory 系统）→ 分别对应 Task 2、Task 3、Task 4、Task 5。低优先级问题（用户级 CLAUDE.md 整体重排）未单独建任务，按审计文档"低优先级"标注暂不处理，留待后续单独评估。
2. **占位符检查**：全文无 "TBD/implement later/add appropriate" 等占位表述，所有替换内容均为完整逐字文本。
3. **路径一致性检查**：所有文件路径在 Task 1（备份）、Task 3/4/5（修改）中保持一致；`vibe-workflow` skill 名在 Task 4 Step 1 frontmatter 与 Step 2 CLAUDE.md 引用文字中一致。

## 风险提示（执行前请用户确认）

1. Task 4 把 vibe-workflow 从"无条件常驻"改为"需要显式触发"——如果未来某次任务开始时忘记调用该 skill，AUTONOMOUS_MODE 等规则不会自动生效。
2. Task 3 删除项目级角色分工表后，项目专属的模型分工例外（如果将来需要）必须显式在项目 CLAUDE.md 写补充条款，而不能依赖整表覆盖。
3. 所有改动均有备份（Task 1）且通过 git 提交（可 revert），风险可控。
