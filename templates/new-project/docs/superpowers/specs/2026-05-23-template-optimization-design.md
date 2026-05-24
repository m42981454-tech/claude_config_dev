# Template Optimization — Phase 2 Design

> **Refs**: 本次会话 review (无 issue, n/a)
> **Date**: 2026-05-23
> **Status**: Implemented（2026-05-24 更新；部分后续项按用户决策暂停）
> **Cross-ref**: T1（已撤销 docs 误删）/ T2 / T4 / T5 / T6（已完成）/ T7（本 doc §2）

---

## 0. TL;DR

本 doc 锁定模板优化"Phase 2"的两件事：
1. **`.claudeignore` 扩展** —— 让模板自身的历史 spec / postmortem / 设计履历**保留在源里**（修正履历不灭），但在新项目工作时 Claude 不去读它们（不污染 context）。
2. **T7 保守去重 rules** —— `behavioral-rules.md` 与 `git-workflow.md`、`progress-conventions.md` 与 `git-workflow.md §7.7` 有大段字面重复；只删纯重复段、加 link，**不改变规约信息密度**。

执行前需用户拍板本 doc，否则不动。

---

## 1. 背景

### 1.1 已发生

| 任务 | 状态 |
|---|---|
| T1（误删 docs 历史） | ❌ 已撤销，git checkout 恢复 |
| T2（修 `stack-*.md` `cd` bug）| ✅ 完成 |
| T4（`validate.sh` + `.ps1` + SETUP Step 6）| ✅ 完成 |
| T5（hook 跨平台健壮性）| ✅ 完成 |
| T6（`init.sh` / `init.md` / `settings.json` 同步）| ✅ 完成 |
| T7（保守去重 rules）| ✅ 完成 |

### 1.2 用户原则

- **模板是长期维护项目**，历史 spec / 演化履历是资产，不在源头删
- **不丢精度** —— 规约的细节、纪律、4 channel 等沉淀经验全部保留
- **新项目体感清洁** —— 用户拿 init.sh 初始化完，应该看不到一堆别项目的历史 spec 污染 Claude context

---

## 2. §1 设计 —— `.claudeignore` 扩展

### 2.1 现状

`templates/new-project/.claudeignore` 当前内容：

```
# Template maintenance reference, not project working context.
docs/claude-code-best-practices.md
docs/bak
```

只排除了 best-practices 静态参考 + bak 目录（bak 实际已不在模板，可移除条目或保留作为预防）。

### 2.2 扩展后

```
# === Template maintenance reference — not project working context ===
# These paths exist in the template repo as evolution history / design provenance.
# Claude Code should NOT read them when working on a derived project; they would
# inject stale design decisions or unrelated topics into context.

# Static reference docs（模板维护者参考用）
docs/claude-code-best-practices.md

# Template evolution specs（模板自身演化设计履历，每次模板大改沉淀一份）
docs/superpowers/specs/

# Legacy backups（历史 agent / 模板备份，保留作 audit trail）
docs/bak/
```

### 2.3 关键问题与权衡

**问题**: `.claudeignore` 语义是"Claude 读取排除"，不是"init 复制排除"。新项目初始化后**文件仍然存在于硬盘**，只是 Claude 不去读。

**这是缺点还是特性？**

- **特性视角**：用户在新项目目录下做 `git log -- docs/superpowers/specs/` 仍能看到模板演化历史，这对"为什么模板这么设计"的考古很有价值。
- **缺点视角**：新项目用户的硬盘多了几 KB 不属于自己项目的文件，可能 `git grep` 时碰到。
- **裁决**：选 .claudeignore 而非 init 排除复制 —— **模板演化履历对新项目仍有 audit 价值**，用 .claudeignore 关 context 注入即可。若个别用户想清洁删除，直接 `rm -rf docs/superpowers/specs/` 不影响任何模板功能。

### 2.4 是否要让 `/project:init` / `init.sh` 主动告知用户？

**推荐**：是。在 init 完成后输出加一句：

```
ℹ️  模板自带的 docs/superpowers/specs/ 和 docs/bak/ 是模板演化履历，
   已被 .claudeignore 排除，不会污染 Claude context。
   如需彻底删除，可手动 rm -rf 这些目录。
```

