# Superpowers Specs 任务状态报告

> **日期**: 2026-05-24
> **范围**: `templates/new-project/docs/superpowers/specs`
> **分支**: `feature/dev.template-optim`
> **状态**: 已更新；本报告同时记录 session review 命令实现结果

---

## 0. 摘要

`templates/new-project/docs/superpowers/specs` 当前包含 4 份设计 / 治理文档，以及 1 份 README 索引。

早期模板优化工作大多已经实施并验证。原本唯一明确尚未实现的任务，是新增手动触发的 `/project:session-review` 命令；本轮已进入实现阶段，并补齐命令、上下文收集脚本和用户工作风格示例文件。

推荐后续顺序：

1. 继续通过验证脚本确认 `/project:session-review` 的 collector 行为稳定。
2. 后续如需固化用户习惯，再由用户明确批准后复制 `user-working-style.md.example` 为正式规则文件。
3. 继续暂停 statusLine `light/hud` 模式切换和插件自动化策略，因为这些之前已按用户决策暂缓。

---

## 1. 文件清单

| 文件 | 作用 | 当前状态 |
|---|---|---|
| `2026-05-23-agent-pool-governance-design.md` | Agent 池与 L2/L3 分层治理设计 | 大部分已实现 |
| `2026-05-23-hook-noise-session-learning-design.md` | Hook 降噪与 session learning 设计 | Phase 1/2 已实现；Phase 3 暂停 |
| `2026-05-23-template-optimization-design.md` | 模板优化 Phase 2/3 设计 | 核心验收项已实现 |
| `2026-05-24-session-review-command-design.md` | 手动 session review 命令设计 | 已完成第一版实现 |
| `README.md` | specs 目录索引 | 已完成 |

---

## 2. 完成度概览

| 文档 | 估算完成度 | 说明 |
|---|---:|---|
| `agent-pool-governance-design.md` | 80% | 核心治理已完成；agent 边界 pilot 和 prompt 瘦身仍未做 |
| `hook-noise-session-learning-design.md` | 70% | SessionStart / SessionEnd 已完成；statusLine 模式切换暂停 |
| `template-optimization-design.md` | 90% | 功能验收基本完成；清单文字仍需同步 |
| `session-review-command-design.md` | 80% | 命令、collector、规则示例已实现；仍需真实 Claude Code 命令体验验证 |
| `README.md` | 100% | 目录索引已存在并列出设计文档 |

---

## 3. 分文档评审

### 3.1 `2026-05-23-agent-pool-governance-design.md`

已完成：

- 可复用 agent 池已完成 `name == filename stem` 标准化。
- `.enabled.example` 已成为项目按需启用 agent 的主要参考。
- L2 / L3 分层已反映到 new-project 模板。
- 项目本地 `_available` 现在优先于共享用户级 agent pool。
- SessionStart / SessionEnd 第一轮治理已经接入并记录。
- plugin metadata 状态文件已移出常规治理提交，不再作为普通项目改动反复污染 git。

未完成：

- `tools` / `maxTurns` / `effort` 的 agent boundary pilot 尚未实施。
- agent prompt 进一步瘦身仍属于后续阶段。
- 插件启用策略已决定采用手动方式，当前暂停自动化策略。

评估：

最初的“稳妥瘦身”目标大部分已经达成。剩余工作主要是优化项，不是阻塞级修复。

---

### 3.2 `2026-05-23-hook-noise-session-learning-design.md`

已完成：

- `agent-loader.sh` 正常路径已保持安静。
- `SessionEnd` 本地 session learning 已接入。
- `.claude/session-memory/` 已加入 ignore，不进入 git。
- 用户级 statusline 结构已经优化。
- 动态 Week reset 与 statusline 脚本重命名已在用户级配置中处理。

暂停 / 未实现：

- 完整 `CLAUDE_STATUSLINE_MODE=light/hud` 切换尚未实现。
- `statusline-light.sh` 尚未实现。
- new-project template 暂不同步 statusline，因为用户已明确当前显示效果可以保留。

评估：

该文档是“按决策部分完成”。剩余 statusline 工作已被明确降级，继续暂停是合理的。

---

### 3.3 `2026-05-23-template-optimization-design.md`

实际文件核对结果：

