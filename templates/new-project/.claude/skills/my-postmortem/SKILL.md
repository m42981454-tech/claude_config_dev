---
name: my-postmortem
description: 写事故 postmortem — 当用户说"复盘" / "postmortem" / "事故" / production incident 后使用。包含 timeline + 5-Whys + action items + 必含 8 段结构(模板 来自 docs/postmortems/README.md)。
---

# my-postmortem

> **作用**:事故复盘标准模板封装(timeline + 5-Whys + action items + runbook 改进)
> **触发**:auto-match `复盘` / `postmortem` / `事故` / production incident 后
> **关联**: [`docs/postmortems/README.md §模板`](../../../20260403/plan1a-kong/docs/postmortems/README.md) + 3 篇已有 postmortems 范例

---

## 何时写 postmortem

| 必写 | 不写 |
|---|---|
| 🔥 High 事故:数据丢失 / 主仓污染 / 多 agent 串扰 / 严重 merge 错误 | 普通 bug fix |
| ⚡ Medium:workflow slip 致 revert / 认知负担循环 / stale base | UI label 错 / typo |
| ⏳ Low(可选):新教训值得记 | 已 closed issue 内已记 |

---

## 文件位置 + 命名

```
docs/postmortems/<YYYY-MM-DD>_<incident-slug>.md
```

例:`docs/postmortems/2026-05-19_progress-self-reference-paradox.md`

slug 用 `kebab-case`,描述事件**根因**(不是症状)。

---

## 标准 8 段结构(照抄)

```markdown
# Postmortem — <事件标题(中英混排,描述事件本质)>

> **Date**: YYYY-MM-DD
> **Severity**: 🔥 High / ⚡ Medium / ⏳ Low
> **Status**: Resolved / Mitigated / Open
> **Refs**: [#N](https://github.com/m42981454-tech/doc/issues/N)

## 1. 时间线(timeline)

按时间倒序或顺序,每行 1 个时间点 + 动作:
- HH:MM — 发生(symptom 首现)
- HH:MM — 检测(谁 / 怎么发现)
- HH:MM — 决策点(讨论了什么 / 拍板什么)
- HH:MM — 缓解(temporary mitigation)
- HH:MM — 恢复(root cause fix landed)
- HH:MM — 验证(测试 / 用户确认)

## 2. 现象(what happened)

用户能看到的 / 测试能捕获的可观察症状。不写推测。

## 3. 根因(root cause)

5-Whys / fishbone:
- Why 1: <一层原因>
- Why 2: ...
- Why 5: <根本根因>

包含**真根因**(可能与初始猜测不同;若 fix 后症状未除,需要再 Why)。

## 4. 影响范围

- 文件:具体 path + LOC 变化
- 提交:hash 列表(被影响 / 被 revert 的)
- 时间损失:多少 hr 抢救 + 重做
- 用户感知:是否影响 prod / staging / 仅本地

## 5. 抢救动作清单

按顺序的具体 git / 命令操作,包括:
- TaskStop agent(若有)
- 抢救分支 / cherry-pick / revert 命令
- pytest / docker 验证步骤

## 6. 教训 & action items

| # | Action | 状态 | Owner |
|---|---|---|---|
| 1 | <具体可执行的防御措施>(如:加 git hook 拦截 / 修订 CLAUDE.md §X 规约) | ✅ done / ⏳ in-progress / 📋 backlog | PM |
| 2 | ... | | |

**铁律**:每个 action item 必须**可验证完成**(具体命令 / 期望输出),而非"以后注意"。

## 7. 防御措施落地 commit

链 commit hash / PR / issue 闭环本事故的防御措施。

## 8. Related

- 关联其他 postmortem(类似根因 / 同类型)
- 关联 CLAUDE.md / .claude/rules/ 改动
- 关联 design doc / decision doc
```

---

## 完成后必做

1. **更新 `docs/postmortems/README.md` 索引表**(新加一行 含 link + 严重度 + 防御措施摘要)
2. **若涉及规则改动** → 同 chore 改 CLAUDE.md / `.claude/rules/`(`bug fix Refs #N`)
3. **若涉及 hook 加新规则** → 同 chore 加 `.githooks/` 或 `.claude/settings.json` 规则
4. 不**自动 close** 关联 issue;等用户验证后 close

---

## DON'T

- ❌ 不在 postmortem 改 / 删历史 postmortem(只增 — per `docs-conventions.md §5`)
- ❌ 不省略 5-Whys(根因猜测会导致 fix 后 symptom 仍在,典型 B4/B5 双重纠正教训)
- ❌ 不写"以后注意" / "下次小心" 这类不可验证的 action item
- ❌ 不在 postmortem 含 secrets / 用户隐私 / 真 API key
- ❌ 不漏更新 `docs/postmortems/README.md` 索引(否则后人 grep 找不到)
