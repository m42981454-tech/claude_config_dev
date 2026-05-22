# Git Workflow + Issue 集成

> **Owner**: 主 `CLAUDE.md` §7（Git Workflow）
> **何时 load**: 工作流疑问 / 开 sprint 子分支前 / merge / push / 创建 issue 时

---

## 7. Git Workflow

### 7.1 主线（trunk）定义

- **当前主线**: `[MAIN_BRANCH]`（开发阶段）
- **未来主线**: `main`（首次 merge 到 main 之后切换）
- 任何时刻只有**一条**主线；判断方法：看最新 sprint 文档头部声明的"当前主线"，或 `git log --graph` 上承载最近 merge commit 的那条

### 7.2 强制规则：**不直接 commit 到主线**

- ❌ 不允许在主线（当前 = `[MAIN_BRANCH]`）上直接 `git commit`
- ✅ 所有改动必须先从主线**最新 HEAD** 开新分支：
  - sprint 任务：`[MAIN_BRANCH].ph<N>`（如 `[MAIN_BRANCH].ph13`）
  - bug 修复：`[MAIN_BRANCH].ph<N>.fix<M>`（如 `[MAIN_BRANCH].ph13.fix1`）
  - 杂项 / 文档 / 配置：`[MAIN_BRANCH].chore.<topic>`（如 `[MAIN_BRANCH].chore.handoff-update`）
- ✅ 切换分支前先 `git status` 确认 clean，再 `git checkout [MAIN_BRANCH] && git pull`（如有远端）再 `git checkout -b <new>`
- ✅ merge 回主线统一用 `--no-ff -m "..."`，保留分支拓扑便于回溯
- ✅ merge 后**立刻**删本地临时分支（`git branch -d <name>`）
- ❌ 不 push 远端（除非用户明示）
- ❌ 不 amend；不 rebase 已 merge 的历史；不 force push

> 🤖 **可选 git hook 机器守门**: `.githooks/pre-commit` 直接拒绝主线 commit（详 §7.7.2）

### 7.3 例外（极少数允许直接 commit 主线的场景）

- 只在用户**明确**指示"直接到 [MAIN_BRANCH]"时
- 紧急 hotfix 且时间窗口小于 1 分钟（仍建议 fix 分支）
- 其余情况一律走分支

### 7.4 子分支生命周期

1. PM 收到任务 → `git checkout [MAIN_BRANCH] && git checkout -b [MAIN_BRANCH].<topic>`
2. 设计文档先 commit 到该子分支
3. Implementer / Reviewer / Tester 串行三阶段
4. PM 收尾：split commits（按逻辑：design / backend / frontend / 等）
5. `git checkout [MAIN_BRANCH] && git merge --no-ff [MAIN_BRANCH].<topic> -m "..."`
6. `git branch -d [MAIN_BRANCH].<topic>`

### 7.5 commit 规范

- 每个子任务独立 commit；按逻辑层切片，便于 bisect
- 提交信息聚焦 **why**；bilingual（中文优先 / 英文反引号包代码）
- 在 PM 显式确认前不 commit；永不 push；永不 merge 未经 Review+Test 双签的子分支

### 7.5.1 chained-pipe 防御（重要 — 防错 merge）

**禁止** `git checkout/branch/merge` 与其他命令通过 pipe（`| tail` / `| head` / `| grep` 等）再 chain `&&`：

```bash
# ❌ 错误 — tail 吃 checkout 的 fatal 退出码，&& 仍继续
git checkout BR 2>&1 | tail -2 && git merge --no-ff XX -m "..."
#                ^^^^^^^^^^^^      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#                pipe to tail      被在 wrong branch 上执行（checkout 实际失败）
```

**真实事故模式**（任何项目都可能遭遇）:
- branch checkout 失败 + tail 0 → 误 merge 到错误分支 → 需 `git revert -m 1 <hash>` 抢救
- 同 pattern 重犯：`git revert -m 1 <hash>` + `git revert <hash>` reapply 抢救

