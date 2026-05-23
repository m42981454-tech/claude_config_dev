# Team Orchestration — plugin agents 派单规约

> **Owner**: 主 `CLAUDE.md` §4（Agent / Team 分工）
> **何时 load**: 派 sub-agent 时 / 修改派单模板时 / Reviewer/Tester 流程疑问时

---

**核心思想**: PM（主线决策角色）通过 `Agent({subagent_type: "..." })` 派 plugin sub-agents 并发执行。每个 agent 有专属 system prompt + tool subset + 触发场景 description，**派单更精准**（不用在 prompt 内重复 "作为 X..." persona）。

⚠️ **subagent_type 用 friendly name（Title Case）而非 file name（kebab-case）** — 详 §2.7 顶部注释。`~/.claude/agents/` 文件名是 `engineering-backend-architect.md`，但 Agent tool 注册的 subagent_type 是 `"Backend Architect"`。

**前置**: `~/.claude/plugins/agency-agents/` plugin（或对等 agent catalog）已加载，提供 50+ agents 自动 register 到 `~/.claude/agents/`：engineering-* / testing-* / product-* / project-management-* / specialized-*。Claude Code 重启后才识别。

### 2.1 PM（主线决策角色）

- 拆任务、并行派单、整合产出、与用户对齐、决策、Go/No-Go 签字
- §7.9 Issue-First gate 守门员（开 sprint 子分支前必先 `gh issue create`）
- PM 主线不另开 Agent，不在主线做编码工作
- 需 spec→task 拆解 / discovery / PRD / 路线图细化时，派 `Product Manager` sub-agent 辅助（推荐 `model: opus` 或当前最强决策 model）— 决策与编排权仍在主线 PM

### 2.2 必经组（每 sprint 默认走）

| Agent | 职责 | 触发判定 |
|---|---|---|
| `engineering-backend-architect` | **Implementer** — 后端 API / 服务架构 / 数据库 / 云端服务 | 后端改动主选 |
| `engineering-frontend-developer` | **Implementer** — React / Vue / CSS / 组件 / accessibility / 性能 | 前端 UI 改动主选 |
| `engineering-minimal-change-engineer` | **Implementer** — bug fix / 小增强，scope 控制，避免重构 / 抽象 / 邻近清理 | 单文件 bug / typo / 小逻辑改 |
| `engineering-code-reviewer` | **Code Reviewer** — 4 标准：代码质量 / 设计契合 / 测试覆盖 / 向后兼容 | 每 sprint 必经 |
| `testing-api-tester` | **Tester (API)** — API 健康检查 / contract / 状态码 / 鉴权测试 / 性能 | API 测试主选 |
| `testing-evidence-collector` | **Tester (UI/Browser)** — UI / 浏览器行为，screenshot / console / network 证据 | 前端 / 浏览器测试主选 |

### 2.3 按需追加（任务性质触发）

| Agent | 触发条件 | 5 标准 / 职责 |
|---|---|---|
| `engineering-security-engineer` | auth / token / secrets / 外部 API / 用户数据 / migration / OWASP-relevant 改动 | (a) Secrets 不入 git/log (b) auth 边界（401/403/422 区分）(c) input validation (d) SQL injection/XSS/CSRF (e) audit log 覆盖 |
| `testing-reality-checker` | release readiness / GA 前 / "done" 宣告复核 / 真伪 fix 验证 | (a) 测试 evidence 真数字 (b) 浏览器 screenshot/console (c) 复现性 (d) 部署 readiness (e) 文档可执行 |
| `engineering-codebase-onboarding-engineer` | 进陌生 codebase 区，需架构图 / 模块责任图 / 调用链路 | code-grounded evidence，不写代码，只调查 |
| `engineering-technical-writer` | 大量 dev 文档 / API 文档 / README / runbook / release notes / 迁移 guide | 对照既有文档风格；commit message 含 file 改动清单 |
| `engineering-sre` | 部署 / SLO / 应急响应规划 / 监控覆盖审计 / capacity planning | 5 标准：(a) 部署可重现（IaC / docker compose）(b) 监控覆盖（alert/dashboard）(c) rollback SOP (d) 资源限制（memory/cpu/容量）(e) runbook 完整 |
| `engineering-devops-automator` | docker / docker-compose / CI/CD pipeline / monitoring（prometheus/grafana/alert）/ migration runbook | 与 SRE 互补；SRE 偏架构/规划，devops-automator 偏脚本/自动化实装 |
| `engineering-database-optimizer` | DB schema 性能 / query plan / 索引设计 / migration 影响 / data-heavy 改动 | EXPLAIN ANALYZE / 索引建议 / 分表 / partition / cache 策略 |
| `engineering-incident-response-commander` | 生产事故 / postmortem / 故障排查 / 5xx 飙升 / 数据丢失 | RCA 流程 / timeline 重构 / runbook 改进 / 5 Whys |

