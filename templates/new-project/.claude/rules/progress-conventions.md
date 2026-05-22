# PROGRESS / 文档维护规约 + 关键索引

> **Refs**: [#23](https://github.com/m42981454-tech/doc/issues/23) — 2026-05-20 Phase 1 / 从 PROGRESS.md §🔍/§📐/§🚦/§🗂️ 抽出
> **加载**: 每会话(无 `paths:` frontmatter,与 `.claude/rules/` 其他 sub-file 同 baseline)

---

## 🔍 快速查找(给下个 Claude / 同事)

读完主 [`PROGRESS.md`](../../20260403/plan1a-kong/PROGRESS.md) + `CLAUDE.md` 就能接力。

| 问题 | 看哪段 / 哪文件 |
|---|---|
| 下一步做什么? | 主 PROGRESS §🔄 当前进行中 + §🔴 待做 |
| 哪些等我决策? | 主 PROGRESS §👤 等用户决策 |
| 哪些等我验收? | 主 PROGRESS §🟡 已 merge 待验收 |
| 已闭环 sprint / 决策 | [`PROGRESS_done.md`](../../20260403/plan1a-kong/PROGRESS_done.md) |
| 未来 roadmap / GA 后 | [`PROGRESS_roadmap.md`](../../20260403/plan1a-kong/PROGRESS_roadmap.md) |
| 历史做过啥? | 主 PROGRESS §🔄 完成的转 PROGRESS_done + commit log |
| 架构契约 / 规约? | 本 `.claude/rules/` 各 sub-file + 主 `CLAUDE.md` + `design/` |
| 全文档导航 | [`docs/INDEX.md`](../../20260403/plan1a-kong/docs/INDEX.md) |
| 事故复盘 | [`docs/postmortems/README.md`](../../20260403/plan1a-kong/docs/postmortems/README.md) |

---

## 📐 PM 维护流程

### 每完成一个 sprint
1. 走 chore 分支:`git checkout -b feature/dev.<container>.chore.progress-<topic>`
2. 更新主 PROGRESS.md:
   - §🔄 当前进行中 → 移除该 sprint
   - §🟡 待用户验收 → 添加新验收点
   - §🔄 完成事件简述(若需要细节,留 link 到 docs/ sprint 专辑)
3. 顶部 codeblock `[最后更新]` / `[当前 sprint]` 更新(**不写 hash**,per §7.7.1)
4. 如有新待办 → 主 PROGRESS §🔴 或 [`PROGRESS_roadmap.md`](../../20260403/plan1a-kong/PROGRESS_roadmap.md) 对应分组
5. `--no-ff` merge 回容器分支,删 chore 分支,**不 push**(除非用户明示)

### 滚动归档触发(2026-05-20 新规约,refs #23)

**自动触发条件**(任一满足时,PM 在下一次 chore 顺手归档):
- 主 PROGRESS.md > **250 行**
- 主 PROGRESS §✅ 或 §🟡 完成项 > **20 项**
- 顶层 `docs/` 含 > **5 个** `YYYY-MM-DD_*.md` 未入月份目录

**归档动作**:
1. §✅ 已完成 sprint history → 移入 [`PROGRESS_done.md`](../../20260403/plan1a-kong/PROGRESS_done.md) §已完成 sprint(日期倒序保留)
2. §🟡 已带 ✅ PM auto-verified → 移入 PROGRESS_done §已 verified
3. §🔴 ~~划掉~~ 已 done polish → 移入 PROGRESS_done §已完成 polish
4. §👤 已落地决策 → 移入 PROGRESS_done §已落地决策
5. 顶层 docs/ 单 doc → `git mv docs/YYYY-MM-DD_*.md docs/YYYY-MM/`
6. 主 PROGRESS.md 保持 **< 200 行**(超 250 自动触发下次归档)

### 新 sprint 启动时
1. **必先** `gh issue create`(per §7.9 Issue-First gate)
2. `git checkout -b feature/dev.<container>.<topic>`(从 feature/dev 起)
3. 主 PROGRESS §🔄 加 sprint 简版(name / 范围 / 阶段=design / Blockers)
4. 设计文档单独 commit 到 sprint 分支(不进 PROGRESS.md)

### 用户验收一项后
- 主 PROGRESS §🟡 划掉那行 → 或 PM 在下次 chore 加 ✅ 前缀 → 满 20 项归档

### 完整团队编排(详 `team-orchestration.md`)
- 必经双签:`Code Reviewer` + Tester
- 按需追加签字:Security / Reality Checker / SRE 等(per §2.5 触发决策表)

### Sub-agent / Sonnet 派发原则
- PM 主线跑长任务(pytest 全量 / docker build):避免 Sonnet token 限制中途卡
- Sonnet 只做实装 + 局部测试;不跑 pytest 全量
- 重构涉及 module-level 符号迁移必须同步迁移测试 `monkeypatch.setattr("module.symbol")` path
- 并发 agent 显式 base 隔离;agent prompt 起手 `git fetch && git checkout feature/dev`(防 stale base bug)
- 派 future doc agent 必须含 sprint 完成清单 prerequisite
- bug 诊断必须看完整 traceback / response body
- Tester 报 bug 用 `gh issue create` 自动建 issue(详 §7.9)

---

## 🚦 优先级图标

| 图标 | 含义 |
|---|---|
| 🔥 | 阻塞下个 sprint(PM 不能跳过)|
| ⚡ | 等用户决策才能继续 |
| ⏳ | PM 可独立做(不影响其他)|
| 🧹 | polish 可选(不影响功能)|

---

## 🗂️ 关键文档索引

**总入口**: [`docs/INDEX.md`](../../20260403/plan1a-kong/docs/INDEX.md)(174 .md 分类导航,2026-05-20 新建,refs [#23](https://github.com/m42981454-tech/doc/issues/23))

**常用 link**:
| 主题 | 路径 |
|---|---|
| 项目约定(主)| `<repo>/CLAUDE.md` |
| 派 agent / 团队编排 | `.claude/rules/team-orchestration.md` |
| Git workflow / Issue-First | `.claude/rules/git-workflow.md` |
| 设计契约 / 技术栈 / 测试 | `.claude/rules/project-context.md` |
| 行为 4 原则(karpathy)| `.claude/rules/behavioral-rules.md` |
| docs/ 命名规约(path-scoped)| `.claude/rules/docs-conventions.md` |
| 架构政策(/v1/* 等)| `.claude/rules/architecture-policies.md` |
| 历次 sprint 设计 | `docs/<YYYYMMDD>/` 各 sprint 专辑 |
| 运维 runbook | `docs/admin_runbook.md` |
| 事故复盘 | `docs/postmortems/` |
| brainstorming notes(R1-R20)| `docs/brainstorm/` |
| 月份归档单 doc(2026-05-19 起)| `docs/YYYY-MM/` |
| 历史 ph<N> 归档 | `docs/archive/` |

---

> 📌 **Maintainer 注**:本文件由 [#23](https://github.com/m42981454-tech/doc/issues/23) 引入(2026-05-20 Phase 1 PROGRESS 拆分)。修改本文件 = `.claude/rules/` 改动(per `git-workflow.md §7.9`)→ 必先开 issue + chore 分支。
