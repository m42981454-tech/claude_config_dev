# Skill: my-dispatch-templates

> **触发时机**: 需要向 sub-agent 派单时 / 查具体 Agent({}) 格式时
> **来源**: 从 `.claude/rules/team-orchestration.md §2.7` 拆出，按需加载节省 baseline token

---

## 派单通用规范

**description 字段必含 ch1 前缀**: `[T#·Role·Sprint·Phase] <任务一句话>`

**Commit subject 必含 ch2 role tag**: `<type>(<sprint>·<Role>): <what>`

**返回 message 第一行必含 ch4 header**:
`Agent: <Role> ｜ Track: <T#> ｜ Sprint: <N#-xx> ｜ Phase: <impl/review/test> ｜ Branch: <branch>`

---

## Implementer 派单（挑 1 个）

```
Agent({
  description: "[T#·Role·Sprint·Phase] <任务一句话>",
  subagent_type: "Backend Architect" | "Frontend Developer" | "Minimal Change Engineer",
  prompt: "上下文：...（贴 spec 章节 + 文件路径 + 行号）。
           任务：...（明确动作，最小变更范围）。
           验收：...（pytest 命令 / 期望测试通过 / 设计文档章节引用）。
           禁止：扩大重构 / 修改无关文件 / 跳过测试。
           Commit 约定（ch2）：subject 必含 `<type>(<sprint>·<Role>): <what>` role tag。
           报告约定（ch4）：返回 message 第一行必为 `Agent: <Role> ｜ Track: <T#> ｜ Sprint: <N#> ｜ Phase: <impl> ｜ Branch: <branch>`，后接变更文件清单 + 测试结果。"
})
```

## Code Reviewer 派单

```
Agent({
  description: "Review <PR>",
  subagent_type: "Code Reviewer",
  prompt: "审查范围：（具体文件列表 + diff hash）。
           Review 标准：
             1. 代码质量：可读性 / 错误处理 / 边界条件
             2. 设计契合：对照 design/ 章节
             3. 测试覆盖：核心 ≥ 90% / 整体 ≥ 80%
             4. 向后兼容：既有 baseline 全绿
           输出格式：✅ 通过 / ⚠️ 建议 / ❌ 阻断，每项 file:line"
})
```

## Tester (API) 派单

```
Agent({
  description: "API test <task>",
  subagent_type: "API Tester",
  prompt: "测试范围：(API endpoints + 期望 contract)。
           场景：happy path + 2-3 边界 + 1 error path。
           工具：curl / httpx / pytest。
           Bug 处置：发现即报，真 bug 用 gh issue create（详 §7.9）。
           完成报告：场景 PASS/FAIL 矩阵 + bug 清单 + issue 编号"
})
```

## Tester (UI/Browser) 派单

```
Agent({
  description: "UI evidence <scenario>",
  subagent_type: "Evidence Collector",
  prompt: "前置：通过 Bash run_in_background 启动 dev server。
           场景：1. ... 2. ...
           工具：必须用 browser MCP 系列工具驱动浏览器；
                必须用 read_console_messages 抓 console 错误；
                必须用 read_network_requests 验证 API 调用。
           Bug 处置：发现即报，真 bug 用 gh issue create（详 §7.9）。
           完成报告：场景 PASS/FAIL 矩阵 + console/network screenshot + bug + issue 编号"
})
```

## Security 派单（按需，auth / token / data 改动）

```
Agent({
  description: "Security review <PR>",
  subagent_type: "Security Engineer",
  prompt: "审查范围：（具体文件列表 + diff hash）。
           Security 5 维：
             1. Secrets：不入 git/log；.env 配置；PR diff 全 scan
             2. Auth boundary：401 vs 403 vs 422 区分清晰
             3. Input validation：schema + 边界（长度/类型/SQL char）
             4. SQL injection / XSS / CSRF：参数化查询 / output escape / state token
             5. Audit log：敏感操作（login / token mgmt / admin op）有 audit trail
           输出格式：✅/⚠️/❌ 矩阵 + 每项 file:line + 推荐修复
           真 ❌ 阻断必用 gh issue 创建 [security] label（详 §7.9）"
})
```

## Reality Checker 派单（按需，release / GA 前 / "done" 宣告复核）

```
Agent({
  description: "Reality check <release>",
  subagent_type: "Reality Checker",
  prompt: "审查范围：本 sprint claim 'done' 的 task list + evidence。
           Reality 5 标准：
             1. 测试 evidence：实际 pytest output 数字（不是描述）
             2. 浏览器 evidence：screenshot / console 无 error / network 验证
             3. 复现性：fix 是否真复现 bug + 测试是否真 reproduce
             4. 部署 readiness：docker stack 真启动 + 健康 + 端点响应
             5. 文档 evidence：runbook 步骤可执行 / 命令真有效
           输出：'PASS / NEEDS REWORK' verdict + 每项 evidence 链接（file:line / pytest output / screenshot 路径）"
})
```

## Codebase Onboarding 派单（按需，陌生代码区）

```
Agent({
  description: "Map <module>",
  subagent_type: "Codebase Onboarding Engineer",
  prompt: "目标：画 <module> 架构图 + 模块责任 + 调用链路。
           范围：（具体目录 / 文件 glob）。
           输出：
             1. 架构图（Mermaid / text）+ entry point
             2. 主要 class / function 责任（file:line）
             3. 调用链路：外部入口 → service → repo / model
             4. 测试覆盖位置（对应 tests/<path>）
           禁止：写代码；只 evidence-based 调查。"
})
```

## Technical Writer 派单（按需，文档密集）

```
Agent({
  description: "Write <docs>",
  subagent_type: "Technical Writer",
  prompt: "目标：写 <文档类型>：API doc / runbook / release notes / README / 迁移 guide。
           范围：（文件路径 + 章节 + 关联代码 file:line）。
           风格：对照既有 docs/ 风格（中文优先，英文反引号包代码）。
           输出：具体 commit 内容 + 文件改动清单。"
})
```

## SRE 派单（按需，部署 / 监控 / SLO / 应急规划）

```
Agent({
  description: "SRE review <topic>",
  subagent_type: "SRE (Site Reliability Engineer)",
  prompt: "审查范围：docker-compose / Dockerfile / monitoring / migration / runbook。
           SRE 5 标准：
             1. Deployment 可重现：docker compose / Dockerfile / 依赖文件完整
             2. Monitoring 覆盖：新功能 alert + dashboard panel + log 关键字
             3. Rollback SOP：migration 有 down 路径；feature flag 切换路径清晰
             4. 资源限制：memory/cpu limit 标注；db pool / redis 容量合理
             5. Runbook 完整：故障场景 + 排查步骤 + 联系人（写进 runbook 文件）
           输出：✅/⚠️/❌ 矩阵 + 建议 docker-compose / runbook diff"
})
```

## DevOps Automator 派单（按需，docker / CI/CD / monitoring 实装）

```
Agent({
  description: "DevOps automate <task>",
  subagent_type: "DevOps Automator",
  prompt: "目标：实装 docker-compose / Dockerfile / GitHub Action / Prometheus scrape / Grafana panel / alert rule / migration runbook 等。
           范围：具体 file 列表。
           风格：对照现有部署 / 监控配置模式。
           完成后报告：文件清单 + 部署 smoke test 命令"
})
```

## Database Optimizer 派单（按需，DB 性能 / schema / migration）

```
Agent({
  description: "DB optimize <topic>",
  subagent_type: "Database Optimizer",
  prompt: "目标：DB 性能分析 / schema 优化 / 索引设计 / migration 影响评估。
           范围：具体 SQL / migration / 慢 query 日志。
           工具：EXPLAIN ANALYZE / pg_stat_statements 等 query plan 工具。
           输出：索引 / 分表 / partition / cache 策略建议 + 风险评估"
})
```

## Incident Commander 派单（按需，生产事故 / postmortem）

```
Agent({
  description: "Incident respond <event>",
  subagent_type: "Incident Response Commander",
  prompt: "事故描述：（symptom / 影响范围 / 开始时间）。
           可用证据：logs / metrics / traceback。
           任务：
             1. timeline 重构（发生 → 检测 → 缓解 → 恢复）
             2. RCA 5 Whys / fishbone
             3. action items（立刻 / 短期 / 长期）
             4. runbook 改进点
           输出：postmortem markdown + action items 优先级"
})
```

## Product Manager 派单（按需，spec→task 拆解 / discovery / PRD）

```
Agent({
  description: "[T#·ProductManager·Sprint·plan] <规划任务一句话>",
  subagent_type: "Product Manager",
  prompt: "上下文：...（需求来源 / design 章节 / PROGRESS §🔮 候选）。
           任务：...（spec→可执行任务拆解 / discovery 综述 / PRD / Now-Next-Later 路线图 — 挑一）。
           产出：结构化文档，每个任务 / 路线图项含 owner + 成功指标 + 时间窗。
           禁止：替代主线 PM 决策（只产出建议，主线 Opus 拍板）；不写实现代码。
           报告约定（ch4）：返回 message 第一行 `Agent: Product Manager ｜ Track: <T#> ｜ Sprint: <N#> ｜ Phase: plan ｜ Branch: <branch>`。"
})
```
