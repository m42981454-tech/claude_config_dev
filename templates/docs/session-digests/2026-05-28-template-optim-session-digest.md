# Session 复盘摘要 — new-project 模板优化及收尾

> 缓存用途：供日后学习 / 复用本次协作中的决策与踩坑。
> 这是**提炼版**，非逐字实录；完整原始对话见 transcript：
> `~/.claude/projects/C--Users-dev002--claude/5599d903-4e07-439e-8c8d-f7e6638db8ed.jsonl`
> 日期：2026-05-28（优化主体工作发生在 2026-05-23~24，本次为收尾会话）

---

## 1. 这次 session 做了什么（整体弧线）

一次围绕 `~/.claude/templates/new-project/` 模板的**深度 review → 优化 → 提交 → 收尾**的长任务，跨多个会话（中途 compact / resume）。

- 主体：review 模板配置，做了 5 轮 review，闭环 28/40 问题（约 70%）
- 优化范围：占位符同步、跨平台 hook 健壮性、CRLF 崩溃修复、规则去重（单一真相源）、agent 默认禁用（`_available/` 子目录）、新增 `validate.sh/.ps1` 健康检查
- 产出已合并进 `feature/dev`（commit `308e312`，人工合并）
- 本次收尾会话处理了：缓存形式选型、报告位置纠错、配置提交

---

## 2. 关键决策与取舍

| 决策点 | 结论 | 理由 |
|---|---|---|
| 是否清理 `docs/` 历史 | **不删**，改用 `.claudeignore` 排除 | docs 是修正/演进履历；模板是长期维护项目，履历只能在派生新项目时排除，绝不能从模板源删 |
| `.claudeignore` 写法 | 文件级排除，**不用 `!` 反向规则** | gitignore 语义下父目录被排除时 `!` 反选无效 |
| agent 默认状态 | 默认禁用，移到 `_available/` | 减少新项目初始 context 开销，按需启用 |
| 规则重复段 | 保守去重 + link 到单一真相源（`git-workflow.md`） | 避免多处维护漂移，又不丢精度 |
| 模型角色表述 | 去掉 Opus/Sonnet 硬编码 → 角色化（PM/Implementer/Tester） | 模型会换代，硬编码会过期 |
| 优化复盘报告归属 | 留在 `new-project/docs/report/`（**不移出**） | 报告内容与该工程强相关（用户最终判断） |
| 是否写入 memory | **不写** | 用户明确拒绝；改为归档报告 + session 摘要 |

---

## 3. 踩坑与教训（最值得记住的部分）

1. **"agent/summary 总结 ≠ 实际发生"**
   上一轮总结声称报告已存到 `templates/report/`，实际它在 `new-project/docs/report/`，且 `templates/report/` 根本不存在。
   → 教训：凡涉及文件落盘/位置，**以 `ls`/`git status` 实测为准**，不轻信总结里的"已完成"。

2. **设计先行（design-before-implementation）**
   曾未出设计文档就直接改模板，被强制打断两次。
   → 教训：改动前先写 design doc 经确认，再动手。与全局 CLAUDE.md §7 brainstorming 门禁一致。

3. **误删 docs 履历**
   曾派 subagent "清理残留"误删了 specs，被强制打断后 `git checkout HEAD --` 还原。
   → 教训：长期维护项目的历史只排除、不删除。

4. **commit 切片要干净**
   一次 commit 误带入 8 个 agent rename → `git reset --soft` 重做。
   → 教训：按文件精确暂存，提交前 `git status -s` 核对。

5. **元报告 vs 模板内容 的边界**
   `docs/report/` 是模板给**派生项目**的 session 复盘约定；而"优化模板本身"的报告是元复盘，处境不同。最终因内容与工程强相关而留在原处。
   → 教训：放文件前先问"它会不会被带进新项目？是不是该混进模板源？"

6. **AI 不合主线**
   向 `feature/dev`/main 的 merge 是人工专属操作（H1 hook + 全局 CLAUDE.md）。

7. **memory vs 归档报告 的区别**
   memory = 给未来会话**自动加载/遵守**的规则；报告/摘要 = 给人**主动翻阅**的归档。用途不同，别混。

---

## 4. 产物位置清单

| 产物 | 路径 |
|---|---|
| 优化设计文档 | `templates/new-project/docs/superpowers/specs/2026-05-23-template-optimization-design.md` |
| 优化复盘报告（187 行 / ~10KB） | `templates/new-project/docs/report/2026-05-24-template-optimization-report.md` |
| specs 任务状态报告 | `templates/new-project/docs/report/2026-05-24-superpowers-specs-task-status-report.md` |
| 本摘要 | `templates/docs/sessions/2026-05-28-template-optim-session-digest.md` |
| 完整 transcript | `~/.claude/projects/C--Users-dev002--claude/5599d903-...jsonl` |

---

## 5. 本次收尾会话的 git 动作

- `2cd933b chore(config)`：settings.json — 默认模型切 sonnet、停用 karpathy 插件
- 报告 `git mv` 移出 → 又 `git mv` 还原（用户改主意，内容与工程强相关），一来一回抵消，无遗留

---

## 6. 遗留 / 后续（用户决定项）

- 分级模板（minimal/standard/full）
- AI-merge 预授权
- progress.md frontmatter
- validate 范围扩到 CLAUDE.md/docs
- 4 项外部依赖未验证（Claude Code 是否递归 `_available/`、`.claudeignore` 是否真支持、`.gitattributes` LF 是否在 clone 时生效、真实 session hook 行为）
