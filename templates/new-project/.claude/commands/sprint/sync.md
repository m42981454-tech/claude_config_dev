---
description: sprint merge 后同步 PROGRESS.md 的 chore 流程
allowed-tools: Bash, Skill, Edit, Read, Grep
---

# /sprint:sync

sprint merge 后 PROGRESS 同步显式入口。**调用 `my-pm-progress-sync` skill** 走 §7.7 chore 7 步 SOP。

## Usage

```
/sprint:sync                     # 无参,自动 detect 最近 merge 的 sprint
/sprint:sync <sprint-name>       # 显式指定 sprint
```

## 步骤

调用 skill `my-pm-progress-sync`:

1. 走 chore 分支 `feature/dev.chore.progress-<topic>`(**从 feature/dev 起**)
2. 更新 PROGRESS.md(work state,**不**写 git state — per §7.7.1)
3. 检查滚动归档触发(> 250 行 或 §✅/§🟡 > 20 项)
4. commit + 回主线 + merge --no-ff(独立 Bash 调用,**不**chained pipe)
5. 删 chore 分支
6. **不**push(等用户明示)

## 关联

- skill [`my-pm-progress-sync`](../../skills/my-pm-progress-sync/SKILL.md)
- `.claude/rules/git-workflow.md §7.7` + `.claude/rules/progress-conventions.md §📐`
