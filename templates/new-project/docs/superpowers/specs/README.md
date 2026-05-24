# `docs/superpowers/specs/` — 设计 spec 目录

## ⚠️ 本目录默认被 `.claudeignore` 排除

模板根的 `.claudeignore` 默认排除整个 `docs/superpowers/specs/` 目录，目的是防止模板自身的演化设计决策污染新项目工作。

## 副作用与自然有效范围

新项目用户按 `superpowers:brainstorming` skill 的标准写新 spec 时，需要注意：

- ⚠️ **本目录新增 spec 默认也会被排除**。
- ✅ 这对模板维护是安全的，因为这些文件主要是模板演化履历。
- ✅ 如果某个真实项目希望 Claude Code 读取新 spec，应改用不在 `.claudeignore` 中的目录，或调整 `.claudeignore`。

## 解决方案（任选其一）

1. **模板维护 spec 继续放本目录**：保持与当前模板治理历史一致。
2. **真实项目 spec 改用其他目录**：例如 `docs/specs/` 或 `docs/YYYY-MM/<topic>-design.md`（per `docs-conventions.md`）。
3. **清理模板历史文件**：`rm -rf docs/superpowers/specs/`，并按需删 `.claudeignore` 对应行。

## 现存模板演化 spec

| 文件 | 主题 |
|---|---|
| `2026-05-23-agent-pool-governance-design.md` | agent pool 治理设计 |
| `2026-05-23-hook-noise-session-learning-design.md` | hook 噪音 + session 学习设计 |
| `2026-05-23-template-optimization-design.md` | 本次模板优化设计 |
| `2026-05-24-session-review-command-design.md` | 手动 session review 命令设计 |

新项目用户若清理这些文件不影响模板功能。