### 2.5 落地动作（共 2 处文件改动）

| # | 文件 | 改动 |
|---|---|---|
| 1 | `.claudeignore` | 按 §2.2 替换 |
| 2 | `.claude/commands/project/init.md` | Step 5（完成后提示用户）末尾加 §2.4 那段说明 |

`init.sh` 因为 echo 输出已经够长，本次不再扩展（保持脚本聚焦）。

### 2.6 风险

- 若用户用非 Claude Code 工具（Cursor / Copilot）读项目，`.claudeignore` 对它们无效 → 这些工具会读到历史 spec。但模板预期用户就是 Claude Code 用户，风险可控。
- `docs/superpowers/specs/` 未来若放**新项目自己的** spec（不是模板演化的），会被一并排除 → 设计上**冲突**。

**对 §2.6 第二点的解法**：模板演化 spec 用 **`docs/_template-evolution/`** 这种专属目录，与新项目自己的 spec 分离。但这要求改目录结构，破坏既有 commit 历史 follow（git mv 可解）。

**裁决**：先按 §2.5 落地（最小改动），未来若新项目真有 `docs/superpowers/specs/` 写需求，再做目录重构。

---

## 3. §2 设计 —— T7 保守去重 rules

### 3.1 重复点定位

通过 review 确认 3 处大段字面重复：

| # | 位置 A | 位置 B | 重复内容 |
|---|---|---|---|
| **D1** | `behavioral-rules.md` 全文（约 25 行）| `git-workflow.md` 多节 | "不直接 commit 主线" / "不绕 hook" / "不 push 远端" / "不 amend 已 merge" / "sprint merge 后不更新 PROGRESS" 等 5 条 git workflow DON'T |
| **D2** | `progress-conventions.md` §"每完成一个 sprint"（约 30 行）| `git-workflow.md §7.7` PROGRESS 维护流程（约 50 行）| sprint 分支末尾 commit progress.md → merge / pre-merge 自检清单 / chore.progress 例外路径 / 滚动归档触发 |
| **D3** | `team-orchestration.md §2.7` 派单模板入口（约 15 行）| `.claude/skills/my-dispatch-templates/SKILL.md` | "subagent_type Title Case" / "model 锁定原则" / "派单标准模板"  |

### 3.2 单一真源定案

| 主题 | 真源 | 其它位置只允许做 |
|---|---|---|
| Git workflow DON'T 清单 | `git-workflow.md` | `behavioral-rules.md` 列**摘要**（一句话 + link）|
| PROGRESS 维护流程 | `git-workflow.md §7.7` | `progress-conventions.md` 列**触发点 + link 到 git-workflow.md** |
| 派单模板代码块 | `skill my-dispatch-templates` | `team-orchestration.md §2.7` 列**入口指针 + 命名约定**（已经是这样了，确认不动）|

**关键**：单一真源选 `git-workflow.md` 而非 `behavioral-rules.md` 的原因 —— git workflow 内容更结构化、`git-workflow.md` 已经是大段 source-of-truth；`behavioral-rules.md` 体量小、更适合做"门面 + 摘要 + link"。

### 3.3 具体改动

#### 3.3.1 `behavioral-rules.md` 改动

**前**（当前文件 25 行，含 11 条 DON'T，其中 5 条与 git workflow 强重叠）：

```markdown
- ❌ 不删除既有测试或用 @pytest.mark.skip / test.skip 绕过失败
- ❌ 不绕过 hooks（--no-verify / --no-gpg-sign / commit.gpgsign=false）
- ❌ 不在主线 Opus（PM）上做编码工作——派给 Sonnet Implementer
- ❌ Tester 不修代码,只报 bug 给 PM；修代码必须经 Implementer + Review
- ❌ 不直接 commit 到主线（[MAIN_BRANCH]）——所有改动必须先开子分支，详见 [.claude/rules/git-workflow.md §7.2]
- ❌ 不代替人工 merge 到主线（[MAIN_BRANCH]）——向主线的 merge 为人工专属操作；AI 收到此类请求时必须拒绝并提示用户手动执行（H1 hook 会拦截）
- ❌ sprint merge 后不更新 PROGRESS.md 就开始下个 sprint——必须紧接着走 chore 分支同步 PROGRESS.md，详见 [.claude/rules/git-workflow.md §7.7]
- ❌ 不在 UI / API 变更后留下持续刷新的 console error 循环
- ❌ 不在修复聚焦问题时顺手做大范围重构（per §10 surgical changes）
- ❌ 不 push 远端（除非用户明确要求）
```

