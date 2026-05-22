---
description: 按命名规范创建新分支（三项前置检查 + 自动补全主线前缀）
allowed-tools: Bash
---

# /git:branch

创建新分支前执行三项前置检查，并自动补全 `[MAIN_BRANCH].` 前缀，确保符合 `git-workflow.md §7.2` 命名规范。

## Usage

```
/git:branch ph3              → [MAIN_BRANCH].ph3
/git:branch ph3.fix1         → [MAIN_BRANCH].ph3.fix1
/git:branch chore.docs       → [MAIN_BRANCH].chore.docs
/git:branch [MAIN_BRANCH].ph3  → [MAIN_BRANCH].ph3（已含前缀，直接用）
```

## 步骤

**Step 1 — 解析分支名**

从 `$ARGUMENTS` 推断完整分支名（`MAIN_BRANCH` 从 git 自动检测）：

| 输入 | 生成分支名 |
|---|---|
| `ph<N>` | `[MAIN_BRANCH].ph<N>` |
| `ph<N>.fix<M>` | `[MAIN_BRANCH].ph<N>.fix<M>` |
| `chore.<topic>` | `[MAIN_BRANCH].chore.<topic>` |
| 已含 `[MAIN_BRANCH].` 前缀 | 原样使用 |
| 其他任意字符串 | `[MAIN_BRANCH].<input>`（警告：请确认命名符合规范）|

**Step 2 — 三项前置检查**

```bash
# 检查 1：工作树干净
git status --short

# 检查 2：当前所在分支
git branch --show-current

# 检查 3：主线是否落后 remote（有 remote 时）
git fetch origin --dry-run 2>/dev/null
```

| 结果 | 处理 |
|---|---|
| 工作树有未 commit 变更 | **停止**，提示先 `git commit` 或 `git stash` |
| 当前不在主线 | 警告并询问，默认切换到主线再创建 |
| 主线落后 remote | 警告，建议先 `git pull origin [MAIN_BRANCH]` |

**Step 3 — 创建分支**

```bash
MAIN=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo main)
git checkout "$MAIN"
git checkout -b "<full-branch-name>"
```

**Step 4 — 输出**

```
✅ 已创建：<full-branch-name>
   基于：[MAIN_BRANCH] @ <short-hash>
   
   如果这是新 sprint → 建议使用 /sprint:start 代替（含 Issue-First gate）
   如果是 bug fix   → 记得先 /issue bug <desc> 创建 issue，再开始开发
```

## $ARGUMENTS

分支标识符（可省略 `[MAIN_BRANCH].` 前缀，命令自动补全）。

## 注意

如果是**新 sprint**，推荐用 `/sprint:start` 代替本命令——它包含 Issue-First gate，会先创建 GitHub issue 再开分支。本命令适合快速创建 chore / fix 等轻量分支。

## 关联

- `.claude/rules/git-workflow.md §7.2 / §7.4`
- `/sprint:start`（新 sprint 的完整流程）
- `/issue`（fix 分支开始前先建 issue）