**正确写法**（任选其一）:
```bash
# 写法 A — 独立 Bash 调用（推荐；每个命令真退出码可见）
git checkout [MAIN_BRANCH].<topic>
# （单独验证 checkout 成功后再做下一步）
git merge --no-ff [MAIN_BRANCH].<other> -m "..."

# 写法 B — 显式失败传递
git checkout [MAIN_BRANCH].<topic> || exit 1
git merge --no-ff [MAIN_BRANCH].<other> -m "..."

# 写法 C — 不需要 tail 截输出时，直接 chain（checkout 的真退出码会传到 &&）
git checkout [MAIN_BRANCH] && git merge --no-ff <topic> -m "..."
```

**规则**: 涉及 working tree 改变的命令（`checkout` / `merge` / `commit` / `rebase` / `reset`）**不可与输出截断 pipe（`tail` / `head` / `awk`）在 chain 中混用**；若需截输出可在 chain 末尾或独立分开。

### 7.6 当用户说 "启动 ph<N>" 时 PM 的第一动作

```bash
git status                                          # 确认 clean
git checkout [MAIN_BRANCH]                          # 回到主线
git checkout -b [MAIN_BRANCH].ph<N>                 # 开子分支
# 在子分支上写设计文档、派 Implementer、走全流程
```

**绝不**直接在 [MAIN_BRANCH] 上动手。

### 7.7 PROGRESS.md 维护规约（强制）

**文件位置**: `progress.md`（项目根）—— 项目级任务"现在进行 / 已完成 / 待办"单一真相源。

**必须更新的触发点**:

| 触发点 | 改哪段 |
|---|---|
| 新 sprint 启动（开 `[MAIN_BRANCH].ph<N>` 时）| §🔄 进行中 加 sprint 简述（名称 / 范围 / 阶段=design / Blockers）|
| Implementer / Reviewer / Tester 阶段切换 | §🔄 进行中 该 sprint 的"当前阶段"字段（也可推后到 sprint merge 时一并改）|
| sprint merge 进主线（`--no-ff` merge 完成）| §🔄 进行中 移除该 sprint；§🟡 待验收 加验收点；§✅ 已完成 加一行；顶部 codeblock `[最后更新]` / `[当前 sprint]` / `[burning]` 更新（**不再描述 HEAD hash**，per §7.7.1）|
| 发现新待办（sprint 中 reviewer 留 advisory / 用户提新需求 / 等）| §🔴 未完成 对应分组（U / P / L / H）加一行 |
| 用户验收一项后 | §🟡 待验收 划掉那行 |
| 主线名切换（[MAIN_BRANCH] → main）| 顶部 codeblock `[主线名]` 更新 |

**不必每次都更新**:
- 单个 chore 微 commit（如 `docs(typo)` / `chore(format)`）—— 除非引入新待办
- sprint 内部多次 sub-merge（如 fix1 / fix2 同一 sprint 内的 polish）—— 在 sprint 整体 merge 时一并改

**更新方式（强制流程 — PROGRESS update 作为 sprint 分支的最后一个 commit）**:

```bash
# 已在 sprint 分支 [MAIN_BRANCH].<topic> 上，实装 / Review / Test 全部完成

# 1. 在 sprint 分支末尾追加 PROGRESS update commit
git add progress.md
git commit -m "docs(progress): mark <topic> done / 更新 PROGRESS"

# 2. 回主线一次性 merge（code + progress 原子合并）
git checkout [MAIN_BRANCH]
git merge --no-ff [MAIN_BRANCH].<topic> -m "Merge <topic>: <changes summary>"
git branch -d [MAIN_BRANCH].<topic>
```

**与 sprint merge 的关系**: PROGRESS update 是 sprint 分支的**最后一个 commit**，与 sprint 改动**一次 merge** 同时入主线。

**顺序**:

1. sprint 分支跑实装 + Review + Test（每阶段独立 commit）
2. 全部通过后，**在 sprint 分支上**做 `docs(progress): ...` commit 更新 progress.md
3. 一次 `--no-ff` merge 回主线（包含所有 code + progress 改动）
4. 不 push（除非用户明示）

**强制性**: progress.md 必须在**该 sprint 分支的最后一个 commit** 更新 —— 不允许在 merge 后单独做 chore.progress 分支（减少不必要的 merge 操作）；不允许累积多个 sprint 后再批量更新（违反单一真相源原则）。

