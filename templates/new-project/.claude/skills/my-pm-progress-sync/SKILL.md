---
name: my-pm-progress-sync
description: sprint merge 后同步 PROGRESS.md 的 chore 流程 — 当用户说"同步 PROGRESS" / sprint merge 后 hook 提示 / 任何 PROGRESS 更新场景时使用。包含 §7.7 chore 7 步 + 描述边界 + 滚动归档触发。
---

# my-pm-progress-sync

> **作用**:封装 sprint merge 后必走的 PROGRESS chore 流程(§7.7 + §7.7.1 描述边界 + §7.5.1 chained-pipe 防御)
> **触发**:auto-match `同步 PROGRESS` / merge 后 hook 提示 `sprint merge done`
> **关联规约**: [`.claude/rules/git-workflow.md §7.7-§7.7.2`](../../rules/git-workflow.md) + [`.claude/rules/progress-conventions.md`](../../rules/progress-conventions.md)

---

## PROGRESS 同步 chore 7 步 SOP

### Step 1 — 走 chore 分支(从 feature/dev 起,**不**从 sprint 分支)

```bash
git checkout feature/dev            # 必先回主线(防顺手 merge sprint work)
git checkout -b feature/dev.chore.progress-<topic>
```

**铁律**(§7.7):**chore 分支必从 feature/dev 起,不能从 sprint 分支起**(避免 chore commit 携带 sprint work 绕过双签)。

### Step 2 — 更新 PROGRESS.md(主文件,精简版)

按 §7.7.1 描述边界(work state,**不**描述 git state):

| 该更新 | 不该更新(去 git/gh 查)|
|---|---|
| §🔄 当前进行中 sprint phase | HEAD commit hash |
| §🟡 加新验收点 | branch list / push 同步状态 |
| §🔴 划掉已完成项 | 远端 sync 状态(ahead/behind)|
| §🔮 新待办 / decision | merge commit hash |
| 顶部 `[GH issues] N closed / M open` | 工作树 dirty/clean |
| 顶部 `[最后更新]` 日期 | 任何 hash |
| 顶部 `[pytest baseline]` 数字 | branch deletion 状态 |

### Step 3 — 检查滚动归档触发(2026-05-20 新规约)

```bash
wc -l 20260403/plan1a-kong/PROGRESS.md
```

若 PROGRESS.md > **250 行** 或 §✅/§🟡 完成项 > **20 项**:
- 触发归档:把 §✅ 已完成 sprint / §🟡 PM auto-verified / §🔴 ~~划掉~~ / §👤 已落地决策 → 移入 [`PROGRESS_done.md`](../../../20260403/plan1a-kong/PROGRESS_done.md) 顶部(日期倒序)
- 顶层 docs/ 含 > 5 个 `YYYY-MM-DD_*.md` 未入月份目录 → `git mv` 到 `docs/YYYY-MM/`

### Step 4 — commit(避 §7.5.1 chained-pipe trap)

```bash
git add 20260403/plan1a-kong/PROGRESS.md  # 仅 PROGRESS,不带其他文件
git commit -m "docs(progress): <what> (Refs #N)"
```

**铁律**(§7.5.1):`git checkout/merge/commit` **不可与 pipe(`tail`/`head`)+ `&&` chain**(防 pipe 吃 fatal 退出码)。每命令**独立 Bash 调用**。

### Step 5 — 回主线 + merge --no-ff

```bash
git checkout feature/dev
# 独立 Bash 调用 — 不 chain checkout + merge
git merge --no-ff feature/dev.chore.progress-<topic> \
  -m "Merge feature/dev.chore.progress-<topic> -> feature/dev: <what> (Refs #N)"
```

**铁律**(commit-msg hook 强制):merge subject 必含 `<src> -> <dst>: <what>` 前缀。

### Step 6 — 删本地 chore 分支

```bash
git branch -d feature/dev.chore.progress-<topic>
```

### Step 7 — **不** push(用户明示前)

PROGRESS 只在本地 ahead — 等用户说 "push" 才 push。

---

## 两次 merge 原则(§7.7)

**sprint merge** 与 **PROGRESS update merge** 是**两次独立 merge**(保证 sprint 改动与 PROGRESS 改动可分离 review / bisect):

1. 先 merge sprint 分支(实装 + 测试 + docs/ 设计文档)
2. **紧接着**开 `chore.progress-<topic>` 分支更新 PROGRESS
3. merge chore 分支
4. **不**累积多个 sprint 后再批量更新(违反单一真相源)

---

## 错误处理

| 场景 | 动作 |
|---|---|
| commit-msg hook 拒绝 merge subject | 修正格式 `<src> -> <dst>: <what>` 重 commit |
| pre-commit hook 拒绝主线 commit | 走 chore 分支(`feature/dev.chore.<topic>`),不直接主线 |
| 用户问"要不要 push" | **不**自动 push,提示用户明示 |

---

## DON'T

- ❌ 不在主线直接 commit PROGRESS(per §7.2 + pre-commit hook)
- ❌ 不在 sprint 分支上做 chore.progress(从 feature/dev 起)
- ❌ 不在 PROGRESS 写 git hash / branch list / push 状态(per §7.7.1)
- ❌ 不 chained `git checkout BR | tail && git merge`(per §7.5.1)
- ❌ 不累积多 sprint 批量更 PROGRESS(每 sprint merge 后立刻同步)
- ❌ 不 push(用户明示前)
