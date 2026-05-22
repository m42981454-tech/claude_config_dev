# Agent Pool Governance 设计履历

本文记录可复用 Claude Code agents 的分层治理设计，以及当前已经推进到的位置。

## 目标

让 agent 可以复用，但避免每个项目都加载一大批嘈杂、昂贵、边界过宽的 agent。项目只声明自己需要的 agent；共享池提供默认版本；项目如有特殊需求，用项目本地同名文件覆盖。

本文是设计履历，不是运行时规则。它放在新项目模板的 `docs/superpowers/specs` 下，用于给人阅读、复盘和延续后续阶段。

## 初始调查结论

本轮治理最初来自一次 Claude Code token/context 消耗过快的调查。主要结论如下：

- 项目级 `.claude/settings.local.json` 内容为空，不是 token 消耗来源，但它属于本机私有配置，不应进入 git tracking。
- 项目级 `CLAUDE.md` 很小，本身不是上下文膨胀主因。
- 项目启用的 3 个 agents 体量不算离谱，但每次 subagent 调用都会重复加载 agent prompt，因此长 prompt 会累积成本。
- 旧版 agent frontmatter 使用了展示名形式，例如 `Security Engineer`，不利于稳定匹配；应改为 kebab-case `agent ID`。
- `.enabled` 中曾存在不存在的 agent，loader 会报告 missing，形成启动噪音。
- 全局默认 `model` 和 `effortLevel` 是更大的成本来源，已改为更保守默认值。
- `SessionStart` hook、agent-loader 输出、statusline 脚本、插件启用情况都会影响体验或上下文噪音，后续需要单独治理。
- 所有三层 agents 暂未设置 `tools`、`maxTurns`、`effort` 边界，因此能力较宽，下一阶段应先做小范围试点。

## 优化方向总览

治理分为几个阶段，避免一次性改动过大：

1. Metadata governance：标准化 agent ID、`.enabled`、共享池规则和项目 override 规则。
2. Cost baseline：降低全局默认模型和 effort，减少默认消耗。
3. Boundary pilot：先在少量 review 类项目 agents 上验证 `tools`、`maxTurns`、`effort` 等边界。
4. Prompt slimming：把长示例、模板和 checklist 从 agent prompt 中拆到 docs，降低每次 agent 调用成本。
5. Loader hygiene：减少 SessionStart 噪音，区分 project-only agent 和真实 missing agent。
6. Global agent cleanup：标准化 `<global-claude-config>/agents` 下的默认 agents，保持少而精。
7. Template adoption：把稳定规则沉淀进 new-project template，让新项目从一开始使用较低噪音配置。

## 分层模型

- `<agent-reference-root>`：上游或供应方提供的完整 agent 参考库。它是素材来源，不是运行池。
- `<agent-dev-pool>`：精选后的可复用运行池。新加入的通用 agent 需要先在这里完成规范化。
- `<global-claude-config>/agents`：用户级全局默认 agent 集合。这里应该少而精，只放跨项目高频使用的 agent。
- `<project>/.claude/agents`：项目本地 agent 目录。同名文件优先，因为 loader 只复制缺失文件，不覆盖已有文件。
- `<project>/.claude/agents/.enabled`：项目启用清单，用来声明需要从共享池引入哪些 agent。

## 术语说明

- `agent ID`：稳定的 kebab-case 标识，同时作为文件名 stem 和 frontmatter `name`。
- `runtime pool`：loader 根据 `.enabled` 查找 agent 的共享池目录。
- `project-local override`：项目中与共享池同名的 agent 文件。它会覆盖共享池默认版本。
- `.enabled`：项目级 manifest，列出要从共享池 bootstrap 的 agent ID。

## Agent Metadata 规则

每个可复用 agent 是一个 Markdown 文件，文件名使用稳定的 kebab-case：

```text
security-engineer.md
api-tester.md
database-optimizer.md
```

frontmatter 的 `name` 必须等于去掉 `.md` 后的文件名：

