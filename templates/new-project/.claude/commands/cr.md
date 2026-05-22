---
description: Code review with 6 parallel specialist agents
allowed-tools: Bash, Agent, Read, Grep, Glob
---

# /cr

启动并发 code review：Code Reviewer + API Tester + Evidence Collector + Security Engineer + Reality Checker + (按需 Database Optimizer / SRE) 同时跑。

模式借鉴社区 `/cr` 命令实践 + 适配项目 §2.5 触发决策表。

## Usage

```
/cr <PR#>                  # 审 GitHub PR
/cr <branch>               # 审本地 branch diff
/cr <commit-hash>          # 审单 commit
```

## 派单矩阵（per §2.5）

按 sprint 范围选择 ✓ 启动的 specialist:

| 范围 | Code Reviewer | API Tester | Evidence Collector | Security | Reality | DB Optimizer | SRE |
|---|---|---|---|---|---|---|---|
| 后端 API / Service | ✅ | ✅ | — | — | — | — | — |
| 前端 UI | ✅ | — | ✅ | — | — | — | — |
| auth / token / migration | ✅ | ✅ | — | ✅ | — | — | — |
| DB schema | ✅ | ✅ | — | — | — | ✅ | — |
| docker / monitoring | ✅ | ✅ | — | — | — | — | ✅ |
| GA 前 release | ✅ | ✅ | ✅ | ✅ | ✅ | — | ✅ |

## 并发约束

- 并发 ≤ 5 agent（per §2.6）
- 同消息内多个 `Agent` tool call（并行启动）
- 必经双签：Code Reviewer + Tester
- 按需追加签字 ❌ → 阻断 merge

## 关联

- `.claude/rules/team-orchestration.md §2.5 触发决策表` + `§2.7 派单模板`
- skill [`my-dispatch-sprint`](../skills/my-dispatch-sprint/SKILL.md)
