# Project Context — 设计契约 + P0 顺序 + 技术栈 + 测试要求

> **Owner**: 主 `CLAUDE.md` §3 + §4 + §5 + §6(本文件由 chore `CLAUDE.md restructure Phase 3` 从主文件拆出,refs [#21](https://github.com/m42981454-tech/doc/issues/21))
> **何时 load**:开始新 sprint / 改代码前确认契约 / 加依赖 / 写测试时
> **保留章节编号**:沿用 §3 / §4 / §5 / §6(cross-ref 兼容)

---

## 3. 设计契约（强制遵守）

任何 P0 PR 不得违反：

| 文件 | 含义 |
|---|---|
| `design/01_基础设计.md` ~ `04_设计审核报告.md` | 9 条 ADR + 5 Phase 范围 |
| `design/detail/A_数据模型与API规格.md` | 表结构 / 端点 / 请求响应 / 错误码 |
| `design/detail/B_管理UI交互设计.md` | UI 线框 / 交互 / i18n 键 / a11y |
| `design/detail/C_测试与运维设计.md` | 测试金字塔 / 指标 / 告警 / 灰度 |
| `docs/2026-05-08_*.md` | 本期审计 + spike 结论 + UI 改修方案 |

**偏离设计**必须：① 在 `docs/` 下补 `2026-MM-DD_decision_<topic>.md` 说明 why；② PM 与用户确认后再实施。

---

## 4. 当前 P0 顺序（spike 后修订）

| # | 任务 | 依据 | 备注 |
|---|---|---|---|
| **P0-1** | `request_logs` 拆表迁移 015 + `usage_service` 双写 + Logs 页查询切读 | docs/2026-05-08_pre_coding_spike_results.md C2 | 单独建表（用户决策）；先双写兼容期 |
| **P0-2** | 多模态 pricing 维度扩展（`cost.py` + `llm_models.pricing` schema） | spike C3 / 新增 R13 | rerank 前置 |
| **P0-3** | `POST /v1/rerank` + Cohere/智谱 rerank handler | audit R1 | 用维度 `rerank` |
| **P0-4** | 前端路线 A 脚手架（Vite + React 18 + TS + shadcn/ui + Tailwind + Tremor + TanStack Query/Table） | docs/2026-05-08_ui_revamp_proposal.md | 与 P0-1~3 并行 |
| **P0-5** | docs/admin 调试残留清理 | audit R11/R12 | ✅ 已完成 |

---

## 5. 技术栈约束

### 后端（不变）
- Python 3.11 + FastAPI + asyncpg + httpx[http2] + pytest + respx
- Redis 7 / PostgreSQL 15
- 不引入新常驻服务（ADR-02）

### 前端（路线 A 新建）
- 新 SPA 位于 `fastapi-app/docs/admin-next/`
- Vite + React 18 + TypeScript + shadcn/ui + Tailwind v3 + Tremor + TanStack Query/Table
- `react-i18next`，复用现有 `locales/{zh-CN,ja-JP,en-US}.json`
- 旧 `docs/admin/index.html` + `index.legacy.html` **保留不动**直到新 SPA 达功能等价

### 数据库
- 迁移文件命名：`NNN_<snake_case_topic>.sql`
- 每个迁移含 idempotent (`IF NOT EXISTS`)
- 破坏性变更（DROP / 改类型）必须配 `down.sql` 与备份说明

---

## 6. 测试硬性要求

- 既有 31 + 83 单元 + 11 集成测试 **100% 绿**
- 新增功能行覆盖 ≥ 80%，核心服务 ≥ 90%
- 多模态 / Logs / Channels / Playground 必须有 Playwright 场景
- E2E 必须用 claude-in-chrome MCP 验证浏览器 console 无 error 才算通过
