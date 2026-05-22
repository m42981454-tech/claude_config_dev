---
description: 随时查看当前工作状态（分支 / issues / PROGRESS 摘要）
allowed-tools: Bash, Read
---

# /status

随时可调的工作状态快照。等同于 H6 SessionStart 摘要，但附加 PROGRESS 当前 sprint 详情和待决策项。

## 步骤

**Step 1 — Git 状态**

```bash
git branch --show-current
git status --short
git log --oneline -5
git rev-list --count "origin/$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|origin/||')..HEAD" 2>/dev/null
```

**Step 2 — Open Issues**

```bash
gh issue list --state open --limit 10 2>/dev/null
```

**Step 3 — PROGRESS 摘要**

Read `progress.md`，提取并输出以下段落：

| 段落 | 说明 |
|---|---|
| `§🔄 当前进行中` | 所有内容 |
| `§🟡 已 merge 待验收` | 所有内容 |
| `§👤 等用户决策` | 所有内容 |
| `§🔴 待做` 中 🔥 项 | 仅 Urgent / Must-Fix-Now |

**Step 4 — 格式化输出**

```
━━━ Project Status ━━━━━━━━━━━━━━━━━━━
Branch : <branch>  |  ahead <N>  |  <clean/dirty>
Issues : <N> open
Commits: <hash> <msg>  |  <hash> <msg>  |  ...

🔄 In Progress
  <sprint summary or "(none)">

🟡 Pending Review
  <items or "(none)">

👤 Awaiting Decision
  <items or "(none)">

🔥 Blockers
  <items or "(none)">
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## $ARGUMENTS

无参数。

## 关联

- `progress.md`（状态唯一真相源）
- `.claude/rules/progress-conventions.md`
- H6 SessionStart hook（session 起时自动输出精简版）
