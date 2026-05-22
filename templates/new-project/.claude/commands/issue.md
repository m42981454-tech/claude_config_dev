---
description: 创建 GitHub issue（Issue-First gate 格式）— 开 sprint 前 / 发现 bug 时
allowed-tools: Bash, Edit, Read, Skill
---

# /issue

按 `git-workflow.md §7.9` 格式创建 GitHub issue，并在 `progress.md` 添加 backlink。

## Usage

```
/issue                          # 从对话上下文推断类型和描述
/issue bug auth 登录后 token 过期  # bug issue
/issue feature 添加导出 CSV 功能   # 功能需求
/issue chore 升级依赖到最新版       # 维护任务
```

## 步骤

**Step 1 — 确认 gh 可用**

```bash
gh auth status
```

不可用时提示用户先运行 `gh auth login`，并停止执行。

**Step 2 — 推断参数**

从 `$ARGUMENTS` 解析：
- 第一个词为 `bug` / `feature` / `chore` → 作为 type；其余为描述
- 无 type → 默认 `bug`
- 无描述 → 从对话上下文推断，向用户确认后再创建

**Step 3 — 创建 issue**

```bash
gh issue create \
  --title "[<type>] <模块>: <描述>" \
  --label "<type>" \
  --body "$(cat <<'BODY'
## 复现步骤
1. ...

## 期望 vs 实际
- 期望：...
- 实际：...

## 上下文
- branch: $(git branch --show-current)
- file: <path:line>

## 推测根因
...

## 优先级
⏳ 中
BODY
)"
```

**Step 4 — 更新 progress.md**

Read `progress.md`，在 `§🔴 待做` 对应分组（`U` / `P` / `L` / `H`）追加：

```
- ⏳ [#N](<issue-url>) <描述>
```

**Step 5 — 输出摘要**

```
✅ Issue #N 已创建：<url>
   progress.md §🔴 已更新
   下一步：/sprint:start 时在首个 commit message 末尾加 Refs #N
```

## $ARGUMENTS

`[type] [description]`（均可省略，省略时从上下文推断）

## 关联

- `.claude/rules/git-workflow.md §7.9`
- skill `my-issue-first-gate`（完整 Issue-First gate SOP）
- `/sprint:start`（开 sprint 前调用本命令）