- `.claude/agents/_available/` 下有 8 个 agent 文件。
- `.claude/agents/` 根目录只保留 `.enabled.example` 和 `README.md`。
- `.enabled.example` 已说明 `_available` 启用方式。
- `.claude/agents/README.md` 已解释 agent 默认 disabled 的设计。
- `.claudeignore` 已忽略模板维护 specs 和参考文档。
- `/project:init` 已说明模板维护文档不属于项目工作上下文。
- 设计文档里列出的死链模式在 `.claude/rules` 下已无命中。
- `validate.sh` 和 `validate.ps1` 已存在。

已补充：

- 该设计文档中的 checklist 已更新为完成状态。
- 已追加 2026-05-24 实施状态，说明 `validate.sh` / `validate.ps1` 的必要性和暂停事项。

评估：

功能层面和文档状态已经对齐。后续只需要在真实新项目中继续观察 validate 脚本是否覆盖足够。

---

### 3.4 `2026-05-24-session-review-command-design.md`

当前状态：

- 设计文档已存在。
- 第一版实现已完成。

设计中预期文件：

```text
.claude/commands/project/session-review.md
.claude/scripts/session-review-context.sh
.claude/rules/user-working-style.md.example
```

评估：

该设计已经落地为保守实现。命令只收集 bounded context 并要求输出中文复盘，不自动修改规则、agent、plugin 或提交记录。

已实现内容：

1. 新增 `/project:session-review` 命令。
2. 新增 bounded context collector 脚本。
3. 新增 `user-working-style.md.example`。
4. 命令文本明确禁止自动编辑文件。
5. collector 只在 user-level session memory 的 `cwd` 与当前项目一致时读取，避免把其他项目的 session 记忆带入当前项目。

剩余验证：

- 需要在真实 Claude Code 命令环境中运行 `/project:session-review`，确认输出格式和上下文体量符合预期。

---

## 4. `validate.sh` / `validate.ps1` 是否有必要？

结论：**有必要保留，而且是当前模板可交付性的关键部分。**

理由：

1. **跨平台兜底不同**
   - `validate.sh` 面向 Ubuntu、Git Bash、CI-like shell。
   - `validate.ps1` 面向 Windows PowerShell，尤其能检查 `bash` 是否错误解析到 WSL launcher。

2. **它们验证的风险不是普通 lint 能覆盖的**
   - 必需文件是否存在。
   - `jq` 是否可用。
   - 占位符是否残留。
   - `.githooks` 是否正确安装。
   - 初始化产物是否已清理。
   - rules 内部链接是否有效。

3. **之前 dry-run 暴露的问题正是靠验证脚本闭环**
   - `.githooks` 绝对路径判断错误。
   - Windows Git Bash / PowerShell 行为差异。
   - placeholder 残留。
   - 初始化后是否真正 exit 0。

4. **它们不会增加 Claude Code session baseline**
   - 脚本文件存在于磁盘，不会自动进入上下文。
   - 只有显式运行 `/project:init` 或手动验证时才产生输出。

保留建议：

- 保留两个脚本。
- `SETUP.md` 继续要求初始化后至少运行一个平台对应脚本。
- 模板维护者在发版前建议两个都跑，尤其是 Windows 环境。

---

## 5. 本次核对命令

核对时使用的只读命令：

```text
Get-ChildItem -File templates/new-project/docs/superpowers/specs
rg -n "Status|状态|未完成|待|TODO|Open Questions|验收|完成|已完成|Phase|\[ \]" templates/new-project/docs/superpowers/specs
Get-ChildItem -File templates/new-project/.claude/agents/_available/*.md
Get-ChildItem -File templates/new-project/.claude/agents
rg -n dead-link patterns templates/new-project/.claude/rules
Test-Path templates/new-project/.claude/commands/project/session-review.md
Test-Path templates/new-project/.claude/scripts/session-review-context.sh
Test-Path templates/new-project/.claude/rules/user-working-style.md.example
```

观察结果：

- `_available` agent 数量：8
- 活跃 project agent 根目录文件：`.enabled.example`、`README.md`
- 死链模式扫描：无命中
- session review 实现文件：尚不存在
- 本报告首次生成前工作树：clean；本轮更新后产生了文档和实现文件改动

---

## 6. 推荐下一步

### 立即处理

运行完整验证并在真实 Claude Code 命令中试用 `/project:session-review`。

### 下一项功能

如用户认可 session review 输出，再单独实现“批准后固化 `user-working-style.md`”的手顺。

### 继续暂停

- 完整 statusline `light/hud` 切换
- new-project template statusline 同步
- 插件自动化策略
- 大范围 agent prompt 瘦身

这些要么已被用户明确暂停，要么更适合等手动 session review 工作流落地后再评估。