### 2.4 缺失角色映射（无 dedicated agent → 组合替代）

| 缺失 | 推荐组合 |
|---|---|
| **QA Architect** | `testing-reality-checker` + `testing-api-tester` + `testing-evidence-collector` 组合（coverage 数字 + 回归测试 + E2E 场景 + pyramid）|
| **Architect (System Level)** | 后端架构 → `engineering-backend-architect`（主架构 + 实装）；前端架构 → `engineering-frontend-developer`；系统级 → `specialized-workflow-architect`（复杂 multi-service orchestration）|

### 2.5 触发决策表（PM 派单前自检）

| 任务性质 | Implementer | Reviewer | Tester | 追加 |
|---|---|---|---|---|
| 单文件 bug fix（typo/typing/小逻辑）| `engineering-minimal-change-engineer` | `engineering-code-reviewer` | `testing-api-tester` | — |
| 后端 API / Service 改动 | `engineering-backend-architect` | `engineering-code-reviewer` | `testing-api-tester` | — |
| 前端 UI 改动 | `engineering-frontend-developer` | `engineering-code-reviewer` | `testing-evidence-collector` | — |
| auth / token / migration 变更 | `engineering-backend-architect` | `engineering-code-reviewer` | `testing-api-tester` | **`engineering-security-engineer`** |
| 核心架构拆分 | `engineering-backend-architect` | `engineering-code-reviewer` | `testing-api-tester` + `testing-evidence-collector` | **`testing-reality-checker`** |
| DB schema / migration / data 改动 | `engineering-backend-architect` | `engineering-code-reviewer` | `testing-api-tester` | **`engineering-database-optimizer`** |
| docker / prometheus / grafana / alert | `engineering-devops-automator` | `engineering-code-reviewer` | `testing-api-tester` | **`engineering-sre`** |
| 生产事故 / 5xx 飙升 / postmortem | （按域选）| `engineering-code-reviewer` | （按域）| **`engineering-incident-response-commander`** + `engineering-sre` |
| GA 前 release candidate | （按域选）| `engineering-code-reviewer` | `testing-api-tester` + `testing-evidence-collector` | **`engineering-security-engineer` + `testing-reality-checker` + `engineering-sre`** |
| 进陌生 codebase 区 | （先 `engineering-codebase-onboarding-engineer` 调查 → 再派 Implementer）| `engineering-code-reviewer` | （按域）| — |
| 文档密集 sprint | `engineering-technical-writer` | `engineering-code-reviewer` | （无，文档不测试）| — |
| MCP server 开发 | `specialized-mcp-builder` | `engineering-code-reviewer` | `testing-api-tester` | — |

### 2.6 并发规则

- **独立任务必须并行**: 同一条消息内多个 `Agent` tool calls
- **串行依赖不可并行**: Architect 设计 → Implementer 实装 → Reviewer → Tester → （Security / Reality / SRE 按需）→ PM 收尾
- **必经双签**: `engineering-code-reviewer` + Tester（`testing-api-tester` 或 `testing-evidence-collector`）双签才能 merge 主线
- **按需追加签字**: 触发表对应 agent 必须 ✅ 才能 merge
- Tester 报告 bug → PM 即刻派 Implementer 修 → Tester 重测，**循环直到 console 干净**
- `engineering-security-engineer` ❌ → 阻塞 merge，Implementer 修 → 重审
- `testing-reality-checker` 'NEEDS REWORK' → 退回 Implementer
- `engineering-sre` 报告部署不可重现 / 监控漏 → 退回 Implementer 修

### 2.7 派单模板

> **重要 — subagent_type 命名约定**: `~/.claude/agents/` 下 file 是 kebab-case（`engineering-backend-architect.md`），但 plugin **registry 把 friendly name 暴露给 Agent tool** = `"Backend Architect"`（Title Case 去 prefix）。**派单时用 Title Case 名字**，kebab-case file name **不会被识别**。

