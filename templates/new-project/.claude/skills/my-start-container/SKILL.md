---
name: my-start-container
description: 开新滚动容器(如 feature/dev.260520)— 当用户说"启动 sprint 260XXX" / "开 container 260XXX"时使用。必须 5 条件同时满足,且 disable-model-invocation true(避免误触发开新容器)。
disable-model-invocation: true
---

# my-start-container

> **作用**:开新滚动容器(`feature/dev.<YYMMDD>`)必须严格满足 §7.8 5 条件
> **触发**:**只手动** `/my-start-container` 或 my-start-sprint 内部明确调用(`disable-model-invocation: true` 防误触发,避免事故 1 / 事故 2 重演 — 详 `docs/postmortems/2026-05-18_worktree-collision-and-pm-merge-slip.md`)
> **关联规约**: [`.claude/rules/git-workflow.md §7.8`](../../rules/git-workflow.md)

---

## 5 条件 checklist(任一不满足 → 不开新容器)

| 条件 | 校验方式 | 满足? |
|---|---|---|
| **C1** 日历日已换 | 当前系统日期 > 当前容器名日期(同日不开)| ⏳ |
| **C2** 当前容器已 merge 主线 + push 远端 | `git log origin/feature/dev` 含当前容器 merge commit | ⏳ |
| **C3** §🟡 待用户验收为空 / 全划掉 | PROGRESS §🟡 无未划掉项 | ⏳ |
| **C4** §🔴 无 🔥 阻塞项 | PROGRESS §🔴 当前 sprint 0 Must-Fix-Now | ⏳ |
| **C5** 用户明示触发 | 用户说 "启动 sprint <YYYYMMDD>" / "开新容器" | ⏳ |

**任一不满足** → **不**升级容器名,改用:
- 当前容器内子分支:`feature/dev.<当前容器>.<topic>`
- 或挂主线 chore:`feature/dev.chore.<topic>`

---

## 校验脚本(逐条检查,**不要跳步**)

### C1 — 日历日已换

```bash
TODAY=$(date +%y%m%d)
CURRENT=$(git branch --list 'feature/dev.[0-9]*' | sed 's/.*feature\/dev\.//' | grep -oE '^[0-9]{6}' | sort -u | tail -1)
echo "Today: $TODAY  /  Current container: $CURRENT"
# C1 满足:Today > Current
```

### C2 — 当前容器已 push 远端

```bash
git log origin/feature/dev --grep "feature/dev.$CURRENT" --oneline | head -5
# 若 0 行 → 容器未 merge / 未 push → C2 ❌
```

### C3 — §🟡 全划掉

```bash
awk '/^## 🟡/,/^## 🔴/' 20260403/plan1a-kong/PROGRESS.md | grep -c '^| [A-Z]'
# 0 行 = §🟡 已空(或全 ✅ 移到 PROGRESS_done.md)
# 若 > 0 → C3 ❌
```

### C4 — §🔴 无 🔥

```bash
awk '/^### 🔥/,/^### ⚡/' 20260403/plan1a-kong/PROGRESS.md | grep -c '🔥'
# 0 行 = 无 burning;> 0 → C4 ❌
```

### C5 — 用户明示

只在用户输入含 "启动 sprint <YYMMDD>" / "开新容器" / "开 container" 时触发。**不**根据猜测自动开。

---

## 全 5 满足 → 开新容器

```bash
git checkout feature/dev
git pull                            # 同步远端最新
NEW_CONTAINER="feature/dev.$(date +%y%m%d)"
git checkout -b "$NEW_CONTAINER"
# 开第一个 sprint 子分支(per my-start-sprint)
```

---

## 任一不满足 — 替代方案

按 §7.8 fallback:

| 当前情况 | 用什么 |
|---|---|
| 容器已 closed(merge + push)+ 只做 polish / hotfix | `feature/dev.chore.<topic>` 直接挂主线 — **不开新容器** |
| 当前 sprint 进行中,要加 fix | `feature/dev.<当前容器>.fix<M>` 子分支 |
| sprint 进行中,加新 task 子分支 | `feature/dev.<当前容器>.<topic>` |

---

## 违反后果

**误开新容器**(任一条件未满足就升级)会导致:
- 分支拓扑混乱(多容器并存 / 跨容器 commit 漂移)
- §🟡 验收项分散到多容器,用户验收时找不到
- bisect 困难

**事故案例**:[`docs/postmortems/2026-05-18_worktree-collision-and-pm-merge-slip.md`](../../../20260403/plan1a-kong/docs/postmortems/2026-05-18_worktree-collision-and-pm-merge-slip.md)

---

## DON'T

- ❌ 不在 5 条件未全满足时开新容器
- ❌ 不在用户没明示时"主动"开新容器
- ❌ 不在 sprint 进行中改容器名
- ❌ 不在容器 merge 后立即开新容器(必满足 C1 日历日已换)