```yaml
---
name: security-engineer
description: Short trigger-oriented description.
model: sonnet
color: red
---
```

人类可读的展示名称不要写进 `name`。例如不要使用 `Security Engineer`；展示语义放到 `description` 或正文里。

## 项目启用方式

项目通过 `.enabled` 声明需要的共享 agent：

```text
# enabled project agents
security-engineer
api-tester
database-optimizer
```

loader 按以下关系解析：

```text
<agent-dev-pool>/<agent-id>.md
```

并复制到：

```text
<project>/.claude/agents/<agent-id>.md
```

只有缺失文件会被复制。项目本地已经存在的同名 agent 不会被覆盖。

## new-project template 使用手顺

这个模板用于初始化一个带有 Claude Code 约定、项目规则、可选 agents、commands 和 skills 的新项目。建议把模板当作“起始骨架”，而不是运行时共享源。

建议手顺：

1. 创建或进入目标项目根目录。
2. 将 `<new-project-template>` 的内容复制到目标项目根目录。
3. 打开目标项目的 `CLAUDE.md`，替换项目名、阶段、日期、技术栈、目录结构和当前任务状态。
4. 检查 `<project>/.claude/settings.json` 和 `<project>/.claude/settings.local.json`：
   - 可共享的项目设置保留在 `settings.json`。
   - 本机私有设置放在 `settings.local.json`，并确认它不会进入 git tracking。
5. 编辑 `<project>/.claude/agents/.enabled`，只保留当前项目实际需要的共享 agent ID。
6. 启动或重载 Claude Code，让 loader 根据 `.enabled` 从 `<agent-dev-pool>` 复制缺失 agent。
7. 如果某个 agent 需要项目专属行为，编辑 `<project>/.claude/agents/<agent-id>.md`，不要直接修改共享池。
8. 按项目实际情况删减不需要的 rules、commands、skills，避免新项目一开始就带入过多上下文。
9. 建立或更新 `progress.md`，把它作为任务状态的唯一真相源。
10. 提交初始化结果时，先检查 `git status`，确保没有把本机私有配置、插件缓存或临时文件混入提交。

给 AI 执行模板初始化时，建议使用英文、明确、可验证的任务描述，例如：

```text
Initialize this repository from <new-project-template>.
Replace placeholders in CLAUDE.md.
Keep only project-relevant agents in .claude/agents/.enabled.
Do not commit local-only settings or plugin caches.
Report the copied files, removed template placeholders, and remaining TODOs.
```

## 项目覆盖规则

如果某个项目需要不同定义：

1. 保持同一个文件名和同一个 frontmatter `name`。
2. 在 `<project>/.claude/agents/<agent-id>.md` 放置项目本地版本。
3. `.enabled` 仍可以保留该 agent ID，作为项目启用清单和 bootstrap 说明。
4. loader 会跳过共享池版本，因为项目本地文件已经存在。

如果某个 agent 只属于单个项目，可以直接放在项目 `.claude/agents` 下；但如果当前 loader 仍按共享池查找 `.enabled`，则不在共享池中的 ID 可能被报告为 missing。后续可以优化 loader，让它识别 project-only agent。

## 目前已经完成

- 示例项目使用 `.enabled` 作为 active shared agents 的来源。
- 示例项目中的 `security-engineer`、`api-tester`、`database-optimizer` 已改为 kebab-case `name`。
- 示例项目的 `.claude/settings.local.json` 已退出 git tracking，并加入 ignore。
- `<agent-dev-pool>` 下新增了 `AGENT_RULES.md` 维护规则。
- `<agent-dev-pool>` 里的 44 个 agent 已完成 `name == filename stem` 标准化。
- 全局默认模型和 effort 已从高消耗默认值调整为更保守的默认值。
- `<global-claude-config>/agents` 下的 8 个全局默认 agents 已完成 `name == filename stem` 标准化；随后其中 4 个开发项目默认角色已下沉到 new-project template。
- loader 已调整为 project-local agent 优先：项目本地同名文件存在时，不再因为共享池缺失而报告 missing。
- new-project template 曾内置的 11 个 agents 已完成 `name == filename stem` 标准化。
- new-project template 已进一步清理重复/近重复 agent：模板本地保留开发项目默认角色和项目模板专属 agent，其余通过 `.enabled.example` 从 `<agent-dev-pool>` 按需启用。
- new-project template 的 `.enabled.example` 和 `CLAUDE.md` 已同步为 kebab-case agent ID、推荐测试角色和按需加载说明。

