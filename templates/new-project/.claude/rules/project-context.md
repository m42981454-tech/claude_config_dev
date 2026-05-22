# Project Context — 设计契约 + 任务顺序 + 技术栈 + 测试要求

> **Owner**: 主 `CLAUDE.md` §1 + §2 + §3（仓库结构 / 技术栈 / 当前任务与状态）
> **何时 load**: 开始新 sprint / 改代码前确认契约 / 加依赖 / 写测试时
> **保留章节编号**: 沿用 §3 / §4 / §5 / §6（cross-ref 兼容）

---

## 3. 设计契约（强制遵守）

任何 sprint PR 不得违反以下来源契约（具体路径按项目实际填写）：

| 文件 | 含义 |
|---|---|
| `design/<top-level>.md` | 总体设计 + ADR + Phase 范围 |
| `design/detail/<topic>.md` | 表结构 / 端点 / 请求响应 / 错误码 / UI 线框 / i18n 等 |
| `docs/YYYY-MM-DD_*.md` | 本期审计 / spike 结论 / 改修方案 |

**偏离设计**必须：
1. 在 `docs/YYYY-MM/` 下补 `YYYY-MM-DD_decision_<topic>.md` 说明 why
2. PM 与用户确认后再实施
3. 实施 commit 必 link 到 decision doc + Refs issue

---

## 4. 当前任务顺序（PM 维护，从 `progress.md` 同步）

> 详 [`progress.md`](../../progress.md) §🔄 当前进行中 / §🔴 待做 / §🟡 待验收
>
> 本节作为速览，不替代 `progress.md`。新任务/优先级调整都在 `progress.md` 更新。

| # | 任务 | 依据 | 备注 |
|---|---|---|---|
| **P0-1** | [示例] <核心任务一句话> | <设计文档章节> | <状态> |
| **P0-2** | [示例] ... | ... | ... |

---

## 5. 技术栈约束

### 后端
- [BACKEND_LANGUAGE_VERSION]（如 Python 3.11 / Node 20）
- [BACKEND_FRAMEWORK]（如 FastAPI / Express）
- [ORM_AND_MIGRATIONS]（如 SQLAlchemy + Alembic）
- [DATABASE]（如 PostgreSQL 15 + Redis 7）
- [TEST_FRAMEWORK]（如 pytest）
- 不引入新常驻服务（除非有 decision doc）

### 前端
- [FRONTEND_FRAMEWORK]（如 Next.js 14 / React + Vite）
- [LANGUAGE]（如 TypeScript）
- [STYLING]（如 Tailwind v3 + shadcn/ui）
- [STATE_MGMT]（如 TanStack Query）
- [I18N]（如 react-i18next，无则删除）
- 旧入口/legacy 实现**保留不动**直到新版本达功能等价

### 数据库
- 迁移文件命名：`NNN_<snake_case_topic>.sql`
- 每个迁移含 idempotent (`IF NOT EXISTS`)
- 破坏性变更（DROP / 改类型）必须配 `down.sql` 与备份说明

---

## 6. 测试硬性要求

- 既有测试套件 **100% 绿**（基线数字按项目实际填，例：`<unit-pass>/<unit-total>` + `<e2e-pass>/<e2e-total>`）
- 新增功能行覆盖 **≥ 80%**，核心服务 **≥ 90%**
- UI / 浏览器场景必须有 E2E 测试（Playwright / 等）
- E2E 必须用 browser MCP / Playwright 验证浏览器 console 无 error 才算通过
