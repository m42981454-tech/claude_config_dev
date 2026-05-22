---
name: my-pm-progress-sync
description: 在 sprint merge 前把 progress.md 更新作为 sprint 分支最后一个 commit（新工作流，减少不必要的 chore merge）— 当用户说"同步 PROGRESS" / "更新进度" / sprint 全部跑完准备合并主线时使用。包含 pre-merge 流程 + chore.progress 例外路径 + §7.7.1 描述边界 + 滚动归档触发。
---

# my-pm-progress-sync

> **作用**：封装 sprint 全部实装 / Review / Test 完成后必走的 PROGRESS 同步流程（§7.7 新工作流 + §7.7.1 描述边界 + §7.5.1 chained-pipe 防御）
> **触发**：auto-match `同步 PROGRESS` / `更新进度` / sprint 阶段切换 / merge 前 PM 收尾
> **关联规约**: [`.claude/rules/git-workflow.md §7.7-§7.7.2`](../../rules/git-workflow.md) + [`.claude/rules/progress-conventions.md`](../../rules/progress-conventions.md)

---

## 主路径：PROGRESS 更新作为 sprint 分支最后一个 commit

**新工作流**：把 PROGRESS update 作为 sprint 分支的**最后一个 commit**，与 code 改动**一次 merge** 同时入主线（减少 chore.progress 单独 merge）。

### Step 1 — 确认在 sprint 分支上

```bash
git status                                  # 必 clean
git branch --show-current                   # 应该是 [MAIN_BRANCH].<topic>
```

**铁律**：本步骤**不切回主线**。直接在 sprint 分支上做 PROGRESS update。

### Step 2 — 更新 progress.md（按 §7.7.1 描述边界）

只写 work state，**不**写 git state：

| 该更新 | 不该更新（去 git/gh 查）|
|---|---|
| §🔄 当前进行中 sprint phase | HEAD commit hash |
| §🟡 加新验收点 | branch list / push 同步状态 |
| §🔴 划掉已完成项 | 远端 sync 状态（ahead/behind）|
| §🔮 新待办 / decision | merge commit hash |
| 顶部 `[GH issues] N closed / M open` | 工作树 dirty/clean |
| 顶部 `[最后更新]` 日期 | 任何 hash |
| 顶部 `[pytest baseline]` 数字 | branch deletion 状态 |

### Step 3 — 检查滚动归档触发

```bash
wc -l progress.md
```

若 progress.md > **250 行** 或 §✅/§🟡 完成项 > **20 项**:

- 触发归档：把 §✅ 已完成 sprint / §🟡 PM auto-verified / §🔴 ~~划掉~~ / §👤 已落地决策 → 移入 `PROGRESS_done.md` 顶部（日期倒序）
- 顶层 docs/ 含 > 5 个 `YYYY-MM-DD_*.md` 未入月份目录 → `git mv` 到 `docs/YYYY-MM/`

### Step 4 — commit（避 §7.5.1 chained-pipe trap）

```bash
git add progress.md                         # 仅 PROGRESS，不带其他文件
git commit -m "docs(progress): <what> (Refs #N)"
```

**铁律**（§7.5.1）：`git checkout/merge/commit` **不可与 pipe（`tail`/`head`）+ `&&` chain**（防 pipe 吃 fatal 退出码）。每命令**独立 Bash 调用**。

### Step 5 — Pre-merge 自检

```bash
git log -1 --name-only [MAIN_BRANCH].<topic> | grep -i progress
```

应输出 `progress.md`。若空 → 上一步 commit 未生效，重做 Step 4。

### Step 6 — 回主线一次性 merge（code + progress 原子）

```bash
git checkout [MAIN_BRANCH]
# 独立 Bash 调用 — 不 chain checkout + merge
git merge --no-ff [MAIN_BRANCH].<topic> \
  -m "Merge [MAIN_BRANCH].<topic> -> [MAIN_BRANCH]: <what> (Refs #N)"
```

**铁律**（commit-msg hook 强制）：merge subject 必含 `<src> -> <dst>: <what>` 前缀。

### Step 7 — 删本地 sprint 分支

```bash
git branch -d [MAIN_BRANCH].<topic>
```

### Step 8 — **不** push（用户明示前）

PROGRESS 只在本地 ahead — 等用户说 "push" 才 push。

---

## 例外路径：chore.progress 分支（少数场景）

以下情况允许走单独 chore.progress 分支：

| 场景 | 处理 |
|---|---|
| 紧急 hotfix：sprint 已 merge，事后才发现需要补 PROGRESS | `[MAIN_BRANCH].chore.progress-<topic>` 补一次 |
| 跨 sprint 总结性 PROGRESS 调整（归档触发后批量整理）| `[MAIN_BRANCH].chore.progress-archive` |
| design-only sprint（无 code 改动，但要登记决策）| 可直接在 chore 分支做 |

例外路径流程：

```bash
git checkout [MAIN_BRANCH]                              # 回主线
git checkout -b [MAIN_BRANCH].chore.progress-<topic>    # 从主线起开 chore
# 编辑 progress.md
git add progress.md
git commit -m "docs(progress): <what> (Refs #N)"
git checkout [MAIN_BRANCH]
git merge --no-ff [MAIN_BRANCH].chore.progress-<topic> \
  -m "Merge [MAIN_BRANCH].chore.progress-<topic> -> [MAIN_BRANCH]: <what> (Refs #N)"
git branch -d [MAIN_BRANCH].chore.progress-<topic>
```

**铁律**（§7.7）：chore.progress 分支**必从主线起**（不能从 sprint 分支起），避免 chore commit 携带 sprint work 绕过双签。

---

## 错误处理

| 场景 | 动作 |
|---|---|
| commit-msg hook 拒绝 merge subject | 修正格式 `<src> -> <dst>: <what>` 重 commit |
| pre-commit hook 拒绝主线 commit | 走 chore 分支（`[MAIN_BRANCH].chore.<topic>`），不直接主线 |
| Pre-merge 自检发现 last commit 未含 progress.md | 在 sprint 分支追加 Step 4 commit，再 merge |
| H2-pre hook 警告 sprint 分支 last commit 未含 progress.md | 退回 Step 4 更新；或确认是 design-only sprint 可继续 |
| 用户问"要不要 push" | **不**自动 push，提示用户明示 |

---

## DON'T

- ❌ 不在主线直接 commit PROGRESS（per §7.2 + pre-commit hook）
- ❌ 不在 sprint 分支上启动 chore.progress 子分支（例外路径必从主线起）
- ❌ 不在 PROGRESS 写 git hash / branch list / push 状态（per §7.7.1）
- ❌ 不 chained `git checkout BR | tail && git merge`（per §7.5.1）
- ❌ 不累积多 sprint 批量更 PROGRESS（每 sprint merge 前立刻同步作为 final commit）
- ❌ 不 push（用户明示前）
- ❌ 不在已 merge 的 sprint 分支上做 PROGRESS update（已 merge 用 chore.progress 例外路径）
