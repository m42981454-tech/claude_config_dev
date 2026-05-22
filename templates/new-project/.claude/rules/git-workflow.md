# Git Workflow（详细规则）

> 由 `CLAUDE.md §7` 引用。主文档保留要点摘要，本文件是完整规则。

---

## 1. 主线定义

- **当前主线**：`[MAIN_BRANCH]`（开发阶段）
- **PR 目标**：`main`

---

## 2. 强制规则：不直接 commit 到主线

- ❌ 不允许在主线（`[MAIN_BRANCH]`）上直接 `git commit`
- ✅ 所有改动必须从主线最新 HEAD 开子分支：
  - 功能 / sprint：`[MAIN_BRANCH].ph<N>`（如 `[MAIN_BRANCH].ph1`）
  - bug 修复：`[MAIN_BRANCH].fix<M>`
  - 文档 / 配置 / 杂项：`[MAIN_BRANCH].chore.<topic>`
- ✅ 切换前先 `git status` 确认 clean
- ✅ merge 回主线用 `--no-ff -m "..."` 保留拓扑
- ✅ merge 后立刻 `git branch -d <name>` 删临时分支
- ❌ 不 push 远端（除非用户明确要求）
- ❌ 不 amend 已 push 历史；不 rebase 已 merge 历史；不 force push

---

## 3. 例外

- 用户**明确**指示"直接提交到主线"时才允许
- 其余情况一律走子分支

---

## 4. 子分支生命周期

```bash
git status                                              # 确认 clean
git checkout [MAIN_BRANCH]                              # 回主线
git checkout -b [MAIN_BRANCH].<topic>                   # 开子分支
# ... 实装 / Review / 测试 ...
git checkout [MAIN_BRANCH]
git merge --no-ff [MAIN_BRANCH].<topic> -m "..."
git branch -d [MAIN_BRANCH].<topic>
```

---

## 5. commit 规范

- 多行格式（subject + 空行 + 正文 bullet），仅用户明确要求时才用单行
- 正文分区：代码变更 / 测试变更 / 文档变更
- 聚焦 **why**；中文优先，代码用英文反引号包裹
- commit 前必须先 `git status` / `git diff`
- 只 stage 属于当前任务的文件，不裹带无关 dirty files

---

## 6. progress.md 更新规约

- 新任务启动时：在 `## 当前任务` 加行
- 任务完成 merge 后：移到 `## 已完成`，并更新 `## 残留清理` / `## 后续计划`
- 每次 sprint merge 后**立即**走 `[MAIN_BRANCH].chore.progress` 子分支更新，不累积批量改

---

## 7. Worktree 并行开发

需要并行处理 2+ 个**独立**任务时，用 worktree 物理隔离，避免同目录双 Claude 互踩 git index。

### 创建并行 worktree

```bash
# 从当前主线开新子分支并放到隔离目录
git worktree add ../[project]-ph<N> [MAIN_BRANCH].ph<N>
# 在新目录另开 Claude session，互不串扰，各自有完整 working tree + node_modules
```

### 完成后清理

```bash
# 主目录里
git worktree remove ../[project]-ph<N>
git branch -d [MAIN_BRANCH].ph<N>   # 如已 merge
```

### 与 subagent isolation 配合

subagent frontmatter `isolation: worktree` 让 subagent 跑在临时副本：

- subagent 无 commit → 自动清理
- subagent 有 commit → 保留 worktree，PM 决定如何 merge

适用场景：派 subagent 跑长时间 / 风险高 / 可能弄脏 working tree 的任务。

### 不要做

- ❌ 同一目录开 2 个 Claude session（会互踩 git index）
- ❌ Windows 下 worktree 路径含中文 / 空格（git 路径解析坑）
- ❌ 在 worktree 副本里 `git pull` / `git merge` 主线 — 主分支只在主目录操作
