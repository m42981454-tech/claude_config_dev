---
description: 启动新 sprint（走 Issue-First gate + 开子分支 + 派单入口）
allowed-tools: Bash, Skill, Edit, Write, Read, Grep, Glob, Agent
---

# /sprint:start

启动新 sprint 的显式入口。**调用 `my-start-sprint` skill** 走完 7 步 SOP（详 `.claude/skills/my-start-sprint/SKILL.md`）。

## Usage

```
/sprint:start P0-1
/sprint:start P0-2
/sprint:start ph<N>
/sprint:start <sprint-topic>
```

## 步骤

调用 skill `my-start-sprint` 执行:

1. 验证 git status clean + 回 [MAIN_BRANCH]
2. Issue-First gate（`gh issue create` + 拿 #N）
3. 开子分支 `[MAIN_BRANCH].<topic>`（从 [MAIN_BRANCH] 起）
4. 首 commit `Refs #N`
5. 派单（`/sprint:dispatch`）
6. sprint 执行循环（双签 / 按需追加签字）
7. Pre-merge：在 sprint 分支上更新 progress.md 作为 last commit（调用 `/sprint:sync` 主路径），然后 `--no-ff` 一次性 merge

## $ARGUMENTS

接受参数：sprint 标识符（P0-N / ph<N> / topic）。

## 关联

- skill [`my-start-sprint`](../../skills/my-start-sprint/SKILL.md)
- skill [`my-issue-first-gate`](../../skills/my-issue-first-gate/SKILL.md)
- `.claude/rules/git-workflow.md §7.4-§7.9`
