---
description: 手动复盘上一轮 session，总结事实、习惯候选和可固化规则建议
allowed-tools: Bash, Read
---

# /project:session-review

手动触发的 session review。用于读取有限上下文，输出可人工审查的会话复盘。

核心原则：

```text
Automatic capture, manual review, human-approved promotion.
```

## 必须遵守

- 不自动修改文件。
- 不自动更新 `CLAUDE.md`。
- 不自动更新 `.claude/rules/`。
- 不自动启用 agent 或 plugin。
- 不自动提交 commit。
- 不读取完整 transcript，除非用户明确提供路径并要求读取。
- 把所有“用户习惯”判断标为 inference，不当作事实。

## 步骤

**Step 1 — 收集有限上下文**

运行：

```bash
.claude/scripts/session-review-context.sh $ARGUMENTS
```

`$ARGUMENTS` 可选。如果用户传入一个具体报告或 spec 路径，collector 可以把该文件作为候选证据摘录。

**Step 2 — 输出中文复盘**

按以下结构输出：

```markdown
# Session Review

## 1. 本次会话事实
- 做了什么
- 改了哪些路径
- 运行了哪些验证
- 还有什么未完成

## 2. 用户使用习惯候选

| Confidence | Habit | Evidence | Suggested Rule |
|---|---|---|---|
| high / medium / low | ... | ... | ... |

## 3. 可固化规则建议

### 建议写入项目规则
- ...

### 建议只保留为本地偏好
- ...

### 不建议固化
- ...

## 4. 风险
- 过度学习风险
- 单次偏好误固化风险
- context 噪音风险

## 5. 下一步建议
- 不修改
- 等用户确认后写入 `user-working-style.md`
- 等用户确认后更新某个 design/report
```

## 固化规则

如果用户明确要求固化，再单独进入实现步骤。

可选目标：

```text
.claude/rules/user-working-style.md
```

模板仅提供：

```text
.claude/rules/user-working-style.md.example
```

不要把一次性决定写成长期规则。