**后**（精简到 9 行，分两组）：

```markdown
## 8.1 通用行为（本文件 source of truth）

- ❌ 不删除既有测试或用 `@pytest.mark.skip` / `test.skip` 绕过失败
- ❌ 不在主线 Opus（PM）上做编码工作——派给 Sonnet Implementer
- ❌ Tester 不修代码,只报 bug 给 PM；修代码必须经 Implementer + Review
- ❌ 不在 UI / API 变更后留下持续刷新的 console error 循环
- ❌ 不在修复聚焦问题时顺手做大范围重构（per `engineering.md` §3 Surgical Changes）

## 8.2 Git Workflow DON'T 摘要（详见 [`git-workflow.md`](git-workflow.md)）

git workflow 类 DON'T（不绕 hook / 不直接 commit 主线 / 不 AI merge 主线 / 不 push / 不 amend rewrite）在 [`git-workflow.md §7.2-§7.3 + §7.7`](git-workflow.md) 列**完整规约**。

本节作摘要：
- ❌ 不绕过 hooks / 不直接 commit 主线 / 不 AI merge 主线 / 不 push 远端（详 §7.2-7.3）
- ❌ sprint merge 前必更新 progress.md 作为最后一个 commit（详 §7.7）
```

**信息密度**：每条规约的"why / how" 在 git-workflow.md 完整保留；本文件只剩门面 + 跳转，**不丢任何细节**。

#### 3.3.2 `progress-conventions.md` 改动

**当前**：§"每完成一个 sprint" 整段约 30 行，重复 git-workflow.md §7.7 流程 + pre-merge 自检 + 例外路径。

**改动**：把这一段替换为：

```markdown
### 每完成一个 sprint —— **源自 [`git-workflow.md §7.7`](git-workflow.md)**

完整流程（sprint 分支末尾 commit progress.md → `--no-ff` merge → pre-merge 自检 → chore.progress 例外）见 [`git-workflow.md §7.7`](git-workflow.md)。

本文件**不重复**那段，只列 PROGRESS 维护的两条**专属约定**（git-workflow.md 不涉及的）：

- §🟡 待用户验收：用户验收后划掉，PM 在下次 chore 加 ✅ 前缀
- 满 20 项归档：触发条件见下方 §"滚动归档触发"
```

§"滚动归档触发" 段（行 ~60 起）**保留不动** —— 那是 progress-conventions.md 独有内容（git-workflow.md 不涉及归档）。

#### 3.3.3 `team-orchestration.md §2.7` —— 已经是 link 入口，不动

确认现状已是"派单模板代码块见 skill"形态。本次不改。

### 3.4 不改的（保精度）

- `engineering.md`（karpathy 4 原则）—— 独立内容，无重复
- `architecture-policies.md` —— 独立内容
- `project-context.md` —— 独立内容
- `docs-conventions.md` —— 独立内容
- `skill-promotion-path.md` —— 独立内容
- `team-orchestration.md` 主体（§2.1-§2.6）—— 独立内容
- `git-workflow.md` 全文 —— 是 source of truth，不动

### 3.5 验证策略

T7 完成后跑 `validate.sh`：
- 必需文件齐全 ✅
- rules 内部 link 完整性 → 重点验证 behavioral-rules.md → git-workflow.md，progress-conventions.md → git-workflow.md 的相对 link 不死

---

## 4. 验收清单（执行后)

- [x] `.claudeignore` 含新增 template maintenance reference pattern
- [x] `init.md` Step 5 含 §2.4 那段提示
- [x] `behavioral-rules.md` 已压缩为摘要 + source-of-truth link
- [x] `progress-conventions.md` 已去除与 `git-workflow.md §7.7` 的重复流程
- [x] `validate.sh` / `validate.ps1` 已存在，并在端到端 dry-run 中验证通过
- [x] 未删除既有 rule 文件
- [x] `git-workflow.md` source-of-truth 语义未被压缩

---

