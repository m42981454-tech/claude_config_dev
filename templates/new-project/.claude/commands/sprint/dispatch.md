---
description: 派 sub-agent 干 sprint 工作（13 angle agent 决策表 + 4 channel 强制）
allowed-tools: Bash, Skill, Agent
---

# /sprint:dispatch

派 plugin sub-agent 显式入口（Backend Architect / Code Reviewer / API Tester / Security Engineer / 等 13 个角色）。

**调用 skill `my-dispatch-sprint`**（`disable-model-invocation: true`，只能显式 invoke，防误派）。

## Usage

```
/sprint:dispatch backend <task>       # 派 Backend Architect 干 <task>
/sprint:dispatch frontend <task>      # 派 Frontend Developer
/sprint:dispatch review <PR>          # 派 Code Reviewer 审 <PR>
/sprint:dispatch test-api <scope>     # 派 API Tester
/sprint:dispatch test-ui <scope>      # 派 Evidence Collector
/sprint:dispatch security <PR>        # 派 Security Engineer
/sprint:dispatch fix <bug>            # 派 Minimal Change Engineer
```

## 4 Channel 强制（每个 dispatch 必含）

| Ch | 位置 | 格式 |
|---|---|---|
| 1 | Agent `description` | `[T#·Role·Sprint·Phase] <一句话>` |
| 2 | commit subject | `<type>(<sprint>·<Role>): <what>` |
| 3 | PROGRESS §🔄 表 | Track / Sprint / Role / Phase / Branch / Status / ETA |
| 4 | agent 返回 header | `Agent: <Role> ｜ Track: <T#> ｜ Sprint: <N#> ｜ Phase: <impl/review/test> ｜ Branch: <branch>` |

## $ARGUMENTS

接受参数：`<role> <task描述>`。

## 关联

- skill [`my-dispatch-sprint`](../../skills/my-dispatch-sprint/SKILL.md)
- `.claude/rules/team-orchestration.md §2.1-§2.7.0`