## new-project agent 补位评估

本次重新对照了三层 agent 配置：

- L2 用户级默认 4 个：覆盖 PM、代码审查、最小变更和 Git 工作流。
- L3 new-project 模板默认 5 个：覆盖多 agent 编排、后端、前端、现实复核，以及项目模板专属的 `project-management-jira-workflow-steward`。
- L1.5 dev 专家池 44 个：作为按需启用来源，不应全量复制进项目模板。

结论：模板内不应保留和 L1.5 dev 专家池重复/近重复的 agent 文件；但开发项目高频默认角色可以放在 new-project template 中，而不是长期放在用户级全局目录。这样用户级默认上下文更轻，新项目仍能保留完整开发工作流。

推荐按需启用角色：

| Agent ID | 补位原因 | 是否默认内置 |
|---|---|---|
| `security-engineer` | 登录、权限、密钥、OWASP、合规和威胁建模是常见发布闸门 | 否，按风险启用 |
| `api-tester` | API contract、endpoint 回归、服务间协议变更需要专门验证 | 否，按接口变更启用 |
| `test-results-analyzer` | 测试报告、失败分布、flaky pattern 和质量趋势需要专门分析 | 否，按测试分析需要启用 |
| `performance-benchmarker` | 延迟、吞吐、负载测试和性能瓶颈需要可复现基准 | 否，按性能风险启用 |
| `accessibility-auditor` | UI、表单、键盘导航、ARIA 和 WCAG 需要专门验收 | 否，按 UI/无障碍要求启用 |
| `devops-automator` | Docker、CI/CD、部署和监控属于常见交付链缺口 | 否，按交付链变更启用 |
| `evidence-collector` | UI、浏览器、日志、截图和复现证据能补足人工验收证明 | 否，按验收需要启用 |
| `codebase-onboarding-engineer` | 新项目或陌生仓库需要快速建立模块地图和风险地图 | 否，项目启动/接手时启用 |
| `technical-writer` | release notes、runbook、ADR、交接文档在交付后期常被遗漏 | 否，文档密集阶段启用 |
| `software-architect` | 跨系统设计和重大选型需要独立架构视角 | 否，重大设计时启用 |
| `ai-engineer` | ML、AI 集成、模型部署和生产 AI 功能需要专门实现视角 | 否，按 AI 项目启用 |
| `data-engineer` | ETL/ELT、dbt、lakehouse 和数据平台需要专门工程视角 | 否，按数据项目启用 |
| `database-optimizer` | schema、索引、慢查询、迁移影响和数据库性能需要专门审查 | 否，按数据库风险启用 |
| `incident-response-commander` | 生产事故、postmortem、on-call 和应急流程需要独立指挥视角 | 否，按生产事故启用 |
| `sre-site-reliability-engineer` | SLO、error budget、observability 和 toil reduction 需要可靠性治理 | 否，按可靠性治理启用 |
| `lsp-index-engineer` | LSP 编排、semantic indexing 和代码智能基础设施需要专门能力 | 否，按代码智能项目启用 |
| `mcp-builder` | MCP server、tools、resources、prompts 和 agent capability 集成需要专门能力 | 否，按 MCP 项目启用 |

测试类 agent 覆盖判断：

