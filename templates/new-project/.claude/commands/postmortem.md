---
description: 写事故 postmortem（模板 + 索引 + action items）
allowed-tools: Bash, Skill, Write, Edit, Read, Grep
---

# /postmortem

事故复盘显式入口。**调用 `my-postmortem` skill** 走 8 段标准结构。

## Usage

```
/postmortem <incident-slug>           # 例：/postmortem chained-pipe-trap
/postmortem <YYYY-MM-DD>_<slug>       # 显式日期 prefix
```

## 8 段结构（per `docs/postmortems/README.md §模板`）

1. 时间线（detect / decision / mitigate / recover / verify）
2. 现象（观察症状，不推测）
3. 根因（5-Whys，可能多层）
4. 影响范围（files / commits / 时间损失 / 用户感知）
5. 抢救动作清单（git / 命令 顺序）
6. 教训 & action items（可验证完成的 防御措施）
7. 防御措施落地 commit（链 hash / PR / issue）
8. Related（关联 postmortem / 规约改动 / decision doc）

## 完成后必做

1. 更新 `docs/postmortems/README.md` 索引表（新加一行 link + 严重度 + 防御措施）
2. 若涉规则改动 → 同 chore 改 CLAUDE.md / `.claude/rules/`
3. 若涉 hook → 同 chore 加 `.githooks/` 或 `.claude/settings.json`
4. **不**自动 close 关联 issue

## 关联

- skill [`my-postmortem`](../skills/my-postmortem/SKILL.md)
- 范例：参 `docs/postmortems/` 内既有 postmortem（如有）