**例外**（极少数情况允许 sprint merge 后单独 chore.progress 分支）:

- 紧急 hotfix：sprint 已 merge，事后发现需要补 PROGRESS 一条 → 用 `[MAIN_BRANCH].chore.progress-<topic>` 补一次
- 跨 sprint 总结性 PROGRESS 调整（如归档触发后批量整理）→ 用 `[MAIN_BRANCH].chore.progress-archive` 走一次

**Pre-merge 自检清单（PM 在 sprint 合并前必看）**:

- [ ] sprint 分支 last commit 是否包含 `progress.md`？（`git log -1 --name-only` 检查）
- [ ] 顶部 codeblock `[最后更新]` / `[当前 sprint]` / `[burning]` 是否已更新？
- [ ] §🔄 进行中 → 是否已移出该 sprint？
- [ ] §🟡 待验收 → 是否已添加新验收点？

若有任一未做 → 在 sprint 分支上追加 commit 后再 merge。

### 7.7.1 PROGRESS.md 描述边界

**核心原则**: PROGRESS.md 描述**工作状态**（work state），**不描述 git 状态**（git state）。

| 该写 PROGRESS | 不该写 PROGRESS（去 `git` / `gh` 查）|
|---|---|
| 当前 sprint phase（design/impl/review/test/merge）| HEAD commit hash |
| 哪些 issue open / closed（数字）| branch list / push 同步状态 |
| 哪些待用户验收 / 决策 | 远端 sync 状态（ahead/behind）|
| 哪些 burning task / blocker | merge commit hash |
| 测试 baseline 数字 | 工作树 dirty/clean |
| Docker image rebuild 日期 | branch deletion 状态 |
| 主线名 / 活跃容器名（语义）| 任何 hash |

**理由**: PROGRESS.md 描述自己 commit 后才知道的属性 → 必然自指悖论（chore commit 改变 HEAD → 写入的 hash 立即过时 → 想修 → 又 commit → ∞）。

**查 git 实况**: 本文件顶部 codeblock 末尾列权威 cmd（`git log -3` / `git status` / `git branch -a` / `gh issue list`）— 读者按需自查。

### 7.7.2 Git hooks 机器守门（可选）

**位置**: `.githooks/`（项目根）+ `bash .githooks/install.sh` 一键启用。
**原理**: `git config core.hooksPath .githooks`（Git 2.9+），clone 后跑一次 install，跨平台。

**推荐 hooks**:

| Hook | 守门规则 | 关联 |
|---|---|---|
| `pre-commit` | 拒绝直接 commit 到 `[MAIN_BRANCH]` / `main`（允许 merge commit / cherry-pick / revert）| §7.2 |
| `commit-msg` | merge commit subject 必须含 `<src> -> <dst>:` 前缀（非 merge commit 不约束）| commit message 规范 |

**绕过**: `git commit --no-verify`（违反规则，需在 PR/commit 说明理由）。

**Clone 后启用**:

```bash
bash .githooks/install.sh
```

### 7.8 滚动容器启动条件

**绝不**自动开下一个滚动容器（如 `[MAIN_BRANCH].260519`）。开新容器必须**同时**满足以下全部条件，且**用户明示触发**：

| 条件 | 校验方式 |
|---|---|
| **C1 日历日已换** | 当前系统日期 > 当前容器名日期 |
| **C2 当前容器已 merge 主线 + push 远端** | `git log origin/[MAIN_BRANCH]` 含当前容器 merge commit |
| **C3 §🟡 待用户验收段为空 / 所有项已划掉** | PROGRESS §🟡 无未划掉的验收点 |
| **C4 §🔴 待做段无 🔥 阻塞项** | PROGRESS §🔴 当前 sprint 0 Must-Fix-Now |
| **C5 用户明示触发** | 用户说"启动 sprint <日期>" / "开新容器" / 类似明确指令 |

**任一条件不满足**:
- PM 必须**继续在当前容器内**做工作（子分支命名 `[MAIN_BRANCH].<当前容器>.<topic>`）
- 或用 chore 分支（`[MAIN_BRANCH].chore.<topic>`）直接挂主线做跨 sprint 规则/polish

