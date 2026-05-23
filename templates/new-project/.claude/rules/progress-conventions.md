---
paths:
  - "progress.md"
  - "PROGRESS*.md"
---

# PROGRESS / 文档维护规约 + 关键索引

> **加载**: path-scoped（仅在读写 `progress.md` / `PROGRESS*.md` 时载入，不进 session baseline）
> **核心理念**: PROGRESS 三件套——主文件 + done 归档 + roadmap，按生命周期分层

---

## 🔍 快速查找（给下个 Claude / 同事）

读完主 [`progress.md`](../../progress.md) + `CLAUDE.md` 就能接力。

| 问题 | 看哪段 / 哪文件 |
|---|---|
| 下一步做什么? | 主 PROGRESS §🔄 当前进行中 + §🔴 待做 |
| 哪些等我决策? | 主 PROGRESS §👤 等用户决策 |
| 哪些等我验收? | 主 PROGRESS §🟡 已 merge 待验收 |
| 已闭环 sprint / 决策 | `PROGRESS_done.md`（按需创建） |
| 未来 roadmap / GA 后 | `PROGRESS_roadmap.md`（按需创建） |
| 历史做过啥? | 主 PROGRESS §🔄 完成的转 PROGRESS_done + commit log |
| 架构契约 / 规约? | 本 `.claude/rules/` 各 sub-file + 主 `CLAUDE.md` + `design/` |
| 全文档导航 | `docs/INDEX.md`（按需创建） |
| 事故复盘 | [`docs/postmortems/README.md`](../../docs/postmortems/README.md)（按需创建） |

---

## 📐 PM 维护流程

### 每完成一个 sprint —— 源自 [`git-workflow.md §7.7`](git-workflow.md)

完整流程（sprint 分支末尾 commit progress.md → `--no-ff` merge → pre-merge 自检清单 → chore.progress 例外路径）见 [`git-workflow.md §7.7`](git-workflow.md)。

本文件**不重复**那段，只列 PROGRESS 维护的**专属约定**（git-workflow.md 不涉及的）：

- **§🟡 待用户验收**：用户验收后划掉一行；PM 在下次 chore 加 `✅` 前缀；满 20 项触发归档（见下方 §"滚动归档触发"）
- **§👤 等用户决策**：仅 PROGRESS 用，git-workflow.md 不涉及

### 滚动归档触发（保持主 PROGRESS < 200 行）

**自动触发条件**（任一满足时，PM 在下一次 chore 顺手归档）:
- 主 `progress.md` > **250 行**
- 主 PROGRESS §✅ 或 §🟡 完成项 > **20 项**
- 顶层 `docs/` 含 > **5 个** `YYYY-MM-DD_*.md` 未入月份目录

**归档动作**:
1. §✅ 已完成 sprint history → 移入 `PROGRESS_done.md` §已完成 sprint（日期倒序保留）
2. §🟡 已带 ✅ PM auto-verified → 移入 PROGRESS_done §已 verified
3. §🔴 ~~划掉~~ 已 done polish → 移入 PROGRESS_done §已完成 polish
4. §👤 已落地决策 → 移入 PROGRESS_done §已落地决策
5. 顶层 docs/ 单 doc → `git mv docs/YYYY-MM-DD_*.md docs/YYYY-MM/`
6. 主 `progress.md` 保持 **< 200 行**（超 250 自动触发下次归档）

### 新 sprint 启动时

1. **必先** `gh issue create`（per [git-workflow.md §7.9](git-workflow.md) Issue-First gate）
2. `git checkout -b [MAIN_BRANCH].<topic>`（从主线起）
3. 主 `progress.md` §🔄 加 sprint 简版（name / 范围 / 阶段=design / Blockers）
4. 设计文档单独 commit 到 sprint 分支（不进 `progress.md`）

### 用户验收一项后

- 主 PROGRESS §🟡 划掉那行 → 或 PM 在下次 chore 加 ✅ 前缀 → 满 20 项归档

### 完整团队编排（详 [`team-orchestration.md`](team-orchestration.md)）

- 必经双签：Code Reviewer + Tester
- 按需追加签字：Security / Reality Checker / SRE 等（per 触发决策表）

### Sub-agent 派发原则

- PM 主线跑长任务（pytest 全量 / docker build）：避免 subagent token 限制中途卡
- Subagent 只做实装 + 局部测试；不跑 pytest 全量
- 重构涉及 module-level 符号迁移必须同步迁移测试 `monkeypatch.setattr("module.symbol")` path
- 并发 agent 显式 base 隔离；agent prompt 起手 `git fetch && git checkout [MAIN_BRANCH]`（防 stale base bug）
- 派 future doc agent 必须含 sprint 完成清单 prerequisite
- bug 诊断必须看完整 traceback / response body
- Tester subagent 报 bug 用 `gh issue create` 自动建 issue（详 git-workflow.md §7.9）

---

## 🚦 优先级图标

| 图标 | 含义 |
|---|---|
| 🔥 | 阻塞下个 sprint（PM 不能跳过）|
| ⚡ | 等用户决策才能继续 |
| ⏳ | PM 可独立做（不影响其他）|
| 🧹 | polish 可选（不影响功能）|

---

## 🗂️ 关键文档索引

**常用 link**:

| 主题 | 路径 |
|---|---|
| 项目约定（主）| `<repo>/CLAUDE.md` |
| 派 agent / 团队编排 | `.claude/rules/team-orchestration.md` |
| Git workflow / Issue-First | `.claude/rules/git-workflow.md` |
| 设计契约 / 技术栈 / 测试 | `.claude/rules/project-context.md` |
| 行为 4 原则（karpathy）| `.claude/rules/behavioral-rules.md` |
| docs/ 命名规约（path-scoped）| `.claude/rules/docs-conventions.md` |
| 架构政策 | `.claude/rules/architecture-policies.md` |
| 历次 sprint 设计 | `docs/<YYYYMMDD>/` 各 sprint 专辑 |
| 运维 runbook | `docs/admin_runbook.md`（如有）|
| 事故复盘 | `docs/postmortems/`（如有）|
| 月份归档单 doc | `docs/YYYY-MM/` |

---

> 📌 **Maintainer 注**：本文件描述 PROGRESS 三件套维护方式。修改本文件 = `.claude/rules/` 改动（per `git-workflow.md §7.9`）→ 必先开 issue + chore 分支。
