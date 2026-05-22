---
description: 开新滚动容器（必满足 §7.8 5 条件）
allowed-tools: Bash, Skill, Read, Grep
---

# /sprint:container

开新滚动容器（如 `[MAIN_BRANCH].260520`）显式入口。**调用 `my-start-container` skill**（`disable-model-invocation: true`，只能显式 invoke 防误开）。

## Usage

```
/sprint:container 260520          # 显式指定容器日期
/sprint:container                 # 用当日日期（若 5 条件满足）
```

## 5 条件 checklist（任一不满足 → 不开）

| 条件 | 校验 |
|---|---|
| C1 日历日已换 | 今日 > 当前容器名日期 |
| C2 当前容器已 merge + push | `git log origin/[MAIN_BRANCH]` 含 merge |
| C3 §🟡 空 / 全划掉 | PROGRESS §🟡 无未划掉 |
| C4 §🔴 无 🔥 阻塞 | 0 Must-Fix-Now |
| C5 用户明示触发 | 你执行本 `/sprint:container` = 明示 ✅ |

任一不满足 → 改用 `/sprint:start` 在当前容器内开子分支。

## 关联

- skill [`my-start-container`](../../skills/my-start-container/SKILL.md)
- `.claude/rules/git-workflow.md §7.8`
- 事故案例：参 `docs/postmortems/` 内 worktree collision / PM merge slip 类型复盘（如有）