**例外**: 当前容器已 closed（merge 主线 + push）且只是做 polish / chore / hotfix → 用 `[MAIN_BRANCH].chore.<topic>` 直接挂主线，**不开新容器**

**违反后果**: 误开新容器会导致分支拓扑混乱（多容器并存 / 跨容器 commit 漂移）、§🟡 验收项分散到多容器、bisect 困难

---

## 7.9 Bug / Sprint 跟踪 — GitHub Issue 集成

> **触发**: PM 在工作中发现 bug / 测试 fail 真根因 / 用户反馈功能问题 / Review 发现阻塞项 / **开任何 sprint 子分支前**。

### Issue-First 硬性 gate（不可绕过）

| 时机 | 强制动作 | 校验 |
|---|---|---|
| **开 sprint 子分支前**（`[MAIN_BRANCH].<topic>`）| **必先** `gh issue create` label 含 `bug` / `feature` / `chore` 之一，记录 issue url | sprint 首 commit message 末尾必含 `Refs #N` / `Closes #N` |
| **bug 发现时**（测试 fail 真根因 / 用户反馈 / review 阻塞）| 同上，issue body 含复现命令 + 推测根因 + 优先级 | issue 必须**先**于修复 commit 存在 |
| **issue 创建后** | 在 progress.md 对应段加 `[#N](issue-url)` backlink 行 | sprint merge 同时 chore 更新 PROGRESS 一并入 |
| **修复完成时** | issue 评论 commit hash + "已修，等用户确认关闭"；**不**自动 close | 用户验收后才 close |

**违反后果**:
- 没 issue 开了 sprint → PM 必须立刻停 + 补 issue + 在 sprint 后续 commit message 加 `Refs #N`
- 没 issue 直接 commit fix → 必须新 commit 补 backlink（或在 sprint merge commit message 加）
- chore 分支（progress / docs / config polish）— issue 可选，但**规则变更 / CLAUDE.md 改动必须开**

**例外**（允许后置创建 issue）:
- 紧急 hotfix（< 5 分钟动作）— commit 后立刻补 issue + 在下一个 commit 加 `Refs #N`

**为什么强制**（karpathy Goal-Driven）:
- sprint 必须有可验证的成功标准 — issue 是承载该标准 + 横向追踪 + 团队对齐的唯一真相源
- 防止"开分支就动手"绕过追溯；每个 sprint 离开 worktree 后，issue 是后人接力的入口

---

**优先方式**: 用 `gh` CLI 自动创建 issue。如 `gh` 未装，提示用户:

```bash
winget install GitHub.cli       # Windows
brew install gh                 # macOS
gh auth login                   # 一次性配 PAT
```

**Issue 创建规约**:

```bash
gh issue create \
  --title "[bug] <模块>: <一句话描述>" \
  --label "bug" \
  --body "$(cat <<'EOF'
## 复现步骤
1. ...

## 期望 vs 实际
- 期望：...
- 实际：...

## 上下文
- commit：`<hash>`
- 文件：`path:line`
- 分支：`<branch>`

## 推测根因
...

## 建议优先级
🔥 阻塞 / ⚡ 高 / ⏳ 中 / 🧹 低
EOF
)"
```

> `gh issue create` 不带 `--repo` 时使用 `gh repo` 默认（git remote `origin`）。需指定时加 `--repo [REPO_OWNER]/[REPO_NAME]`。

**Issue 标题规范**: `[bug] <模块>: <一句话>` （例：`[bug] auth router: missing tenant_id validation`）

**创建后**:

- 在 PROGRESS §🔴 加引用 `[#N](issue-url)` 行
- 不在用户明示前关闭 issue（PM 只能创建 + 评论；关闭由用户做）
- 如 bug 已修，在 issue 上评论 commit hash + "已修，等用户确认关闭"

**禁止**:

- 不批量创建 issue（每次 PM 发现 1 个 bug 单独 1 issue）
- 不在 issue body 包含 secrets / API key / sensitive payload
- 不在 PR / commit message 引用未创建的 issue 号（等 issue 创建后再 backlink）