| Agent ID | 覆盖范围 | 不适合替代 |
|---|---|---|
| `api-tester` | API contract、endpoint health、集成回归、API 性能与安全关注 | 浏览器验收、整体测试报告分析、无障碍审计 |
| `test-results-analyzer` | 聚合测试结果、失败模式、flaky 分析、质量指标和改进建议 | 直接执行 API/E2E 测试 |
| `performance-benchmarker` | 性能基准、延迟、吞吐、瓶颈证明和优化验证 | 功能正确性测试 |
| `accessibility-auditor` | WCAG、键盘导航、屏幕阅读器、ARIA 和真实可访问性风险 | 视觉截图验收 |
| `evidence-collector` | 浏览器证据、截图、日志、复现步骤和现实检查 | API contract 或性能基准 |

本阶段已经把上述建议写入：

- `templates/new-project/.claude/agents/.enabled.example`
- `templates/new-project/CLAUDE.md`

设计原则保持不变：用户级只保留跨项目高频基础角色；new-project template 保留开发项目默认角色；项目差异通过 `.enabled` 从 `<agent-dev-pool>` 复制；只有当某个角色是模板默认工作流、模板自身专属约定，或需要覆盖共享池行为时，才放进 L3 项目本地 agent 目录。

## Claude Code 配置稳妥瘦身方案完成度

本节记录最初“稳妥瘦身方案”的实现程度。

已完成：

1. 修正项目 agent frontmatter：
   - `security-engineer.md` 的 `name` 已改为 `security-engineer`。
   - `api-tester.md` 的 `name` 已改为 `api-tester`。
   - `database-optimizer.md` 的 `name` 已改为 `database-optimizer`。
   - 仅改 metadata，未改正文行为。
2. 清理项目 `.enabled`：
   - 已删除不存在的 agent 条目。
   - 已统一使用 kebab-case agent ID。
3. 处理项目 `.claude/settings.local.json`：
   - 文件内容保持本机本地用途。
   - 已从 git tracking 中移除。
   - 已加入 ignore，避免后续误提交。
4. 全局降耗：
   - 默认 `model` 已从高成本默认值调整为更保守默认值。
   - 默认 `effortLevel` 已从高成本默认值调整为更保守默认值。
5. 共享池 metadata 标准化：
   - `<agent-dev-pool>` 中 44 个 agents 已完成 `name == filename stem`。
   - 已新增 `<agent-dev-pool>/AGENT_RULES.md` 作为后续新增 agent 的维护规则。
6. 全局默认 agents metadata 标准化：
   - `<global-claude-config>/agents` 中 8 个默认 agents 已完成 `name == filename stem`。
   - 其中 `agents-orchestrator`、`backend-architect`、`frontend-developer`、`reality-checker` 已下沉到 new-project template，用户级保留 4 个更通用的基础 agent。
7. loader hygiene 初步处理：
   - project-local-only agent 已可通过本地同名文件避免 missing 噪音。
8. new-project template 一致性：
   - 模板本地 agent 已从 11 个重复/近重复 agent 清理后，调整为 5 个项目默认 agent。
   - 模板默认保留 `agents-orchestrator`、`backend-architect`、`frontend-developer`、`reality-checker`、`project-management-jira-workflow-steward`。
   - 重复/近重复的通用专家已从模板本地 agent 目录移除，改由 `.enabled.example` 按需启用。
   - `.enabled.example` 已改为 kebab-case agent ID 示例，并补充测试、性能、可访问性、证据采集等推荐角色。
   - 模板 `CLAUDE.md` 中的 agent 表格、动态加载示例、派单示例和测试类 agent 覆盖判断已同步到新策略。

已验证：

- 示例项目 agent frontmatter 与文件名一致。
- 示例项目 `.enabled` 中每个 ID 都能映射到项目本地 agent 文件。
- 项目本地 settings 文件未再被 git tracking。
- `<agent-dev-pool>` 中 agent `name` 不合规项为 0。
- `<global-claude-config>/agents` 中 agent `name` 不合规项为 0。
- new-project template 默认 agent `name` 不合规项为 0。
- new-project template 内置 agents 的 `name` 不合规项为 0。
- 相关文档不包含固定本机路径。

尚未纳入本阶段：

