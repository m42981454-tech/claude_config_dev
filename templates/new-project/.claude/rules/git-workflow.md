# Git Workflow + Issue 集成

> **Owner**: 主 `CLAUDE.md` §7 + §7.9(本文件由 chore `CLAUDE.md restructure Phase 2` 从主文件拆出,refs [#21](https://github.com/m42981454-tech/doc/issues/21))
> **何时 load**:工作流疑问 / 开 sprint 子分支前 / merge / push / 创建 issue 时
> **保留章节编号**:沿用 §7.x / §7.9(cross-ref 兼容)

---

## 7. Git Workflow

### 7.1 主线（trunk）定义
- **当前主线**：`feature/dev`（开发阶段）
- **未来主线**：`main`（feature/dev 第一次 merge 到 main 之后切换）
- 任何时刻只有**一条**主线；判断方法：看最新 sprint 文档头部声明的"当前主线"，或 git log --graph 上承载最近 merge commit 的那条

### 7.2 强制规则：**不直接 commit 到主线**
- ❌ 不允许在主线（当前 = `feature/dev`）上直接 `git commit`
- ✅ 所有改动必须先从主线**最新 HEAD** 开新分支：
  - sprint 任务：`feature/dev.ph<N>`（如 `feature/dev.ph13`）
  - bug 修复：`feature/dev.ph<N>.fix<M>`（如 `feature/dev.ph13.fix1`）
  - 杂项 / 文档 / 配置：`feature/dev.chore.<topic>`（如 `feature/dev.chore.handoff-update`）
- ✅ 切换分支前先 `git status` 确认 clean，再 `git checkout feature/dev && git pull`（如有远端）再 `git checkout -b <new>`
- ✅ merge 回主线统一用 `--no-ff -m "..."`，保留分支拓扑便于回溯
- ✅ merge 后**立刻**删本地临时分支（`git branch -d <name>`）
- ❌ 不 push 远端（用户明示）
- ❌ 不 amend；不 rebase 已 merge 的历史；不 force push

> 🤖 **2026-05-19 起 git hook 机器守门**:`.githooks/pre-commit` 直接拒绝主线 commit(详 §7.7.2)。

### 7.3 例外（极少数允许直接 commit 主线的场景）
- 只在用户**明确**指示"直接到 feature/dev"时
- 紧急 hotfix 且时间窗口小于 1 分钟（仍建议 fix 分支）
- 其余情况一律走分支

### 7.4 子分支生命周期
1. PM 收到任务 → `git checkout feature/dev && git checkout -b feature/dev.<topic>`
2. 设计文档先 commit 到该子分支
3. Implementer / Reviewer / Tester 串行三阶段
4. PM 收尾：split commits（按逻辑：design / backend / admin-next / portal-next 等）
5. `git checkout feature/dev && git merge --no-ff feature/dev.<topic> -m "..."`
6. `git branch -d feature/dev.<topic>`

### 7.5 commit 规范
- 每个子任务独立 commit；按逻辑层切片，便于 bisect
- 提交信息聚焦 **why**；bilingual（中文优先 / 英文反引号包代码）
- 在 PM 显式确认前不 commit；永不 push；永不 merge 未经 Review+Test 双签的子分支

### 7.5.1 chained-pipe 防御(2026-05-19 加 — refs [#15](https://github.com/m42981454-tech/doc/issues/15))

**禁止** `git checkout/branch/merge` 与其他命令通过 pipe(`| tail` / `| head` / `| grep` 等)再 chain `&&`:

```bash
# ❌ 错误 — tail 吃 checkout 的 fatal 退出码,&& 仍继续
git checkout BR 2>&1 | tail -2 && git merge --no-ff XX -m "..."
#                ^^^^^^^^^^^^      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#                pipe to tail      被在 wrong branch 上执行(checkout 实际失败)
```

**事故记录**(2 次违反 / 2 次 revert 抢救):
- 2026-05-18 chore.progress-t1t3t4 误把 sprint N3 work merge 进 feature/dev(branch checkout 失败 + tail 0 → 错 merge)→ `git revert -m 1 381a51e`
- 2026-05-19 chore.merge-N1-bk-audit-fix 同 pattern → `git revert -m 1 92fdb29` + `git revert 5dd349b` reapply 抢救

**正确写法**(任选其一):
```bash
# 写法 A — 独立 Bash 调用(推荐;每个命令真退出码可见)
git checkout feature/dev.260518.XX
# (单独验证 checkout 成功后再做下一步)
git merge --no-ff feature/dev.YY -m "..."

# 写法 B — 显式失败传递
git checkout feature/dev.260518.XX || exit 1
git merge --no-ff feature/dev.YY -m "..."

# 写法 C — 不需要 tail 截输出时,直接 chain(checkout 的真退出码会传到 &&)
git checkout feature/dev && git merge --no-ff XX -m "..."
```

**规则**:涉及 working tree 改变的命令(`checkout` / `merge` / `commit` / `rebase` / `reset`)**不可与输出截断 pipe(`tail` / `head` / `awk`)在 chain 中混用**;若需截输出可在 chain 末尾或独立分开。

### 7.6 当用户说 "启动 ph<N>" 时 PM 的第一动作
```bash
git status                                          # 确认 clean
git checkout feature/dev                            # 回到主线
git checkout -b feature/dev.ph<N>                   # 开子分支
# 在子分支上写设计文档、派 Implementer、走全流程
```
**绝不**直接在 feature/dev 上动手。

### 7.7 PROGRESS.md 维护规约（强制）

**文件位置**：`20260403/plan1a-kong/PROGRESS.md` —— 项目级任务"现在进行 / 已完成 / 待办"单一真相源。

**必须更新的触发点**：

| 触发点 | 改哪段 |
|---|---|
| 新 sprint 启动（开 `feature/dev.ph<N>` 时） | §🔄 进行中 加 sprint 简述（名称 / 范围 / 阶段=design / Blockers） |
| Implementer / Reviewer / Tester 阶段切换 | §🔄 进行中 该 sprint 的"当前阶段"字段（也可推后到 sprint merge 时一并改） |
| sprint merge 进主线（`--no-ff` merge 完成） | §🔄 进行中 移除该 sprint；§🟡 待验收 加验收点；§✅ 已完成 加一行含 merge commit hash；顶部 codeblock `[最后更新]` / `[当前 sprint]` / `[burning]` 更新（**不再描述 HEAD hash**,2026-05-19 起 — 详 §7.7.1） |
| 发现新待办（sprint 中 reviewer 留 advisory / 用户提新需求 / 等） | §🔴 未完成 对应分组（U / P / L / H）加一行 |
| 用户验收一项后 | §🟡 待验收 划掉那行 |
| 主线名切换（feature/dev → main） | 顶部 codeblock `[主线名]` + §🔴 H2 项标记完成 |

**不必每次都更新**：
- 单个 chore 微 commit（如 `docs(typo)` / `chore(format)`）—— 除非引入新待办
- sprint 内部多次 sub-merge（如 fix1 / fix2 同一 sprint 内的 polish）—— 在 sprint 整体 merge 时一并改

**更新方式（强制流程）**：
```bash
# 1. 走 chore 分支（不直接 commit 主线）
git checkout feature/dev
git checkout -b feature/dev.chore.progress-ph<N>

# 2. 编辑 PROGRESS.md

# 3. commit + 回主线 --no-ff merge + 删分支
git add 20260403/plan1a-kong/PROGRESS.md
git commit -m "docs(progress): mark ph<N> done / 更新 PROGRESS"
git checkout feature/dev
git merge --no-ff feature/dev.chore.progress-ph<N> -m "Merge progress update ph<N>"
git branch -d feature/dev.chore.progress-ph<N>
```

**与 sprint merge 的关系**：sprint merge 与 PROGRESS update 是**两次独立 merge**（保证 sprint 改动与 PROGRESS 改动可分离 review / 可 bisect）。顺序：
1. 先 merge sprint 分支（实装 + 测试 + docs/ 设计文档）
2. **紧接着**开 chore.progress-ph<N> 分支更新 PROGRESS.md
3. merge chore 分支
4. 两次都不 push

**强制性**：sprint merge 后**必须**立刻做 PROGRESS update —— 不允许累积多个 sprint 后再批量更新（违反单一真相源原则）。

### 7.7.1 PROGRESS.md 描述边界(2026-05-19 加,refs [#20](https://github.com/m42981454-tech/doc/issues/20))

**核心原则**:PROGRESS.md 描述**工作状态**(work state),**不描述 git 状态**(git state)。

| 该写 PROGRESS | 不该写 PROGRESS(去 `git` / `gh` 查) |
|---|---|
| 当前 sprint phase(design/impl/review/test/merge) | HEAD commit hash |
| 哪些 issue open / closed(数字) | branch list / push 同步状态 |
| 哪些待用户验收 / 决策 | 远端 sync 状态(ahead/behind) |
| 哪些 burning task / blocker | merge commit hash |
| 测试 baseline 数字(1815/0/44) | 工作树 dirty/clean |
| Docker image rebuild 日期 | branch deletion 状态 |
| 主线名 / 活跃容器名(语义) | 任何 hash |

**理由**:PROGRESS.md 描述自己 commit 后才知道的属性 → 必然自指悖论(chore commit 改变 HEAD → 写入的 hash 立即过时 → 想修 → 又 commit → ∞)。详 `docs/postmortems/2026-05-19_progress-self-reference-paradox.md`。

**查 git 实况**:本文件顶部 codeblock 末尾列了权威 cmd(`git log -3` / `git status` / `git branch -a` / `gh issue list`)— 读者按需自查。

### 7.7.2 Git hooks 机器守门(2026-05-19 加,refs [#20](https://github.com/m42981454-tech/doc/issues/20))

**位置**:`.githooks/`(项目根)+ `bash .githooks/install.sh` 一键启用。
**原理**:`git config core.hooksPath .githooks`(Git 2.9+),clone 后跑一次 install,跨平台。

**当前 hooks**:

| Hook | 守门规则 | 关联 |
|---|---|---|
| `pre-commit` | 拒绝直接 commit 到 `feature/dev` / `main`(允许 merge commit / cherry-pick / revert) | §7.2 |
| `commit-msg` | merge commit subject 必须含 `<src> -> <dst>:` 前缀(非 merge commit 不约束) | user memory rule "Merge message 必带 src→dst" |

**绕过**:`git commit --no-verify`(违反规则,需在 PR/commit 说明理由)。

**Clone 后启用**:
```bash
bash .githooks/install.sh
```

**详**:`.githooks/README.md`。

### 7.8 滚动容器启动条件（2026-05-18 加强）

**绝不**自动开下一个滚动容器（如 `feature/dev.260519`）。开新容器必须**同时**满足以下全部条件，且**用户明示触发**：

| 条件 | 校验方式 |
|---|---|
| **C1 日历日已换** | 当前系统日期 > 当前容器名日期（如今天 2026-05-18,容器是 260518 → 不开;明天 2026-05-19+ → 才允许开） |
| **C2 当前容器已 merge 主线 + push 远端** | `git log origin/feature/dev` 含当前容器 merge commit |
| **C3 §🟡 待用户验收段为空 / 所有项已划掉** | PROGRESS §🟡 无未划掉的验收点 |
| **C4 §🔴 待做段无 🔥 阻塞项** | PROGRESS §🔴 当前 sprint 0 Must-Fix-Now |
| **C5 用户明示触发** | 用户说"启动 sprint <日期>" / "开新容器" / 类似明确指令 |

**任一条件不满足**：
- PM 必须**继续在当前容器内**做工作(子分支命名 `feature/dev.<当前容器>.<topic>`)
- 或用 chore 分支(`feature/dev.chore.<topic>`)直接挂主线做跨 sprint 规则/polish

**例外**：
- 当前容器已 closed(merge 主线 + push)且只是做 polish / chore / hotfix → 用 `feature/dev.chore.<topic>` 直接挂主线,**不开新容器**

**违反后果**:误开新容器会导致:
- 分支拓扑混乱（多容器并存 / 跨容器 commit 漂移）
- §🟡 验收项分散到多容器,用户验收时找不到
- bisect 困难

---

## 7.9 Bug / Sprint 跟踪 — GitHub Issue 集成（2026-05-18 加;2026-05-18 加强:sprint 开分支前必先 issue）

> **触发**:PM 在工作中发现 bug / 测试 fail 真根因 / 用户反馈功能问题 / Review 发现阻塞项 / **开任何 sprint 子分支前**。

### Issue-First 硬性 gate（不可绕过）

| 时机 | 强制动作 | 校验 |
|---|---|---|
| **开 sprint 子分支前**(`feature/dev.<topic>` / `feature/dev.260YYY.<topic>`) | **必先** `gh issue create` label 含 `bug` / `feature` / `chore` 之一,记录 issue url | sprint 首 commit message 末尾必含 `Refs #N` / `Closes #N` |
| **bug 发现时**(测试 fail 真根因 / 用户反馈 / review 阻塞) | 同上,issue body 含复现命令 + 推测根因 + 优先级 | issue 必须**先**于修复 commit 存在 |
| **issue 创建后** | 在 PROGRESS.md 对应段加 `[#N](issue-url)` backlink 行 | sprint merge 同时 chore 更新 PROGRESS 一并入 |
| **修复完成时** | issue 评论 commit hash + "已修,等用户确认关闭";**不**自动 close | 用户验收后才 close |

**违反后果**:
- 没 issue 开了 sprint → PM 必须立刻停 + 补 issue + 在 sprint 后续 commit message 加 `Refs #N`
- 没 issue 直接 commit fix → 必须新 commit 补 backlink(或在 sprint merge commit message 加)
- chore 分支(progress / docs / config polish)— issue 可选,但**规则变更/CLAUDE.md 改动必须开**

**例外**(允许后置创建 issue):
- 紧急 hotfix(< 5 分钟动作)— commit 后立刻补 issue + 在下一个 commit 加 `Refs #N`

**为什么强制**(karpathy Goal-Driven):
- sprint 必须有可验证的成功标准 — issue 是承载该标准 + 横向追踪 + 团队对齐的唯一真相源
- 防止"开分支就动手"绕过追溯;每个 sprint 离开 worktree 后,issue 是后人接力的入口

---

**优先方式**:用 `gh` CLI 自动创建 issue。如 `gh` 未装,提示用户:
```bash
winget install GitHub.cli       # Windows
brew install gh                 # macOS
gh auth login                   # 一次性配 PAT
```

**Issue 创建规约**:

```bash
gh issue create \
  --repo m42981454-tech/doc \
  --title "[bug] <模块>: <一句话描述>" \
  --label "bug" \
  --body "$(cat <<'EOF'
## 复现步骤
1. ...

## 期望 vs 实际
- 期望:...
- 实际:...

## 上下文
- commit:`<hash>`
- 文件:`path:line`
- 分支:`<branch>`

## 推测根因
...

## 建议优先级
🔥 阻塞 / ⚡ 高 / ⏳ 中 / 🧹 低
EOF
)"
```

**Issue 标题规范**:`[bug] <模块>: <一句话>` (例:`[bug] chat router: _stream_with_accounting 多传 quota_service`)

**创建后**:
- 在 PROGRESS §🔴 加引用 `[#N](issue-url)` 行
- 不在用户明示前关闭 issue(PM 只能创建 + 评论;关闭由用户做)
- 如 bug 已修,在 issue 上评论 commit hash + "已修,等用户确认关闭"

**禁止**:
- 不批量创建 issue(每次 PM 发现 1 个 bug 单独 1 issue)
- 不在 issue body 包含 secrets / API key / sensitive payload
- 不在 PR / commit message 引用未创建的 issue 号(等 issue 创建后再 backlink)

仓库:`https://github.com/m42981454-tech/doc`
