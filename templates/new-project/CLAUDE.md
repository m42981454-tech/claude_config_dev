# [PROJECT_NAME] — Project Conventions

> 当前阶段：**[PHASE]**（截至 [DATE]）
> [Brief phase description]

---

## 1. 仓库结构（关键路径）

```
[project-root]/
├── [backend-dir]/              # [BACKEND_STACK] 后端
│   ├── app/                    # 应用模块
│   ├── tests/                  # 测试套件
│   ├── docs/                   # 后端文档
│   └── ...
├── [frontend-dir]/             # [FRONTEND_STACK] 前端
│   ├── app/                    # 页面
│   ├── components/             # 组件
│   ├── lib/                    # 工具库
│   └── ...
├── docs/                       # 项目级文档
├── docker-compose.dev.yml      # 本地开发栈（如有）
├── progress.md                 # ★ 任务状态唯一真相源
└── CLAUDE.md                   # 本文件
```

不要碰：[列出旧/废弃/不属于当前工作目标的目录]

---

## 2. 技术栈（概述）

- **后端**：[BACKEND_STACK]（详见 [`.claude/rules/backend.md`](./.claude/rules/backend.md)，工作在 `[backend-dir]/` 时自动加载）
- **前端**：[FRONTEND_STACK]（详见 [`.claude/rules/frontend.md`](./.claude/rules/frontend.md)，工作在 `[frontend-dir]/` 时自动加载）
- **基础设施**：[INFRA]

---

## 3. 当前任务与状态

状态唯一真相源：**`progress.md`**（根目录）。

| ID | 任务 | 状态 |
|---|---|---|
| | | |

---

## 4. Agent / Team 分工

**默认**：当前会话（PM）自己处理，不开子代理。
**例外**：用户明确要求 team 处理 / 并行执行时，派项目级 agent。

### 角色（定义见 [`.claude/agents/`](./.claude/agents/)）

| Role | subagent_type | Model | 工具权限（frontmatter `tools:` 锁定） |
|---|---|---|---|
| **PM** | (当前会话) | opus | * |
| **Implementer** | `implementer` | sonnet | Read / Glob / Grep / Bash / Edit / MultiEdit / Write |
| **Reviewer** | `reviewer` | sonnet | Read / Glob / Grep / Bash（**无** Edit/Write，只读） |
| **Tester** | `tester` | haiku | Read / Glob / Grep / Bash（**无** Edit/Write，只读） |

工具权限由 agent 文件 frontmatter 锁定 → Reviewer / Tester 即使想"小修一下"也写不了文件（deterministic）。

### 派单规则

- 独立任务：同一消息内并行多个 `Agent` call
- 串行依赖：实装 → Review → 测试，不可并行
- Tester 不修代码（工具权限已锁），只报 bug 给 PM；PM 再派 Implementer 修 → Tester 重测

### 派单模板

```
Agent({
  description: "<动词 + 短描述>",
  subagent_type: "implementer",   // 或 reviewer / tester
  prompt: "上下文：...（文件路径 + 行号 + 相关规范）。
           任务：...（明确动作，最小变更范围）。
           验收：...（pytest 命令 / 期望测试通过）。
           完成后报告：变更文件清单 + 测试结果。"
})
```

> Model 在 agent frontmatter 已定，调用时不必再指定。

---

## 5. Engineering rules — Always invoke `karpathy-guidelines` skill

详见 [`.claude/rules/engineering.md`](./.claude/rules/engineering.md)。要点：

- **强制 trigger 时机**：写新代码 / Review diff / Refactor / 用户明示
- **4 原则**：Think Before Coding → Simplicity First → Surgical Changes → Goal-Driven Execution
- **全角色共同行为基础**：PM / Implementer / Reviewer / Tester 都遵循

---

## 6. 测试要求（通用原则）

- 不删除既有测试，不用 `@pytest.mark.skip` 或 `test.skip` 绕过失败
- 影响共享契约 / 路由 / API client / UI shell 的变更，必须扩大验证范围
- E2E 浏览器验证时，console 无 error 循环才算通过
- 具体命令：后端见 [`.claude/rules/backend.md`](./.claude/rules/backend.md)，前端见 [`.claude/rules/frontend.md`](./.claude/rules/frontend.md)

---

## 7. Git Workflow

详细规则见 [`.claude/rules/git-workflow.md`](./.claude/rules/git-workflow.md)。要点：

- **主线**：`[MAIN_BRANCH]`（PR → `main`）
- ❌ 不直接 commit 主线 — 所有改动开子分支 `[MAIN_BRANCH].<topic>`（`.ph<N>` / `.fix<M>` / `.chore.<topic>`）
- ✅ merge 用 `--no-ff -m "..."`，merge 后立刻 `git branch -d <name>` 删临时分支
- ❌ 不 push 远端 / 不 amend 已 push / 不 rebase 已 merge / 不 force push
- ✅ 每次 merge 后立即走 `[MAIN_BRANCH].chore.progress` 子分支更新 `progress.md`
- ✅ 并行多个独立任务时用 git worktree 隔离（详见上述文件 §7），避免同目录双 Claude 互踩

---

## 8. 开发命令速查

见 [`.claude/rules/dev-commands.md`](./.claude/rules/dev-commands.md)（docker compose / 测试 / type-check / 迁移 等）。

> 该文件不在模板内，按项目实际命令创建。

---

## 9. 不要做（DON'T）

- ❌ 不删除既有测试或用 skip 绕过失败
- ❌ 不绕过 hooks（`--no-verify` / `--no-gpg-sign`）
- ❌ 不在 UI/API 变更后留下持续刷新的 console error 循环
- ❌ 不在修复聚焦问题时顺手做大范围重构
- ❌ 不直接 commit 到主线——所有改动必须先开子分支（见 §7）
- ❌ sprint merge 后不更新 progress.md 就开始下个任务
- ❌ 不 push 远端（除非用户明确要求）