- 未给 agents 添加 `tools`、`maxTurns` 或 `effort` 边界。
- 未瘦身长 agent prompt。
- 未治理 `SessionStart` hook、statusline 脚本和插件启用策略。

结论：最初“稳妥瘦身方案”的项目内配置部分已经完成；共享池 metadata、全局默认 agents metadata 和 loader 的 project-local 优先处理也已完成。剩余项属于下一阶段的边界治理、prompt 瘦身和更深入的 hook/statusline 治理。

## 当前阶段

当前处于 metadata governance 阶段。

已完成：

- 分层角色已定义。
- 共享池 agent ID 已标准化。
- 项目 `.enabled` 行为已记录。
- 项目本地覆盖行为已记录。
- 新项目模板中已保留本设计履历。
- 全局默认 agents 已完成 metadata 标准化，并已下沉 4 个开发项目默认角色到 new-project template。
- loader 已支持 project-local-only agent 不产生共享池 missing 噪音。

未完成：

- 尚未给 agent 添加 `tools`、`maxTurns` 或 `effort` 边界。
- 尚未把长 agent prompt 中的大段示例拆到 docs 中。
- 尚未治理 `SessionStart` hook 输出和 statusline 脚本复杂度。
- 尚未对插件启用策略做分层记录，避免无关插件增加上下文或工具噪音。

## 下一阶段建议

下一阶段应先做小范围边界试点，而不是一次性限制所有 agents。

建议试点对象：

1. `security-engineer`
2. `api-tester`
3. `database-optimizer`

试点步骤：

1. 先确认目标 Claude Code 版本支持计划使用的 frontmatter keys。
2. 只在项目本地 review 类 agent 上添加保守边界。
3. 用真实任务测试调用效果。
4. 确认没有丢失必要工具或明显降低输出质量后，再推广到共享池。

不要一开始就全量添加 tool restrictions。构建、研究、实现、事故响应类 agent 往往需要比 review 类 agent 更宽的工具能力。

## L2 基础 agent 二阶段瘦身设计

本阶段重新评估了 `<global-claude-config>/agents` 下 8 个用户级默认 agent 与 `<agent-reference-root>/testing`、`<agent-dev-pool>` 的关系，并已执行第一轮下沉。

关键结论：

- `testing-api-tester` 没有进入 L2 基础 agent，并不是遗漏，而是因为它属于专项 API 验证能力。
- L2 的 `backend-architect` 可以设计 API，`code-reviewer` 可以发现 breaking API contract，`reality-checker` 可以要求最终证据，但它们都不应该替代 `api-tester` 执行接口契约、端点健康、集成回归、性能和安全验证。
- 同理，`accessibility-auditor`、`performance-benchmarker`、`evidence-collector`、`test-results-analyzer`、`security-engineer` 等都应作为按需启用的专项角色，而不是全部并入 L2 prompt。

本阶段已经做的调整：

1. `.enabled.example` 中把原先过强的来源措辞改为“推定来源 / 覆盖参考”，并说明这来自 reference 目录角色职责对照，不是 agent 文件中的显式血缘字段。
2. 8 个 L2 用户级 agent 已新增轻量 `Boundary and Delegation` 段落：
   - `project-manager-senior`：规划时识别 API、安全、性能、无障碍、DevOps、数据库等专项验收角色。
   - `agents-orchestrator`：编排时将专项验证路由给对应 agent，而不是自己吞并能力。
   - `backend-architect`：只负责后端设计，API 测试、DB 性能、安全对抗和部署流水线交给专项角色。
   - `frontend-developer`：只做基础前端实现与基础 hygiene，浏览器证据、正式无障碍和深度性能验证交给专项角色。
   - `code-reviewer`：把缺失的专项证据作为 review finding，不把代码审查伪装成完整验证。
   - `reality-checker`：作为最终证据闸门，要求或复核专项 agent 的证据，缺失则判定 `NEEDS WORK`。
   - `minimal-change-engineer`：发现跨域风险时记录 follow-up，不扩大当前最小修复范围。
   - `git-workflow-master`：只管理 Git 边界，不用 Git 操作绕过质量闸门。