## 5. 后续（不在本期）

- §2.6 提到的 `docs/_template-evolution/` 目录重构 —— 等首个新项目用户真正在 `docs/superpowers/specs/` 写自己的 spec 时再做
- 三档梯度模板（minimal / standard / full）—— 用户已明确不丢精度，不做

---

---

## 6. Phase 3 设计 —— #11 + #13（追加于 §1/§2 实施后）

### 6.1 §3 设计 —— #11 agent/skill 默认 disabled

#### 6.1.1 现状

- `.claude/agents/` 预装 8 个 `.md` 文件（agents-orchestrator / api-tester / backend-architect / database-optimizer / frontend-developer / project-management-jira-workflow-steward / reality-checker / security-engineer）
- Claude Code 看到 `.claude/agents/*.md` 即自动 register 为可用 agent，**无 frontmatter disable 机制**
- `.enabled.example` 已存在（列完整候选清单，含上面 8 个）
- `.enabled` 不存在（agent-loader.sh 见到此文件不存在就 `exit 0`）
- agent-loader.sh 只负责从 user-level pool **额外**拉 agent，不影响预装 8 个

**当时结论**：当时实际状态 = 8 个 agent **永远 active**（与 plugins.md "按需安装"哲学冲突）。

**2026-05-24 更新**：该问题已通过 `_available/` 目录落地解决；模板 agent 默认 disabled，只有复制到 `.claude/agents/` 或通过 `.enabled` 才激活。

#### 6.1.2 三种实现机制对照

| 方案 | 做法 | 资产保留? | 改动成本 | 默认体验 |
|---|---|---|---|---|
| **A. 移到 `_available/` 子目录** | 8 个 `.md` 从 `.claude/agents/` 移到 `.claude/agents/_available/`；Claude Code 不递归注册下划线开头子目录 | ✅ 文件仍在模板里 | 中（一次 git mv + 改文档） | 用户进新项目：0 agent active；按需 cp 出来 |
| **B. 改后缀 `.md.disabled`** | 8 个 `.md` 改名 `.md.disabled`，Claude Code 不识别该后缀 | ✅ 文件仍在 | 低（rename） | 同 A，但目录看着乱（混 .md 和 .md.disabled） |
| **C. 完全删除预装，靠 agent-loader 从 user pool 拉** | 删 8 个 `.md`；用户在 `.enabled` 列出想要的 → SessionStart H5 hook 从 pool 复制 | ❌ 模板源里删除 | 中 | 用户必须有 user-level pool；新机器初次 broken |

#### 6.1.3 推荐 Variant A（_available 子目录）

**理由**：
- 模板资产保留（用户原则"不丢精度"）
- 不依赖外部 pool（C 的隐性依赖坑）
- 下划线前缀 `_available/` 表"内部目录"约定（git / npm / Python 都通用）
- 用户体验：`cp .claude/agents/_available/api-tester.md .claude/agents/` 一行启用，超直观

#### 6.1.4 落地动作

1. **建目录** `.claude/agents/_available/`
2. **git mv** 8 个 `.md` 进 `_available/`
3. **建 `.claude/agents/README.md`**（约 30 行）说明：
   - 此目录下任何 `.md` 都会被 Claude Code 注册为可用 agent
   - 预装 agent 已搬到 `_available/`（默认 disabled）
   - 启用方式 1：`cp _available/<name>.md ./`
   - 启用方式 2：在 `.enabled` 列出 agent 名（由 SessionStart agent-loader 从 user pool 自动拉，不依赖 `_available/`）
   - 推荐组合见 `.enabled.example`
4. **修 `.enabled.example` 注释**：现有 `# === L3 项目模板默认角色：已随 new-project 模板放入 .claude/agents/ ===` 这条不再准确（已搬到 `_available/`），改为：

   ```
   # === L3 项目模板预装角色：源文件位于 .claude/agents/_available/ ===
   # === 启用方式：cp _available/<name>.md ./ 或在本文件取消注释让 agent-loader 拉 ===
   ```
5. **`/project:init` Step 5** 完成提示加一行：

   ```
   📦 模板预装 8 个 agent 在 .claude/agents/_available/（默认 disabled）。
      按需 cp 想用的到 .claude/agents/，或编辑 .enabled。
   ```
