# 架构政策（只读，偏离需写 decision doc）

> **Status**: Source of truth — 偏离必先在 `docs/YYYY-MM/<date>_decision_<topic>.md` 说明 why
> **加载**: 每会话（无 `paths:` frontmatter，与 `.claude/rules/` 其他 sub-file 同 baseline）
> **用途**: 沉淀项目级架构决策，作为团队共同契约

---

## 模板：架构政策条目（每条决策一节）

```markdown
## YYYY-MM-DD <主题>定案（<方案标记>）

| 关键维度 | 取值 | 说明 |
|---|---|---|
| <维度 1> | <值> | <如何使用 / 边界> |
| <维度 2> | <值> | ... |

**核心规则**:
1. <规则 1>
2. <规则 2>
...

**业界对照**（可选）: <参考主流方案对比>

**Refs**: [#N](<issue-url>) / 设计 doc 路径
```

---

## 示例（删除或替换为你项目的实际政策）

### YYYY-MM-DD [示例] 鉴权方案定案

| 路径前缀 | 鉴权 | 谁能访问 |
|---|---|---|
| `/admin/*` | JWT | admin 角色 |
| `/v1/*` | `Bearer <token>` | API key 持有者 |
| `/health` | 匿名 | 任何人 |

**核心规则**:
1. <根据项目实际写>

---

## 偏离规约（通用）

任何对架构政策的修改/新增：

1. **必先**在 `docs/YYYY-MM/<date>_decision_<topic>.md` 写 decision doc（why / risks / rollback）
2. PM 与用户确认后方可实施
3. 实施 commit 必 link 到 decision doc + Refs issue

**禁止**:
- ❌ 不在共享配置/网关公共路径下加内部鉴权 mapping（保持单点入口可读性）
- ❌ 不删 `/health` `/metrics` 匿名（必要的健康检查 / monitoring scrape）
- ❌ 不混合鉴权方式（同一路径前缀只用一种鉴权策略）

---

> 📌 **Maintainer 注**：每次架构决策落地后，在本文件追加一节（不覆盖历史决策），后续决策若推翻前者，新节标题加 `(supersedes YYYY-MM-DD)` 标记。
