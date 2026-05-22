---
description: sprint 全部完成后同步 progress.md（新工作流：作为 sprint 分支最后一个 commit；例外：chore.progress 分支补救）
allowed-tools: Bash, Skill, Edit, Read, Grep
---

# /sprint:sync

sprint 实装 / Review / Test 全部跑完后 PROGRESS 同步显式入口。**调用 `my-pm-progress-sync` skill** 走主路径或例外路径。

## Usage

```
/sprint:sync                     # 无参，在当前 sprint 分支上更新 progress.md（主路径）
/sprint:sync <sprint-name>       # 显式指定 sprint 名（用于例外路径或多 sprint 同步）
```

## 主路径：progress.md 作为 sprint 分支最后一个 commit（推荐）

仍在 sprint 分支上时调用本命令：

1. 确认在 sprint 分支（`[MAIN_BRANCH].<topic>`）上，**不切回主线**
2. 更新 progress.md（work state，**不**写 git state — per §7.7.1）
3. 检查滚动归档触发（> 250 行 或 §✅/§🟡 > 20 项）
4. `git commit -m "docs(progress): mark <topic> done (Refs #N)"` —— sprint 分支最后一个 commit
5. Pre-merge 自检：`git log -1 --name-only [MAIN_BRANCH].<topic>` 应含 `progress.md`
6. `git checkout [MAIN_BRANCH]` + `git merge --no-ff [MAIN_BRANCH].<topic> -m "Merge ..."` —— 一次 merge 含 code + progress
7. `git branch -d [MAIN_BRANCH].<topic>`
8. **不** push（等用户明示）

## 例外路径：chore.progress 分支（紧急 hotfix 后补 / 跨 sprint 归档整理）

```
/sprint:sync <sprint-name>       # 指定 sprint 走例外路径
```

流程：

1. 回主线开 chore：`git checkout [MAIN_BRANCH] && git checkout -b [MAIN_BRANCH].chore.progress-<topic>`
2. 更新 progress.md + commit + 回主线 `--no-ff` merge + 删 chore 分支
3. **铁律**：chore.progress 分支**必从主线起**（不能从 sprint 分支起）

## 关联

- skill [`my-pm-progress-sync`](../../skills/my-pm-progress-sync/SKILL.md)
- `.claude/rules/git-workflow.md §7.7`（新工作流）+ `.claude/rules/progress-conventions.md`