6. **不动 agent-loader.sh** — 它处理 `.enabled` 文件本来就 OK，预装 .md 搬走对它无影响

#### 6.1.5 skill 是否同样处理？

**不做**。理由：
- `.claude/skills/` 7 个 skill 都是 `my-*` 前缀，**项目专属**（不是通用工具）
- Skills 不像 agents 那样"扩大工具面"，只在被显式 invoke 时才 load
- 预装 skill 不构成 context 负担
- skill 自定义的 SKILL.md 体量也小（< 100 行）

skill 默认全装是合理的，与 #11 哲学不冲突。

#### 6.1.6 风险

- 若有用户在 git history 里 `git log -- .claude/agents/api-tester.md` follow 旧路径 → git 会自动 follow rename，无破坏
- 若用户在自定义 hook 或 script 中 hardcode `.claude/agents/api-tester.md` → 会失效（不太可能但要扫）
- 验证策略：grep 整个模板找 `.claude/agents/<name>.md` 引用

### 6.2 §4 设计 —— #13 4 处 pre-existing 死链 polish

#### 6.2.1 死链清单（validate.sh 输出）

```
.claude/rules/docs-conventions.md → ../foo.md
.claude/rules/progress-conventions.md → ../../PROGRESS_done.md
.claude/rules/progress-conventions.md → ../../PROGRESS_roadmap.md
.claude/rules/progress-conventions.md → ../../docs/INDEX.md
```

#### 6.2.2 改动

| 文件 | 原 markdown link | 改为 inline code |
|---|---|---|
| `docs-conventions.md` | `[../foo.md](../foo.md)` | `` `../foo.md` ``（§1.4 命名反模式示例） |
| `progress-conventions.md` | `[\`PROGRESS_done.md\`](../../PROGRESS_done.md)（按需创建）` | `` `PROGRESS_done.md`（按需创建） `` |
| `progress-conventions.md` | 同上 PROGRESS_roadmap | 同上模式 |
| `progress-conventions.md` | 同上 docs/INDEX.md | 同上模式 |

**核心原则**：示例性引用（"按需创建"的文件、命名反模式举例）不应该是 markdown link —— link 暗示"该文件存在"，但实际是文档约定 / 占位概念。改 inline code 表"这是个文件名概念，不是实际链接"。

#### 6.2.3 不影响

- 信息密度：0 损失（文件名 / 概念照旧表达）
- 用户体验：可读性略提升（不会误点死链）
- validate.sh：未来 init 后跑 → rules 内部 link 全部有效

### 6.3 Phase 3 验收清单

- [x] `.claude/agents/_available/` 含 8 个 `.md` 文件
- [x] `.claude/agents/` 根仅含 `.enabled.example` + 新建 `README.md`
- [x] `.enabled.example` 注释文字更新（已搬 `_available/`）
- [x] `/project:init` Step 5 含预装目录说明
- [x] 4 处死链全部消除（grep 找不到对应 markdown link 语法）
- [x] validate 脚本可检查 rules 内部链接有效性
- [x] grep 全模板：无 `.claude/agents/<name>.md` 硬编码引用残留

### 6.4 实施状态（2026-05-24 更新）

本设计的模板优化主线已经完成。`validate.sh` 和 `validate.ps1` 保留为必要的跨平台验证入口：

- `validate.sh` 覆盖 Ubuntu、Git Bash 和 shell 场景。
- `validate.ps1` 覆盖 Windows PowerShell，并能检查 `bash` 是否错误解析到 WSL launcher。
- 两者只在显式运行时产生输出，不进入 Claude Code session baseline。
- 之前端到端 dry-run 暴露的问题（hook 路径、占位符残留、Windows shell 差异）都依赖这类验证脚本闭环。

仍有意暂停的事项：

- 完整 statusLine `light/hud` 模式切换。
- new-project template statusLine 同步。
- 插件自动化启用策略。
- 大范围 agent prompt 瘦身。

---

## Sources / 参考

- 本次会话 review 输出
- T3 占位符审计报告（subagent agentId 见 conversation history）
- 模板既有 `git-workflow.md`、`behavioral-rules.md`、`progress-conventions.md` 当前内容
- Phase 3 验收 by validate.sh dry-run
