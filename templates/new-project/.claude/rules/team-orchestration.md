# Team Orchestration — plugin agents 派单规约

> **Owner**: 主 `CLAUDE.md` §2(本文件由 chore `CLAUDE.md restructure Phase 1` 从主文件拆出,refs [#21](https://github.com/m42981454-tech/doc/issues/21))
> **何时 load**:派 sub-agent 时 / 修改派单模板时 / Reviewer/Tester 流程疑问时
> **保留章节编号**:沿用 §2.x(cross-ref 兼容)

---

**核心思想**:PM (Opus 4.7) 主线编排,通过 `Agent({subagent_type: "Backend Architect" | "API Tester" | ... })` 派 plugin sub-agents 并发执行。每个 agent 有专属 system prompt + tool subset + 触发场景 description,**派单更精准**(不用在 prompt 内重复 "作为 X..." persona)。

⚠️ **subagent_type 用 friendly name(Title Case)而非 file name(kebab-case)** — 详 §2.7 顶部注释。`~/.claude/agents/` 文件名是 `engineering-backend-architect.md`,但 Agent tool 注册的 subagent_type 是 `"Backend Architect"`。下方表格"Agent"列写 file name 作 reader reference,派单时改用 Title Case。

**前置**:`~/.claude/plugins/agency-agents/` plugin 已加载,提供 50+ agents 自动 register 到 `~/.claude/agents/`:engineering-* (24) + testing-* (8) + product-* (5) + project-management-* (5) + specialized-* (4)。Claude Code 重启后才识别。

### 2.1 PM (Opus 主线)
- 拆任务、并行派单、整合产出、与用户对齐、决策、Go/No-Go 签字
- §7.9 Issue-First gate 守门员(开 sprint 子分支前必先 `gh issue create`)
- 主线 Opus 不另开 Agent,不在主线做编码工作
- 需 spec→task 拆解 / discovery / PRD / 路线图细化时,派 `Product Manager` sub-agent 辅助(`model: opus`;取代旧 `Senior Project Manager`)— 决策与编排权仍在主线 Opus

### 2.2 必经组(每 sprint 默认走)

| Agent | 职责 | 触发判定 |
|---|---|---|
| `engineering-backend-architect` | **Implementer** — 后端 API / FastAPI / 服务架构 / 数据库 / 云端服务 | 后端改动主选 |
| `engineering-frontend-developer` | **Implementer** — React / Vue / CSS / 组件 / accessibility / 性能 | 前端 UI 改动主选 |
| `engineering-minimal-change-engineer` | **Implementer** — bug fix / 小增强,scope 控制,避免重构 / 抽象 / 邻近清理 | 单文件 bug / typo / 小逻辑改 |
| `engineering-code-reviewer` | **Code Reviewer** — 4 标准:代码质量 / 设计契合 / 测试覆盖 / 向后兼容 | 每 sprint 必经 |
| `testing-api-tester` | **Tester (API)** — API 健康检查 / contract / 状态码 / 鉴权测试 / 性能 | API 测试主选 |
| `testing-evidence-collector` | **Tester (UI/Browser)** — UI / 浏览器行为,screenshot / console / network 证据 | 前端 / 浏览器测试主选 |

### 2.3 按需追加(任务性质触发)

| Agent | 触发条件 | 5 标准 / 职责 |
|---|---|---|
| `engineering-security-engineer` | auth / token / secrets / 外部 API / 用户数据 / migration / OWASP-relevant 改动 | (a) Secrets 不入 git/log (b) auth 边界(401/403/422 区分) (c) input validation (d) SQL injection/XSS/CSRF (e) audit log 覆盖 |
| `testing-reality-checker` | release readiness / GA 前 / "done" 宣告复核 / 真伪 fix 验证 | (a) 测试 evidence 真数字 (b) 浏览器 screenshot/console (c) 复现性 (d) 部署 readiness (e) 文档可执行 |
| `engineering-codebase-onboarding-engineer` | 进陌生 codebase 区,需架构图 / 模块责任图 / 调用链路 | code-grounded evidence,不写代码,只调查 |
| `engineering-technical-writer` | 大量 dev 文档 / API 文档 / README / runbook / release notes / 迁移 guide | 对照既有文档风格;commit message 含 file 改动清单 |
| **`engineering-sre`** | 部署 / SLO / 应急响应规划 / 监控覆盖审计 / capacity planning | 5 标准:(a) 部署可重现(IaC / docker compose) (b) 监控覆盖(alert/dashboard) (c) rollback SOP (d) 资源限制(memory/cpu/容量) (e) runbook 完整 |
| **`engineering-devops-automator`** | docker / docker-compose / CI/CD pipeline / monitoring(prometheus/grafana/alert)/ migration runbook | 与 SRE 互补;SRE 偏架构/规划,devops-automator 偏脚本/自动化实装 |
| **`engineering-database-optimizer`** | DB schema 性能 / query plan / 索引设计 / migration 影响 / data-heavy 改动 | EXPLAIN ANALYZE / 索引建议 / 分表 / partition / cache 策略 |
| **`engineering-incident-response-commander`** | 生产事故 / postmortem / 故障排查 / 5xx 飙升 / 数据丢失 | RCA 流程 / timeline 重构 / runbook 改进 / 5 Whys |

### 2.4 缺失角色映射(无 dedicated agent → 组合替代)

| 缺失 | 推荐组合 |
|---|---|
| **QA Architect** | `testing-reality-checker` + `testing-api-tester` + `testing-evidence-collector` 组合(coverage 数字 + 回归测试 + E2E 场景 + pyramid);plugin 无单一 QA Architect agent |
| **Architect (旧)** | 后端架构 → `engineering-backend-architect`(主架构 + 实装);前端架构 → `engineering-frontend-developer`;系统级 → `specialized-workflow-architect`(plugin 提供;复杂 multi-service orchestration) |

### 2.5 触发决策表(PM 派单前自检)

| 任务性质 | Implementer | Reviewer | Tester | 追加 |
|---|---|---|---|---|
| 单文件 bug fix(typo/typing/小逻辑) | `engineering-minimal-change-engineer` | `engineering-code-reviewer` | `testing-api-tester` | — |
| 后端 API / Service 改动 | `engineering-backend-architect` | `engineering-code-reviewer` | `testing-api-tester` | — |
| 前端 UI 改动 | `engineering-frontend-developer` | `engineering-code-reviewer` | `testing-evidence-collector` | — |
| auth / token / migration 变更 | `engineering-backend-architect` | `engineering-code-reviewer` | `testing-api-tester` | **`engineering-security-engineer`** |
| 核心架构拆分(model_router / fallback) | `engineering-backend-architect` | `engineering-code-reviewer` | `testing-api-tester` + `testing-evidence-collector` | **`testing-reality-checker`** |
| DB schema / migration / data 改动 | `engineering-backend-architect` | `engineering-code-reviewer` | `testing-api-tester` | **`engineering-database-optimizer`** |
| docker / prometheus / grafana / alert | `engineering-devops-automator` | `engineering-code-reviewer` | `testing-api-tester` | **`engineering-sre`** |
| 生产事故 / 5xx 飙升 / postmortem | (按域选) | `engineering-code-reviewer` | (按域) | **`engineering-incident-response-commander`** + `engineering-sre` |
| GA 前 release candidate | (按域选) | `engineering-code-reviewer` | `testing-api-tester` + `testing-evidence-collector` | **`engineering-security-engineer` + `testing-reality-checker` + `engineering-sre`** |
| 进陌生 codebase 区 | (先 `engineering-codebase-onboarding-engineer` 调查 → 再派 Implementer) | `engineering-code-reviewer` | (按域) | — |
| 文档密集 sprint | `engineering-technical-writer` | `engineering-code-reviewer` | (无,文档不测试) | — |
| MCP server 开发 | `specialized-mcp-builder` | `engineering-code-reviewer` | `testing-api-tester` | — |

### 2.6 并发规则

- **独立任务必须并行**:同一条消息内多个 `Agent` tool calls
- **串行依赖不可并行**:Architect 设计 → Implementer 实装 → Reviewer → Tester → (Security / Reality / SRE 按需) → PM 收尾
- **必经双签**:`engineering-code-reviewer` + Tester(`testing-api-tester` 或 `testing-evidence-collector`)双签才能 merge 主线
- **按需追加签字**:触发表对应 agent 必须 ✅ 才能 merge
- Tester 报告 bug → PM 即刻派 Implementer 修 → Tester 重测,**循环直到 console 干净**
- `engineering-security-engineer` ❌ → 阻塞 merge,Implementer 修 → 重审
- `testing-reality-checker` 'NEEDS REWORK' → 退回 Implementer
- `engineering-sre` 报告部署不可重现 / 监控漏 → 退回 Implementer 修

### 2.7 派单模板

> **重要 — subagent_type 命名约定**:`~/.claude/agents/` 下 file 是 kebab-case(`engineering-backend-architect.md`),但 plugin **registry 把 friendly name 暴露给 Agent tool** = `"Backend Architect"`(Title Case 去 prefix)。**派单时用 Title Case 名字**,kebab-case file name **不会被识别**(实测:`Agent({subagent_type: "engineering-minimal-change-engineer"})` 报 "not found",`"Minimal Change Engineer"` 工作)。下面所有模板的 `subagent_type` 值都是 Title Case。

> **2026-05-19 — cost 优化最终设计**(refs [#19](https://github.com/m42981454-tech/doc/issues/19))
>
> plugin agent 无 `model:` frontmatter 默认继承 PM Opus 4.7(每 dispatch ~$0.98)。本项目最终 3-layer 架构 + `model:` frontmatter 锁:
>
> ```
> ~/.claude/plugins/agency-agents/  226 .md  CATALOG (source of truth, git clone)
> ~/.claude/agents/                  14 .md  USER-LEVEL ACTIVE(跨项目 baseline)
> <project>/.claude/agents/          11 .md  PROJECT-LEVEL ACTIVE(项目特定 + 按需可选)
> ```
>
> 全 25 active agent 已在 frontmatter 锁:
> - 23 个 `model: sonnet`(代码工程 + 测试 + 架构 + DevOps + AI/数据等)
> - 2 个 `model: opus`(`product-manager` / `project-management-jira-workflow-steward` — PM 决策类高 reasoning 需求)
>
> **派单标准模板**(单行,无需 `model:` 参数 — 已锁 frontmatter):
> ```
> Agent({
>   subagent_type: "API Tester",          // plugin Title Case friendly name
>   description: "[T#·Role·Sprint·Phase] <任务一句话>",
>   prompt: "..."
> })
> ```
>
> **临时 override**(罕见 — 测试 / 特殊高 reasoning 任务):
> ```
> Agent({
>   subagent_type: "API Tester",
>   model: "opus",                         // 显式覆盖 frontmatter
>   description: "...", prompt: "..."
> })
> ```
>
> **catalog 查询 / 取出新 agent 工作流**:
> ```
> find ~/.claude/plugins/agency-agents/ -name "<keyword>*"
> cp ~/.claude/plugins/agency-agents/<subdir>/<file>.md ~/.claude/agents/       # cross-project
> cp ~/.claude/plugins/agency-agents/<subdir>/<file>.md <project>/.claude/agents/  # project-only
> # 然后改 frontmatter 加 `model: sonnet` / opus + 重启 Claude Code
> ```
>
> A/B 实测:Sonnet 与 Opus reasoning 精度等同(Tier 4 environmental judgement PASS);Haiku ❌ DISQUALIFIED(Tier 4 误判)。**默认 Sonnet,PM 决策类例外用 Opus**。
>
> **历史方案废弃**:`my-*` wrapper(P1-P2)— 改 append-only(P3)— 用 vault(P3-P5)— 全部废弃,plugin 直接当 catalog(P6)+ active 3-layer(P7-P9)是终态。
>
> 详 `docs/20260403/plan1a-kong/docs/2026-05-19_decision_agents-vault-rollout.md`(P0-P9 演进 + 对齐 §2.2/§2.3/§2.5 检查表)+ `~/.claude/agents/INDEX.md`(user-level 角色清单)。

#### 2.7.0 角色可视化 4 channel(2026-05-18 加,N1/N2/N3 并行起 — 让"现在谁在干活"一眼可见)

**目的**:并发派多个 sub-agent 时,日志 / commit / PROGRESS / 报告 4 处都能立刻看出**哪个 Track · 哪个 Role · 哪个 Sprint · 哪个 Phase**。

| Ch | 位置 | 强制格式 | 示例 |
|---|---|---|---|
| **1** | Agent `description` 字段(Claude Code UI 实时显示 / 后台日志 / TaskList)| **`[T#·Role·Sprint·Phase] <任务一句话>`** | `[T1·BackendArchitect·N1-bk·P1-P3] 049 mig + Discovery 7 provider + 2 API` |
| **2** | commit subject role tag | **`<type>(<sprint>·<Role>): <what>`** | `feat(N1-bk·BackendArchitect): 049 migration + ProviderModelDiscovery 骨架` |
| **3** | PROGRESS `§🔄 当前进行中` 表 | 表头含 **Track ｜ Sprint ｜ Role(s) ｜ Phase ｜ Branch ｜ Status ｜ ETA** | 见 PROGRESS.md §🔄 实例 |
| **4** | sub-agent 返回 message **第一行** 强制 header | **`Agent: <Role> ｜ Track: <T#> ｜ Sprint: <N#-xx> ｜ Phase: <impl/review/test> ｜ Branch: <branch-name>`** | `Agent: Backend Architect ｜ Track: T1 ｜ Sprint: N1-bk ｜ Phase: impl ｜ Branch: claude/auto-xxx` |

**约定**(强制):
- Track 编号 `T1/T2/T3/T4...` 跨 sprint 不复用,每个 sprint 启动时 PM 给定
- Sprint 编号 `N1/N2/N3...` 来自 PROGRESS §🔴 ⚡ 的 N# 列;同 sprint 的不同 phase 子拆 `N1-bk` / `N1-fe` 等后缀
- Phase 字段值:`P#`(spec 阶段编号)/ `impl` / `review` / `test` / `merge`
- 派单稿模板里 description 字段**必含 ch1 前缀**;agent prompt 末尾**必含 ch2+ch4 指令**(commit 怎么写 + 报告怎么起手)
- PROGRESS §🔄 表 sprint 启动时 PM 写入 1 行,phase 切换 / merge 时 chore 分支 update
- **违反**:ch1 漏前缀 → PM 退回派单;ch2 漏 role tag → 下个 commit 补 amend(用户允许)or 新 commit 加说明;ch4 漏 header → agent 返回后 PM 在回复里手动补头

**Product Manager 派单**(按需,sprint 启动期 — spec→task 拆解 / discovery / PRD / Now-Next-Later 路线图):
```
Agent({
  description: "[T#·ProductManager·Sprint·plan] <规划任务一句话>",
  subagent_type: "Product Manager",
  prompt: "上下文:...(需求来源 / design 章节 / PROGRESS §🔮 候选)。
           任务:...(spec→可执行任务拆解 / discovery 综述 / PRD / Now-Next-Later 路线图 — 挑一)。
           产出:结构化文档,每个任务 / 路线图项含 owner + 成功指标 + 时间窗。
           禁止:替代主线 PM 决策(只产出建议,主线 Opus 拍板);不写实现代码。
           报告约定(ch4):返回 message 第一行 `Agent: Product Manager ｜ Track: <T#> ｜ Sprint: <N#> ｜ Phase: plan ｜ Branch: <branch>`。"
})
```

**Implementer 派单**(挑 1 个;**description 必含 ch1 前缀,prompt 末尾必含 ch2+ch4 指令**):
```
Agent({
  description: "[T#·Role·Sprint·Phase] <任务一句话>",
  subagent_type: "Backend Architect" | "Frontend Developer" | "Minimal Change Engineer",
  prompt: "上下文:...(贴 spec 章节 + 文件路径 + 行号)。
           任务:...(明确动作,最小变更范围)。
           验收:...(pytest 命令 / 期望测试通过 / 设计文档章节引用)。
           禁止:扩大重构 / 修改无关文件 / 跳过测试。
           Commit 约定(ch2):subject 必含 `<type>(<sprint>·<Role>): <what>` role tag。
           报告约定(ch4):返回 message 第一行必为 `Agent: <Role> ｜ Track: <T#> ｜ Sprint: <N#> ｜ Phase: <impl> ｜ Branch: <branch>`,后接变更文件清单 + 测试结果。"
})
```

**Code Reviewer 派单**:
```
Agent({
  description: "Review <PR>",
  subagent_type: "Code Reviewer",
  prompt: "审查范围:(具体文件列表 + diff hash)。
           Review 标准:
             1. 代码质量:可读性 / 错误处理 / 边界条件
             2. 设计契合:对照 design/01-04 + detail/A·B·C 章节
             3. 测试覆盖:核心 ≥ 90% / 整体 ≥ 80%
             4. 向后兼容:既有 baseline 全绿(主套件 1735/0/44, e2e 58/0/0)
           输出格式:✅ 通过 / ⚠️ 建议 / ❌ 阻断,每项 file:line"
})
```

**Tester (API) 派单**:
```
Agent({
  description: "API test <task>",
  subagent_type: "API Tester",
  prompt: "测试范围:(API endpoints + 期望 contract)。
           场景:happy path + 2-3 边界 + 1 error path。
           工具:curl / httpx / pytest。
           Bug 处置:发现即报,真 bug 用 gh issue create (详 §7.9)。
           完成报告:场景 PASS/FAIL 矩阵 + bug 清单 + issue 编号"
})
```

**Tester (UI/Browser) 派单**:
```
Agent({
  description: "UI evidence <scenario>",
  subagent_type: "Evidence Collector",
  prompt: "前置:通过 Bash run_in_background 启动 docker compose 或 npm run dev。
           场景:
             1. ...
             2. ...
           工具:必须用 mcp__claude-in-chrome 系列工具驱动浏览器
                必须用 read_console_messages 抓 console 错误
                必须用 read_network_requests 验证 API 调用
           Bug 处置:发现即报,真 bug 用 gh issue create (详 §7.9)。
           完成报告:场景 PASS/FAIL 矩阵 + console/network screenshot + bug + issue 编号"
})
```

**Security 派单**(按需,auth / token / data 改动):
```
Agent({
  description: "Security review <PR>",
  subagent_type: "Security Engineer",
  prompt: "审查范围:(具体文件列表 + diff hash)。
           Security 5 维:
             1. Secrets:不入 git/log;.env 配置;PR diff 全 scan
             2. Auth boundary:401 vs 403 vs 422 区分清晰;sk_* / JWT / X-Admin-Key 路径正确
             3. Input validation:Pydantic schema + 边界(长度/类型/SQL char)
             4. SQL injection / XSS / CSRF:参数化查询 / output escape / state token
             5. Audit log:敏感操作(login / token mgmt / admin op)有 audit trail
           输出格式:✅/⚠️/❌ 矩阵 + 每项 file:line + 推荐修复
           真 ❌ 阻断必用 gh issue 创建 [security] label (详 §7.9)"
})
```

**Reality Checker 派单**(按需,release / GA 前 / "done" 宣告复核):
```
Agent({
  description: "Reality check <release>",
  subagent_type: "Reality Checker",
  prompt: "审查范围:本 sprint claim 'done' 的 task list + evidence。
           Reality 5 标准:
             1. 测试 evidence:实际 pytest output 数字(不是描述)
             2. 浏览器 evidence:screenshot / console 无 error / network 验证
             3. 复现性:fix 是否真复现 bug + 测试是否真 reproduce
             4. 部署 readiness:docker stack 真启动 + 健康 + 端点响应
             5. 文档 evidence:runbook 步骤可执行 / 命令真有效
           输出:'PASS / NEEDS REWORK' verdict + 每项 evidence 链接(file:line / pytest output / screenshot 路径)"
})
```

**Codebase Onboarding 派单**(按需,陌生代码区):
```
Agent({
  description: "Map <module>",
  subagent_type: "Codebase Onboarding Engineer",
  prompt: "目标:画 <module> 架构图 + 模块责任 + 调用链路。
           范围:(具体目录 / 文件 glob)。
           输出:
             1. 架构图(Mermaid / text)+ entry point
             2. 主要 class / function 责任(file:line)
             3. 调用链路:外部入口 → service → repo / model
             4. 测试覆盖位置(对应 tests/<path>)
           禁止:写代码;只 evidence-based 调查。"
})
```

**Technical Writer 派单**(按需,文档密集):
```
Agent({
  description: "Write <docs>",
  subagent_type: "Technical Writer",
  prompt: "目标:写 <文档类型>:API doc / runbook / release notes / README / 迁移 guide。
           范围:(文件路径 + 章节 + 关联代码 file:line)。
           风格:对照既有 docs/admin_runbook.md 风格(中文优先,英文反引号包代码)。
           输出:具体 commit 内容 + 文件改动清单。"
})
```

**SRE 派单**(按需,部署 / 监控 / SLO / 应急规划):
```
Agent({
  description: "SRE review <topic>",
  subagent_type: "SRE (Site Reliability Engineer)",
  prompt: "审查范围:docker-compose / Dockerfile / monitoring / migration / runbook。
           SRE 5 标准:
             1. Deployment 可重现:docker compose / Dockerfile / requirements.txt 完整
             2. Monitoring 覆盖:新功能 alert + grafana panel + log 关键字
             3. Rollback SOP:migration 有 down.sql;feature flag 切换路径清晰
             4. 资源限制:memory/cpu limit 标注;db pool / redis 容量合理
             5. Runbook 完整:故障场景 + 排查步骤 + 联系人(写进 docs/admin_runbook.md)
           输出:✅/⚠️/❌ 矩阵 + 建议 docker-compose / runbook diff"
})
```

**DevOps Automator 派单**(按需,docker / CI/CD / monitoring 实装):
```
Agent({
  description: "DevOps automate <task>",
  subagent_type: "DevOps Automator",
  prompt: "目标:实装 docker-compose / Dockerfile / GitHub Action / Prometheus scrape / Grafana panel / alert rule / migration runbook 等。
           范围:具体 file 列表。
           风格:对照现有 kong-gateway/deployment/local/ + monitoring/ 模式。
           完成后报告:文件清单 + 部署 smoke test 命令"
})
```

**Database Optimizer 派单**(按需,DB 性能 / schema / migration):
```
Agent({
  description: "DB optimize <topic>",
  subagent_type: "Database Optimizer",
  prompt: "目标:DB 性能分析 / schema 优化 / 索引设计 / migration 影响评估。
           范围:具体 SQL / migration / 慢 query 日志。
           工具:EXPLAIN ANALYZE / pg_stat_statements。
           输出:索引 / 分表 / partition / cache 策略建议 + 风险评估"
})
```

**Incident Commander 派单**(按需,生产事故 / postmortem):
```
Agent({
  description: "Incident respond <event>",
  subagent_type: "Incident Response Commander",
  prompt: "事故描述:(symptom / 影响范围 / 开始时间)。
           可用证据:logs / metrics / traceback。
           任务:
             1. timeline 重构(发生 → 检测 → 缓解 → 恢复)
             2. RCA 5 Whys / fishbone
             3. action items(立刻 / 短期 / 长期)
             4. runbook 改进点
           输出:postmortem markdown + action items 优先级"
})
```
