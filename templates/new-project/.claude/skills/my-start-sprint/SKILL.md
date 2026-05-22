---
name: my-start-sprint
description: 启动新 sprint 的标准流程 — 当用户说"启动 P0-X" / "启动 sprint X" / "启动 ph<N>" 时使用。处理 Issue-First gate（必先 gh issue create）+ 开子分支 + 派单入口。Good example - 用户："启动 P0-1"；Bad example - 不要在已有 sprint 进行中再调用本 skill。
---

# my-start-sprint

> **作用**：封装 PM 收到 "启动 sprint X" / "启动 P0-X" 后的标准化流程（§7.4 子分支生命周期 + §7.6 启动 ph 第一动作 + §7.9 Issue-First gate）
> **触发**：auto-match `启动 P0` / `启动 sprint` / `启动 ph`（无 `disable-model-invocation`）
> **关联规约**: [`.claude/rules/git-workflow.md`](../../rules/git-workflow.md) §7.4-§7.9 + [`.claude/rules/team-orchestration.md`](../../rules/team-orchestration.md) §2

---

## 启动 sprint 7 步 SOP

按顺序执行，**不可跳步**。每一步完成才进下一步。

### Step 1 — 验证启动前状态

```bash
git status                          # 必 clean
git checkout [MAIN_BRANCH]          # 回主线
git pull                            # 同步远端（若有）
```

如 `git status` 非 clean → 报告用户 + 等用户决定（commit / stash / discard）。

### Step 2 — Issue-First gate（§7.9 强制）

**必先**创建 GitHub issue，**再**开子分支。

调用 [`my-issue-first-gate`](../my-issue-first-gate/SKILL.md) skill，或直接:

```bash
gh issue create \
  --title "[<type>] <模块>: <一句话>" \
  --label "<bug|enhancement|chore>" \
  --body "$(cat <<EOF
## 背景
...
## Scope
...
## 验收
...
## 优先级
🔥/⚡/⏳/🧹
EOF
)"
```

> `gh issue create` 不带 `--repo` 时使用 `gh repo` 默认（git remote `origin`）。需指定时加 `--repo [REPO_OWNER]/[REPO_NAME]`。

记下返回的 issue URL → `#N`。

### Step 3 — 开 sprint 子分支（从 [MAIN_BRANCH] 起）

子分支命名（per §7.2）:

- sprint 任务：`[MAIN_BRANCH].ph<N>` 或 `[MAIN_BRANCH].<container>.<topic>`
- bug 修复：`[MAIN_BRANCH].<container>.fix<M>`
- chore：`[MAIN_BRANCH].<container>.chore.<topic>`

```bash
git checkout -b [MAIN_BRANCH].<topic>
```

### Step 4 — 首 commit 含 `Refs #N`

设计文档（若有）单独 commit 到子分支，首 commit message 必含 `Refs #N`。

```
docs(<topic>): 设计文档 <description> (Refs #<N>)
```

### Step 5 — 派单（调用 my-dispatch-sprint）

按 sprint 任务性质，调用 [`my-dispatch-sprint`](../my-dispatch-sprint/SKILL.md) skill 派 implementer / reviewer / tester。

派单稿必含 4 channel 强制（详 dispatch-sprint skill）:

- ch1: Agent description `[T#·Role·Sprint·Phase] <任务一句话>`
- ch2: commit message role tag
- ch3: PROGRESS §🔄 表
- ch4: agent 返回 message 第一行 header

### Step 6 — sprint 执行循环

- Implementer 实装
- Reviewer + Tester 双签（per §2.6）
- 按需追加 Security / Reality / SRE 签字
- 若有 ❌ → 退回 Implementer 修
- 全 ✅ 才进入下一步

### Step 7 — Pre-merge：PROGRESS 作为 sprint 分支最后一个 commit

**新工作流**：merge 前**在 sprint 分支上**完成 PROGRESS 更新（不再单独 chore.progress 分支）。

调用 [`my-pm-progress-sync`](../my-pm-progress-sync/SKILL.md) 主路径：

1. 仍在 sprint 分支上，更新 progress.md（移出 §🔄，加 §🟡 验收点，等）
2. `git commit -m "docs(progress): mark <topic> done (Refs #N)"` —— 这是 sprint 分支的**最后一个 commit**
3. `git checkout [MAIN_BRANCH]`
4. `git merge --no-ff [MAIN_BRANCH].<topic> -m "Merge [MAIN_BRANCH].<topic> -> [MAIN_BRANCH]: <what> (Refs #N)"` —— 一次 merge 包含 code + progress
5. `git branch -d [MAIN_BRANCH].<topic>`

**例外**（仍允许 chore.progress 单独分支）:
- 紧急 hotfix 后补 PROGRESS
- 跨 sprint 归档整理

---

## 错误处理

| 场景 | 动作 |
|---|---|
| git status 非 clean | 报用户，**不**自动 stash；等用户决定 |
| `gh` 未装 | 提示用户 `winget install GitHub.cli`（Win）/ `brew install gh`（Mac）+ `gh auth login` |
| 主线落后远端 | `git pull` 同步先（若失败报用户）|
| 用户没说 issue body | 用 §7.9 模板填占位符 + 让用户 review 后再 `gh issue create` |
| H2-pre hook 警告 last commit 未含 progress.md | 退回 Step 7-1/-2 在 sprint 分支上追加 progress commit |

---

## DON'T

- ❌ 不在主线（[MAIN_BRANCH] / main）上 commit（per §7.2 + .githooks/pre-commit 拦）
- ❌ 不直接开 sprint 子分支 skip Issue-First gate（per §7.9）
- ❌ 不在 sprint 分支上 chore.<topic>（必从 [MAIN_BRANCH] 起，避免顺手 merge sprint work）
- ❌ 不在已 merge 的 sprint 分支上做 progress update（用 chore.progress 例外路径）
- ❌ 不 push（用户明示前）
- ❌ 不 chained pipe `checkout && merge`（per §7.5.1，详 `git-workflow.md`）