3. 已把 4 个开发项目默认角色从用户级下沉到 new-project template：
   - `agents-orchestrator`
   - `backend-architect`
   - `frontend-developer`
   - `reality-checker`
4. 用户级全局目录当前保留 4 个更通用的基础角色：
   - `project-manager-senior`
   - `code-reviewer`
   - `minimal-change-engineer`
   - `git-workflow-master`

当前分层结果：

| 层级 | 建议保留/下沉 | 理由 |
|---|---|---|
| 用户级默认 | `project-manager-senior`、`minimal-change-engineer`、`git-workflow-master`、`code-reviewer` | 跨项目、跨任务高频；用于规划、最小改动、Git 和审查基础能力 |
| 项目模板默认 | `agents-orchestrator`、`backend-architect`、`frontend-developer`、`reality-checker`、`project-management-jira-workflow-steward` | 更像开发项目工作流角色；放入模板后，新项目可用，但普通用户级会话不再默认加载 |
| 项目按需启用 | `api-tester`、`security-engineer`、`evidence-collector`、`performance-benchmarker`、`accessibility-auditor` 等 | 专项能力强，但默认加载会增加上下文和工具面 |

后续迁移原则：

- 先观察用户级 4 个 + 模板默认 5 个的实际使用效果。
- 如果用户级默认上下文仍然过重，再评估是否把 `project-manager-senior` 也下沉到 new-project template。
- 用户级只保留最通用、跨项目、跨任务都成立的角色。

## Claude Code 额度耗尽时的离线手顺

如果 Claude Code 额度暂时耗尽，不建议强行推进需要真实 Claude Code 调用验证的事项，例如 agent boundary pilot。可以先做不依赖 Claude Code 额度的本地工作。

可以继续做：

1. 文档整理：
   - 补充设计履历。
   - 合并或删除重复 progress 文档。
   - 把已完成、未完成、下一阶段写清楚。
2. 静态检查：
   - 检查 agent 文件名和 frontmatter `name` 是否一致。
   - 检查文档是否包含固定本机路径。
   - 检查 `.enabled` 是否只列出实际存在的共享 agent ID。
3. Git hygiene：
   - 用 `git status` 区分本轮改动和既有 staged/unstaged 变更。
   - 分主题提交，避免把插件缓存、local settings、模板文档混在一起。
4. 方案准备：
   - 为下一阶段写计划。
   - 标记哪些步骤需要等 Claude Code 额度恢复后验证。
   - 准备可复制给 AI 的英文验证指令。

暂缓执行：

- 真实调用 Claude Code subagent 验证 `tools`、`maxTurns`、`effort`。
- 修改会影响所有 agents 的工具边界。
- 大规模瘦身 agent prompt。
- 调整 `SessionStart` hook 或 statusline 后直接宣称体验改善。

给 AI 继续离线整理时，可以使用英文任务描述：

```text
Continue only local, non-Claude-Code-quota-dependent maintenance.
Do not run Claude Code agent invocations.
Update docs, run static checks, and mark any runtime validation as pending.
```

## 验证清单

把 agent 推入共享池前，至少检查：

1. 文件名是 kebab-case，并以 `.md` 结尾。
2. frontmatter 从第一行 `---` 开始。
3. `name` 等于文件名去掉 `.md` 后的值。
4. `description` 简短，并面向触发场景。
5. `model` 存在。
6. 没有本机路径、密钥、项目专属假设。
7. 这个 agent 确实值得跨项目共享。

给 AI 或脚本确认 metadata 时，可以使用英文输出，便于直接复制到自动化检查中：

```powershell
Get-ChildItem <agent-dev-pool> -Filter *.md |
  ForEach-Object {
    $expected = $_.BaseName
    $name = (Select-String -Path $_.FullName -Pattern '^name:' |
      Select-Object -First 1).Line -replace '^name:\s*',''
    if ($name -ne $expected) {
      "BAD $($_.Name): name is '$name', expected '$expected'"
    }
  }
```
