# Claude Code 全局基础策略

> 跨项目通用基线。项目级 `CLAUDE.md` 可在此之上覆盖或扩展。

---

## 1. 沟通语言

- 默认使用**中文**与用户沟通（提问、回答、说明、建议）
- 代码、变量名、命令使用英文
- 提交信息主体用中文，技术术语用英文反引号包裹

---

## 2. Session & Context 管理

### 三条铁律

1. **Context 隔离靠客户端多开 + git worktree**，不靠对话内分裂（subagent 必回归，不算独立 session）
2. **跨 session 续接靠 `progress.md` + `memory/` + `CLAUDE.md`**，不死守同一 session
3. **重输出（长日志 / 大搜索 / 全文件 dump）一律派 subagent**，主会话只收摘要

### 场景对应

| 场景 | 做法 |
|---|---|
| 同任务深入，context 渐胀 | `/compact <保留要点>` |
| 并行多个独立任务 | 多开 Claude 面板 + `git worktree` 隔离 |
| 任务切换（串行） | 更新 `progress.md` → `/clear` 或新 session |
| 重调研 / 大日志 | 派 `Explore` / `general-purpose` subagent |
| 历史续接 | `claude --resume <id>` |

### 每项目必备三件套

- **`CLAUDE.md`**：项目约定、分工、禁止事项（稳定不变的规则）
- **`progress.md`**：任务状态唯一真相源（merge 后立即更新）
- **`memory/`**：跨 session 的用户偏好 / 外部资源指针（非代码可推导的信息）

### 关键纪律

- `/compact` 永远带提示词，明确指明保留什么
- sprint / 任务完成立即更新 `progress.md` 再开下个 session
- 派 subagent 时明确"只报摘要，不回灌原始输出"
- **永远不在同目录同时跑两个 Claude**（并行 = 不同 worktree + 不同 session）

---

## 3. 优先级声明（冲突时）

1. 用户明确指示
2. 项目级 `CLAUDE.md`
3. 本全局基础策略
4. 默认系统提示

---

## 4. 通用 Git Workflow 基线

- 不直接 commit 到主线（除非用户明确指示），所有改动走子分支
- merge 用 `--no-ff` 保留拓扑
- 不绕过 hooks（`--no-verify` / `--no-gpg-sign`）
- 不 amend 已 push 历史，不 rebase 已 merge 历史，不 force push
- commit 前先 `git status` / `git diff`，只 stage 当前任务相关文件

具体分支命名 / 主线名 / PR 目标由项目级 `CLAUDE.md` 定义。

---

## 5. 通用测试纪律

- 不删除既有测试，不用 skip 标记绕过失败
- 完成声明前**真跑命令验证**，evidence before assertions
- 影响共享契约 / 路由 / API client / UI shell 的变更要扩大验证范围

---

## 6. Plugin 配置

按需安装、tier 分级、冲突边界详见以下文件（通过 `@import` 自动加载）：

- @~/.claude/rules/plugins.md

---

## 7. Superpowers Skill 强制触发规则

以下触发条件**不可绕过**，优先级高于 skill 内部的自判断逻辑。

### 7.1 brainstorming — 必须触发的场景

用户消息满足以下任一条件时，**在回复之前必须先调用 `superpowers:brainstorming`**：

- 提出新功能 / 新模块 / 新系统的需求（"我想做 X" / "能否支持 Y" / "帮我设计 Z"）
- 询问"应该怎么做" / "如何实现" / "有什么方案"（设计讨论类）
- 启动任何 sprint / 任务前（"开始 phN" / "启动 XXX 功能"）
- 用户说"brainstorm" / "讨论一下" / "想听你的建议"

**禁止**：不得在 brainstorming 完成并获得用户批准前开始实现或写代码。

### 7.2 writing-plans — 必须触发的场景

- brainstorming skill 完成、用户批准设计后 → **必须调用 `superpowers:writing-plans`**
- 用户说"写计划" / "制定实施计划" / "出 plan"

### 7.3 不触发的场景

- 纯事实问答（"这个函数做什么" / "文件在哪里"）
- bug 修复（走 `superpowers:systematic-debugging`）
- 已有明确 plan 的执行阶段（走 `superpowers:executing-plans`）