> **Model 锁定原则**: plugin agent 无 `model:` frontmatter 默认继承 PM 模型（每 dispatch 成本高）。推荐 3-layer 架构 + `model:` frontmatter 锁:
>
> ```
> ~/.claude/plugins/agency-agents/   <N>.md  CATALOG（source of truth, git clone）
> ~/.claude/agents/                  <M>.md  USER-LEVEL ACTIVE（跨项目 baseline）
> <project>/.claude/agents/          <K>.md  PROJECT-LEVEL ACTIVE（项目特定 + 按需可选）
> ```
>
> 全部 active agent 在 frontmatter 锁 model：大部分 `model: sonnet`（代码工程 + 测试 + 架构 + DevOps 等），少量 `model: opus`（PM 决策类 / Product Manager / 高 reasoning 需求）

**派单标准模板**（单行，无需 `model:` 参数 — 已锁 frontmatter）:

```
Agent({
  subagent_type: "API Tester",          // plugin Title Case friendly name
  description: "[T#·Role·Sprint·Phase] <任务一句话>",
  prompt: "..."
})
```

**临时 override**（罕见 — 测试 / 特殊高 reasoning 任务）:

```
Agent({
  subagent_type: "API Tester",
  model: "opus",                         // 显式覆盖 frontmatter
  description: "...", prompt: "..."
})
```

**catalog 查询 / 取出新 agent 工作流**:

```bash
find ~/.claude/plugins/agency-agents/ -name "<keyword>*"
cp ~/.claude/plugins/agency-agents/<subdir>/<file>.md ~/.claude/agents/       # cross-project
cp ~/.claude/plugins/agency-agents/<subdir>/<file>.md <project>/.claude/agents/  # project-only
# 然后改 frontmatter 加 `model: sonnet` / opus + 重启 Claude Code
```

#### 2.7.0 角色可视化 4 channel（并发 sub-agent 时让"现在谁在干活"一眼可见）

**目的**: 并发派多个 sub-agent 时，日志 / commit / PROGRESS / 报告 4 处都能立刻看出**哪个 Track · 哪个 Role · 哪个 Sprint · 哪个 Phase**。

| Ch | 位置 | 强制格式 | 示例 |
|---|---|---|---|
| **1** | Agent `description` 字段（Claude Code UI 实时显示 / 后台日志 / TaskList）| **`[T#·Role·Sprint·Phase] <任务一句话>`** | `[T1·BackendArchitect·N1-bk·P1-P3] migration + Discovery API 骨架` |
| **2** | commit subject role tag | **`<type>(<sprint>·<Role>): <what>`** | `feat(N1-bk·BackendArchitect): migration + Discovery 骨架` |
| **3** | PROGRESS `§🔄 当前进行中` 表 | 表头含 **Track ｜ Sprint ｜ Role(s) ｜ Phase ｜ Branch ｜ Status ｜ ETA** | 见 progress.md §🔄 实例 |
| **4** | sub-agent 返回 message **第一行** 强制 header | **`Agent: <Role> ｜ Track: <T#> ｜ Sprint: <N#-xx> ｜ Phase: <impl/review/test> ｜ Branch: <branch-name>`** | `Agent: Backend Architect ｜ Track: T1 ｜ Sprint: N1-bk ｜ Phase: impl ｜ Branch: <branch>` |

**约定**（强制）:

- Track 编号 `T1/T2/T3/T4...` 跨 sprint 不复用，每个 sprint 启动时 PM 给定
- Sprint 编号 `N1/N2/N3...` 来自 PROGRESS §🔴 ⚡ 的 N# 列；同 sprint 的不同 phase 子拆 `N1-bk` / `N1-fe` 等后缀
- Phase 字段值: `P#`（spec 阶段编号）/ `impl` / `review` / `test` / `merge`
- 派单稿模板里 description 字段**必含 ch1 前缀**；agent prompt 末尾**必含 ch2+ch4 指令**（commit 怎么写 + 报告怎么起手）
- PROGRESS §🔄 表 sprint 启动时 PM 写入 1 行，phase 切换 / merge 时 chore 分支 update
- **违反**: ch1 漏前缀 → PM 退回派单；ch2 漏 role tag → 下个 commit 补 amend / 新 commit 加说明；ch4 漏 header → agent 返回后 PM 在回复里手动补头

---

> **派单模板**（各角色完整 Agent({}) 代码块）已移至 skill 按需加载：
> 调用 `/my-dispatch-templates` 或 `Skill("my-dispatch-templates")` 获取。
> 每个派单模板含 ch2（commit tag）+ ch4（报告 header）约定，直接复制使用。
