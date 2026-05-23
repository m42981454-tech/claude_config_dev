# Postmortem 索引

> 每次重大事故必须在本目录新建独立 postmortem 文件，并在下表登记。
> 模板：`YYYY-MM-DD_<incident>.md`，使用 `/my-postmortem` skill 生成。

---

## 索引表

| 日期 | 事故摘要 | 严重级别 | 文件 | 状态 |
|---|---|---|---|---|
| — | — | — | — | — |

---

## Postmortem 文件模板

新建时复制以下结构（或直接运行 `/my-postmortem`）：

```markdown
# Postmortem：[事故一句话描述]

> **Refs**: [#N](<issue-url>)
> **Date**: YYYY-MM-DD
> **Severity**: P0 / P1 / P2
> **Status**: Draft / Reviewed / Action items in progress / Closed

## 0. TL;DR

[2-3 行核心结论：什么坏了、为什么、已修了吗]

## 1. 时间线（Timeline）

| 时间（UTC）| 事件 |
|---|---|
| HH:MM | 首次告警 / 用户反馈 |
| HH:MM | 开始响应 |
| HH:MM | 根因定位 |
| HH:MM | 修复上线 |
| HH:MM | 全面恢复 |

## 2. 根因分析（5 Whys）

- **Why 1**: 表象是什么？
- **Why 2**: 为什么会这样？
- **Why 3**: ...
- **Why 4**: ...
- **Why 5**: 根本原因是什么？

## 3. 影响范围

- 受影响用户数 / 请求量
- 持续时间
- 数据丢失 / 降级功能

## 4. 应急措施（当时做了什么）

1. ...
2. ...

## 5. 修复方案

- [ ] 短期（已做）：...
- [ ] 中期（本 sprint）：[#N]
- [ ] 长期（改架构）：[#N]

## 6. Action Items

| 负责人 | 任务 | Issue | Due |
|---|---|---|---|
| — | — | — | — |

## 7. 经验教训（Lessons Learned）

**做对了什么**：
- ...

**改进空间**：
- ...

## 8. 参考

- 相关 Issue / PR：[#N]
- 监控截图 / 日志：...
```

---

## 操作规约

- ❌ 不删改已有 postmortem（只增不改；补充用新文件）
- ❌ 不在本目录放代码或配置
- ✅ Action items 必须对应 GitHub Issue（`[#N]`）
- ✅ 新建后立即更新上方索引表
