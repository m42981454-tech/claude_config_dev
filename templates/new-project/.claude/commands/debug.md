---
description: 系统化调试 SOP（最小假设 → 验证 → 最小修复，基于 karpathy Surgical Changes 原则）
allowed-tools: Bash, Read, Grep, Glob, Edit
---

# /debug

系统化 bug 排查 SOP。每步不可跳过：**先定位，再假设，再修复**。
违反顺序容易陷入"猜着改"循环，造成更多破坏。

## Usage

```
/debug                           # 从当前对话上下文推断问题
/debug TypeError: cannot read    # 直接输入报错信息
/debug src/auth/token.py:42      # 指定出错位置
```

## 步骤（顺序不可跳）

**Step 1 — 复现（Reproduce）**

- 确认能稳定复现的最小步骤
- 获取**完整** error message / stack trace / HTTP response body
  - 不接受"大概是这样"，必须看到原始输出
- 记录：环境 / 分支 / 触发操作

**Step 2 — 定位（Locate）**

```bash
# 从报错关键词出发
grep -rn "<error-keyword>" src/
```

- 找到出错文件和确切行号
- 阅读出错函数**完整**上下文（不只看报错那行）
- 往上追调用链：谁传入了这个值？入参是什么？

**Step 3 — 假设（Hypothesize）**

列出 **≥ 2 个**可能根因（不急着动手改）：

| # | 假设 | 验证方式 | 成本 |
|---|---|---|---|
| 1 | ... | ... | 低/中/高 |
| 2 | ... | ... | ... |

选验证成本最低的假设先测。

**Step 4 — 验证（Verify）**

- 用最小代价验证假设：加一行 log / 加断言 / 改单行测试
- **不在验证阶段同时改多处**
- 假设被推翻 → 回 Step 3 选下一个
- 假设成立 → 进入 Step 5

**Step 5 — 最小修复（Fix）**

- 只改**导致 bug 的那处**（per Surgical Changes：不做邻近清理）
- 修复后重跑完整测试套件，不只跑新增测试
- 修复涉及多文件且超出预期 → 停止，根因定位可能有误，回 Step 3

**Step 6 — 验收（Confirm）**

- [ ] 原始错误不再出现
- [ ] 无新 console error / test failure
- [ ] 如果 bug 影响 API 契约 → 同步检查前端 client
- [ ] 创建 issue 记录根因（`/issue bug <module> <description>`）

## $ARGUMENTS

可选：error message / file:line / 空（从上下文推断）。

## 关联

- `.claude/rules/engineering.md`（karpathy 4 原则）
- `/issue`（修复后记录 bug 根因）
- `.claude/rules/git-workflow.md §7.9`（修复走 bug fix 分支）
