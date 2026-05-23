# `docs/superpowers/specs/` — 设计 spec 目录

## ⚠️ 本目录有部分文件被 `.claudeignore` 排除

模板根的 `.claudeignore` 仅排除 3 个已知的模板演化设计 spec（见下表），目的是防止模板自身的陈旧设计决策污染新项目工作。

## 副作用与自然有效范围

新项目用户按 `superpowers:brainstorming` skill 的标准写新 spec 时：

- ✅ **本目录新增 spec 不受排除**（除非文件名完全匹配下表 3 个）
- ✅ **README.md 不被排除**（可正常读）
- ✅ **自动生效**（无需修改 `.claudeignore`）

## 解决方案（任选其一）

1. **直接在本目录写新项目 spec**（推荐）：文件名避免与下表 3 个重叠即可，新 spec 自动可读。
2. **改用其他目录**：例如 `docs/specs/` 或 `docs/YYYY-MM/<topic>-design.md`（per `docs-conventions.md`）。
3. **清理模板历史文件**：`rm` 下表 3 个 spec 文件 + 对应删 `.claudeignore` 3 行，彻底清净。

## 现存模板演化 spec（3 个文件被排除）

| 文件 | 主题 |
|---|---|
| `2026-05-23-agent-pool-governance-design.md` | agent pool 治理设计 |
| `2026-05-23-hook-noise-session-learning-design.md` | hook 噪音 + session 学习设计 |
| `2026-05-23-template-optimization-design.md` | 本次模板优化设计 |

新项目用户若清理这些文件不影响模板功能（直接 `rm` 即可）。
