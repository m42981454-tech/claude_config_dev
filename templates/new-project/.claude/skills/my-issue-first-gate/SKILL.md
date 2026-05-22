---
name: my-issue-first-gate
description: 开 sprint 子分支前必先创建 GitHub issue — 当用户说"创建 issue" / "gh issue create" / "Issue-First" / 准备开 sprint 时使用。包含 title 格式 / body 模板 / PROGRESS backlink 强制。
---

# my-issue-first-gate

> **作用**：§7.9 Issue-First gate 强制条款封装 — 开 sprint 子分支前必先 `gh issue create`，首 commit 必含 `Refs #N`
> **触发**：auto-match `创建 issue` / `gh issue` / Issue-First 提示后 / [`my-start-sprint`](../my-start-sprint/SKILL.md) Step 2 内部调用
> **关联规约**: [`.claude/rules/git-workflow.md §7.9`](../../rules/git-workflow.md)

---

## Issue-First 硬性 gate（不可绕过）

| 时机 | 强制动作 | 校验 |
|---|---|---|
| 开 sprint 子分支前（`[MAIN_BRANCH].<topic>`）| **必先** `gh issue create` label 含 `bug` / `feature` / `chore` 之一 | sprint 首 commit message 末尾必含 `Refs #N` / `Closes #N` |
| bug 发现时（测试 fail / 用户反馈 / review 阻塞）| 同上 | issue 必须**先**于修复 commit 存在 |
| issue 创建后 | PROGRESS 对应段加 `[#N](issue-url)` backlink | sprint merge 同时该 commit 一并入（per progress-conventions.md）|
| 修复完成时 | issue 评论 commit hash + "等用户确认关闭" | **不**自动 close（只 comment）|

**违反后果**:
- 没 issue 开 sprint → PM 必须立刻停 + 补 issue + 在后续 commit 加 `Refs #N`
- 没 issue 直接 commit fix → 必须新 commit 补 backlink

**例外**：紧急 hotfix（< 5 min 动作）— commit 后立刻补 issue + 在下个 commit 加 `Refs #N`

---

## Issue 创建标准模板

### Title 规范

```
[<type>] <模块>: <一句话描述>
```

- `<type>`: `bug` / `feature` / `chore` / `security`（label 同名 — 但注意 GitHub 默认 label 名差异，详下文）
- `<模块>`: 例 `auth router` / `migration` / `monitoring` / `docs`
- 例：`[bug] auth router: missing tenant_id validation`

### Body 模板

```bash
gh issue create \
  --title "[<type>] <模块>: <一句话>" \
  --label "<bug|enhancement|chore|security>" \
  --body "$(cat <<'EOF'
## 背景
为什么这件事要做（动机 / 触发场景 / 用户痛点）

## 复现步骤（bug 必填）
1. ...
2. ...

## 期望 vs 实际（bug 必填）
- 期望：...
- 实际：...

## Scope（chore / feature 必填）
- 文件：`path:line`
- 范围：...

## 推测根因（bug）/ 决策依据（chore）
...

## 验收
- 测试命令 + 期望数字（若有）
- UI 验证步骤（若 frontend）
- 关键 file:line 改动

## 不做（deferred）
...

## 优先级
🔥 阻塞 / ⚡ 高 / ⏳ 中 / 🧹 低
EOF
)"
```

> `gh issue create` 不带 `--repo` 时使用 `gh repo` 默认（git remote `origin`）。如需指定其他仓库加 `--repo [REPO_OWNER]/[REPO_NAME]`。

### 关键 label 注意事项（GitHub 默认 vs 自定义）

| label | 何时用 | 注意 |
|---|---|---|
| `bug` | 测试 fail 真根因 / 用户反馈功能问题 / production incident | GitHub 默认存在 |
| `enhancement` | 新功能 / 增强 / sprint 启动 | **GitHub 默认 label；不是 `feature`** — 若想用 `feature` 需 `gh label create feature` |
| `chore` | docs / 重构 / 规则变更 / polish 不改功能 | 需要 `gh label create chore` |
| `security` | 鉴权 / 权限 / 加密 / OWASP-relevant 改动 | 需要 `gh label create security` |
| `documentation` | 纯文档（与 chore 区分）| GitHub 默认存在 |

**铁律**：**新 sprint 前先 `gh label list` 确认 label 存在**（不存在用 `gh label create` 加，或选语义最近的）。

**Fallback**：若 `gh issue create --label X` 报 `'X' not found`，改用 `enhancement` / `chore` 或 `gh label list` 看现有。

---

## 创建后必做

1. **记 issue URL** + `#N` 编号
2. **在 progress.md 对应段加 backlink** `[#N](issue-url)` 行
3. **首 commit message 末尾含 `Refs #N`**（sprint 子分支）
4. **不**在用户明示前 close issue（PM 只 comment）
5. **修复完成时**：issue 评论 commit hash + "已修，等用户确认关闭" → 用户验收后才 close

---

## 工具未装

```bash
# Windows
winget install GitHub.cli

# macOS
brew install gh

# 后续（一次性）
gh auth login
```

---

## DON'T

- ❌ 不在 issue body 含 secrets / API key / sensitive payload
- ❌ 不批量创建 issue（1 bug = 1 issue）
- ❌ 不在 PR / commit 引用未创建的 issue 号（等 issue 创建后再 backlink）
- ❌ 不**自动 close** issue（只 comment；关闭由用户做）
- ❌ 不用 issue body 描述比 title 还短（body 必含背景 + 复现 / scope + 验收 + 优先级）
- ❌ chore 分支看似 "issue 可选" 但**规则变更 / CLAUDE.md 改动 / .claude/rules/ 改动 必开 issue**
