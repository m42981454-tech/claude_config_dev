# Claude Code 开发最佳实践完全指南

> 整合自 Anthropic 官方文档、GitHub 社区顶级 Repo、开发者论坛实战经验  
> 最后更新：2026年5月 | 覆盖 Claude Code v2.1.x · Sonnet 4.6 / Opus 4.7 / Haiku 4.5

---

## 目录

1. [核心约束：Context Window 是第一资源](#1-核心约束context-window-是第一资源)
2. [CLAUDE.md：持久化上下文配置](#2-claudemd持久化上下文配置)
3. [Hooks：确定性的强制执行机制](#3-hooks确定性的强制执行机制)
4. [Subagents：Context 隔离的最强武器](#4-subagentscontext-隔离的最强武器)
5. [Skills：按需加载的领域知识](#5-skills按需加载的领域知识)
6. [Context 管理：日常操作策略](#6-context-管理日常操作策略)
7. [工作流设计：Explore → Plan → Code → Commit](#7-工作流设计explore--plan--code--commit)
8. [大规模自动化：并行与 CI 集成](#8-大规模自动化并行与-ci-集成)
9. [社区顶级方案 GitHub Repo](#9-社区顶级方案-github-repo)
10. [社区讨论平台](#10-社区讨论平台)
11. [选型决策矩阵](#11-选型决策矩阵)
12. [速查清单](#12-速查清单)

---

## 1. 核心约束：Context Window 是第一资源

Claude 的 context window 承载着整个对话内容，包括每条消息、每个读取的文件、每条命令输出。单次调试会话或代码库探索就可能消耗数万 token。**随着 context 填满，LLM 性能会显著下降**——Claude 可能开始"遗忘"早期指令或犯更多错误。

### 理解 Token 消耗的三大来源

| 来源 | 说明 | 优化手段 |
|------|------|----------|
| 长文件读取 | 500行文件只需20行时，仍全量加载 | `.claudeignore`、精确引用 |
| 冗长对话来回 | 多轮修正中重复解释上下文 | `/clear` 重置，改写 prompt |
| 重复 context 注入 | 每条消息都补充背景信息 | CLAUDE.md 一次性定义 |

> **关键认知**：当 Claude Code context 达到 200k token 时，真正变难的不是读取，而是**生成质量**。那些"空闲"的 context 空间并非浪费——那里才是推理发生的地方。

---

## 2. CLAUDE.md：持久化上下文配置

CLAUDE.md 是每次对话开始时 Claude 自动读取的特殊文件，用于存放 Bash 命令、代码风格和工作流规则。

### 快速启动

```bash
# 基于当前项目结构自动生成 CLAUDE.md
/init
```

### 写什么 vs 不写什么

| ✅ 应该写 | ❌ 不应该写 |
|-----------|-------------|
| Claude 无法猜到的 Bash 命令 | Claude 读代码就能知道的内容 |
| 与默认值不同的代码风格规则 | 标准语言规范（Claude 已知） |
| 测试指令和首选测试运行器 | 详细 API 文档（改用链接） |
| 仓库规范（分支命名、PR 约定） | 经常变化的信息 |
| 项目特有的架构决策 | 逐文件描述代码库 |
| 开发环境特殊配置（必需环境变量） | "写干净代码"这类显而易见的话 |
| 常见坑或非显而易见的行为 | 长篇解释或教程 |

### 示例结构

```markdown
# CLAUDE.md

## Code Style
- Use ES modules (import/export), not CommonJS (require)
- Destructure imports when possible

## Workflow
- Typecheck after a series of code changes
- Run single tests, not the whole suite, for performance

## Architecture
- Frontend: Next.js 15 with App Router
- Database: PostgreSQL with Prisma ORM
- All API routes use tRPC

## Commands
- Build: `npm run build`
- Test: `npm test -- --testPathPattern=<file>`
- Lint: `npm run lint`

## When compacting, always preserve:
- Full list of modified files
- Any test commands used in this session
```

### 分层加载：多位置 CLAUDE.md

```
~/.claude/CLAUDE.md          → 全局，应用于所有会话
./CLAUDE.md                  → 项目级，提交 git 与团队共享
./CLAUDE.local.md            → 个人笔记，加入 .gitignore
./subdir/CLAUDE.md           → 子目录，Claude 按需加载
```

支持 `@path/to/import` 语法导入其他文件：

```markdown
See @README.md for project overview and @package.json for npm commands.

# Additional Instructions
- Git workflow: @docs/git-instructions.md
- Personal overrides: @~/.claude/my-project-instructions.md
```

### Token 精简原则

> 对每一行内容问自己：**"删掉这行会导致 Claude 犯错吗？"** 如果不会，就删掉。  
> 臃肿的 CLAUDE.md 会导致 Claude 忽略你的真实指令。

- 用 `IMPORTANT:` 或 `YOU MUST` 强调关键规则以提高遵守率
- CLAUDE.md 文件长度建议控制在 **100行以内**
- 把 CLAUDE.md 当代码维护：出问题时审查，定期剪枝，观察行为变化

---

## 3. Hooks：确定性的强制执行机制

### CLAUDE.md vs Hooks 的本质区别

| 特性 | CLAUDE.md | Hooks |
|------|-----------|-------|
| 性质 | **建议性**，模型可能遗忘 | **确定性**，物理强制执行 |
| 适用场景 | 风格偏好、流程建议 | 安全检查、强制规范 |
| 绕过可能性 | 有（特别是长 context） | 无 |

> **核心原则**：Hooks 保证行为，Prompts 建议行为。对于**不可妥协的约束**，永远不要只依赖提示词。

### Hook 事件类型（18+ 种）

| 事件 | 触发时机 | 典型用途 |
|------|----------|----------|
| `PreToolUse` | 工具调用前 | 安全检查、危险命令拦截 |
| `PostToolUse` | 工具调用后 | 自动 lint、格式化 |
| `Stop` | Claude 停止时 | 汇报结果、触发下一步 |
| `SubagentStop` | Subagent 停止时 | 协调多 agent 流程 |
| `SessionStart` | 会话开始时 | 环境检查、上下文预加载 |
| `SessionEnd` | 会话结束时 | 日志记录、清理 |
| `Notification` | Claude 发出通知时 | 自定义通知处理 |

### 配置示例（`.claude/settings.json`）

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "echo '检查命令安全性...' && your-safety-check.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "eslint $TOOL_INPUT_PATH --fix"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cat .claude/queue.txt | head -1"
          }
        ]
      }
    ]
  }
}
```

### 实用 Hook 场景

**① 知识图谱辅助搜索**（避免盲目 grep 浪费 context）
```json
{
  "PreToolUse": [{
    "matcher": "Bash",
    "hooks": [{
      "type": "command",
      "command": "CMD=$(python3 -c \"import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',d).get('command',''))\" 2>/dev/null || true); case \"$CMD\" in *grep*|*rg\\ *|*find\\ *) [ -f graph.json ] && echo 'Knowledge graph exists. Check GRAPH_REPORT.md before raw search.' || true ;; esac"
    }]
  }]
}
```

**② 阻止写入特定目录**
```json
{
  "PreToolUse": [{
    "matcher": "Write",
    "hooks": [{
      "type": "command",
      "command": "if [[ \"$TOOL_INPUT_PATH\" == *migrations* ]]; then echo 'BLOCKED: migrations folder is read-only'; exit 1; fi"
    }]
  }]
}
```

> **生成 Hook 的快捷方式**：直接告诉 Claude "写一个 hook，在每次文件编辑后运行 eslint"，然后检查生成的 `.claude/settings.json`。运行 `/hooks` 可查看当前所有 Hook 配置。

---

## 4. Subagents：Context 隔离的最强武器

### 为什么要用 Subagent

Subagent 在独立的 context window 中运行并汇报摘要，不污染主对话。当 Claude 探索代码库时会读取大量文件，这些都消耗主 context——用 Subagent 隔离是保持主 context 清洁最有效的手段。

### 定义 Subagent（`.claude/agents/agent-name.md`）

```markdown
---
name: security-reviewer
description: Reviews code for security vulnerabilities. Use when implementing auth, handling user input, or before PR merge.
tools: Read, Grep, Glob, Bash
model: opus
maxTurns: 20
---

You are a senior security engineer. Review code for:
- Injection vulnerabilities (SQL, XSS, command injection)
- Authentication and authorization flaws
- Secrets or credentials in code
- Insecure data handling

Provide specific line references and suggested fixes.
Report findings as: [SEVERITY: HIGH/MEDIUM/LOW] Description
```

### YAML Frontmatter 完整配置项

```yaml
---
name: agent-name                    # 必填：唯一标识
description: When to use this agent # 必填：Claude 据此自动委派
tools: Read, Grep, Glob, Bash       # 可选：省略则继承全部工具
disallowedTools: WebSearch          # 可选：明确禁止的工具
model: opus                         # 可选：haiku/sonnet/opus/inherit
permissionMode: acceptEdits         # 可选：acceptEdits/plan/bypassPermissions
maxTurns: 30                        # 可选：最大 agentic 轮次
skills:                             # 可选：预加载的 skill 列表
  - api-conventions
  - testing-patterns
hooks:                              # 可选：该 subagent 专属 hooks
  PostToolUse:
    - matcher: Write
      hooks:
        - type: command
          command: "eslint $TOOL_INPUT_PATH"
background: false                   # 可选：true 则始终后台运行
---
```

### 高效使用模式

```bash
# 调研任务委派给 subagent（保护主 context）
"Use subagents to investigate how our authentication system handles
token refresh, and whether we have any existing OAuth utilities I should reuse."

# 代码审查用独立 subagent（避免偏见）
"Use a subagent to review this code for edge cases and security issues."

# Writer/Reviewer 双 Session 模式
# Session A: "Implement a rate limiter for our API endpoints"
# Session B: "Review @src/middleware/rateLimiter.ts for edge cases and race conditions"
# Session A: "Address this review feedback: [Session B output]"
```

> **工具白名单原则**：如果省略 `tools`，Subagent 会继承所有可用工具（包括 MCP）。需要严格控制时请明确白名单。

---

## 5. Skills：按需加载的领域知识

Skills 与 CLAUDE.md 的核心区别：**CLAUDE.md 每次都加载，Skills 按需加载**。只在某些场景用到的领域知识放 Skills，不增加每次会话的负担。

### 创建 Skill（`.claude/skills/<name>/SKILL.md`）

**场景一：知识型 Skill（规范文档）**

```markdown
---
name: api-conventions
description: REST API design conventions for our services
---

# API Conventions
- Use kebab-case for URL paths: /user-profiles not /userProfiles
- Use camelCase for JSON properties
- Always include pagination for list endpoints (page, limit, total)
- Version APIs in the URL path (/v1/, /v2/)
- Error format: { "error": { "code": "AUTH_FAILED", "message": "..." } }
```

**场景二：工作流型 Skill（可直接调用的流程）**

```markdown
---
name: fix-issue
description: Fix a GitHub issue end-to-end
disable-model-invocation: true  # 有副作用，需手动触发
---

Fix GitHub issue: $ARGUMENTS

1. `gh issue view $ARGUMENTS` — 获取 issue 详情
2. 理解问题，定位相关文件
3. 搜索代码库找到根因
4. 实现修复
5. 写测试并运行验证
6. 确保 lint 和 type check 通过
7. 创建 descriptive commit
8. Push 并创建 PR
```

调用方式：`/fix-issue 1234`

### Skill 适用场景

| 场景 | 放 CLAUDE.md | 用 Skills |
|------|-------------|-----------|
| 每次都需要的基础规范 | ✅ | - |
| 特定领域的技术约定 | - | ✅ |
| 可重复的完整工作流 | - | ✅ |
| 偶发性参考文档 | - | ✅ |

> **Subagent + Skills 组合**：在 Subagent 的 YAML 中用 `skills:` 字段预加载，让专属 agent 携带必要知识进入独立 context。

---

## 6. Context 管理：日常操作策略

### 核心命令速查

| 命令 | 场景 | 说明 |
|------|------|------|
| `/clear` | 任务切换 | 完全重置 context window |
| `/compact` | 长会话 | 自动压缩，保留关键信息 |
| `/compact Focus on API changes` | 精准压缩 | 指定压缩重点 |
| `/btw <问题>` | 快速查询 | 悬浮答案，不进对话历史 |
| `Esc` | 中途纠错 | 中断但保留 context |
| `Esc+Esc` 或 `/rewind` | 回滚 | 恢复到任意检查点 |
| `/rename` | 多任务管理 | 命名 session（如 oauth-migration） |
| `claude --continue` | 续接会话 | 继续最近的会话 |
| `claude --resume` | 选择续接 | 从列表选择历史会话 |

### .claudeignore：排除无用文件

```gitignore
# .claudeignore
node_modules/
dist/
build/
.next/
coverage/
*.log
*.lock
*.min.js
*.min.css
docs/generated/
```

### 压缩行为定制（在 CLAUDE.md 中配置）

```markdown
## Compaction Rules
When compacting, always preserve:
- Full list of modified files (with paths)
- All test commands that were run and their results
- Current sprint goals and constraints
- Any architectural decisions made this session
- Error messages and their resolutions
```

### 五大常见失败模式

| 失败模式 | 症状 | 解决方案 |
|----------|------|----------|
| **厨房水槽会话** | 一个 session 里混合不相关任务 | `/clear` 分割任务 |
| **反复纠错循环** | 同一问题纠正 2 次以上 | `/clear` 然后重写更好的初始 prompt |
| **臃肿 CLAUDE.md** | Claude 忽略重要规则 | 无情剪枝，转 Skills 或 Hooks |
| **无限探索** | Claude 读取上百个文件 | 明确范围，或委派给 Subagent |
| **信任鸿沟** | 看起来对但实际有问题的实现 | 始终提供验证标准（测试/脚本/截图） |

---

## 7. 工作流设计：Explore → Plan → Code → Commit

### 标准四阶段流程

```
阶段 1：探索（Plan 模式）
  ↓ 进入 plan mode（只读，不修改）
  ↓ "Read /src/auth and understand session handling and env vars"

阶段 2：规划
  ↓ "Create a detailed implementation plan for Google OAuth"
  ↓ Ctrl+G 在编辑器中直接修改计划

阶段 3：实施
  ↓ 退出 plan mode
  ↓ "Implement the OAuth flow from your plan. Write tests, run and fix failures."

阶段 4：提交
  ↓ "Commit with a descriptive message and open a PR"
```

### 何时跳过规划

| 需要规划 | 可以跳过 |
|----------|----------|
| 不确定实现方案 | 一句话能描述的 diff |
| 修改跨多个文件 | 修复 typo、加 log |
| 不熟悉相关代码库 | 改变量名等小修改 |

### 让 Claude 采访你（大型功能）

```
I want to build [brief description]. Interview me in detail using the AskUserQuestion tool.

Ask about technical implementation, UI/UX, edge cases, concerns, and tradeoffs.
Don't ask obvious questions, dig into the hard parts I might not have considered.

Keep interviewing until we've covered everything, then write a complete spec to SPEC.md.
```

完成后，**开新 session** 执行——新 session 有干净 context，而你有完整的 SPEC.md 作参考。

---

## 8. 大规模自动化：并行与 CI 集成

### 非交互模式

```bash
# 单次查询
claude -p "Explain what this project does"

# 结构化输出（供脚本解析）
claude -p "List all API endpoints" --output-format json

# 流式输出
claude -p "Analyze this log file" --output-format stream-json

# 带权限限制的批量运行
claude -p "Fix all lint errors" \
  --allowedTools "Edit,Bash(eslint *,npm run lint)" \
  --permission-mode auto
```

### Fan-out 并行处理（大规模迁移）

```bash
# 步骤1：生成任务列表
claude -p "List all Python files that need React→Vue migration" > files.txt

# 步骤2：先用 3 个文件测试 prompt
head -3 files.txt | while read file; do
  claude -p "Migrate $file from React to Vue. Return OK or FAIL." \
    --allowedTools "Edit,Bash(git commit *)" \
    --output-format json
done

# 步骤3：验证无误后全量运行
cat files.txt | while read file; do
  claude -p "Migrate $file from React to Vue." \
    --allowedTools "Edit,Bash(git commit *)"
done
```

### Git Worktree 并行实验

```bash
# 创建隔离工作树，多个 Claude session 并行不冲突
git worktree add ../project-feature-a feature-a
git worktree add ../project-feature-b feature-b

# 在不同目录分别启动 Claude session
cd ../project-feature-a && claude
cd ../project-feature-b && claude
```

### CI 集成示例（GitHub Actions）

```yaml
- name: Claude Code Review
  run: |
    claude -p "Review the changes in this PR for security issues and code quality.
    Focus on: @src/api/ @src/auth/
    Output findings as JSON with severity levels." \
    --output-format json \
    --allowedTools "Read,Glob,Grep" \
    > review-results.json
```

---

## 9. 社区顶级方案 GitHub Repo

### 🥇 Superpowers（`obra/superpowers`）— 174k+ ⭐

**定位**：把工程文化编码成 markdown 文件夹，强制执行专业开发方法论

**7阶段工作流（强制，不可跳过）**：
```
Brainstorm → Spec → Plan → TDD → Subagent Development → Review → Finalize
```

**核心特性**：
- 每个任务使用全新 Subagent，防止 context 漂移
- 强制 RED-GREEN-REFACTOR TDD 循环（先写失败的测试）
- 四阶段调试方法论（根因调查先于修复）
- 苏格拉底式头脑风暴（编码前精炼需求）
- 跨平台支持：Claude Code / Cursor / Codex / GitHub Copilot CLI / Gemini CLI / OpenCode

**安装**：
```bash
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

**最佳使用原则**：
- ✅ 适合：明确需求的功能开发、重构已有代码库
- ❌ 不适合：模糊探索、快速一行 bug fix

> *"永远不要跳过手动 Plan 审查步骤——Plan 质量直接决定执行质量。"* — Jesse Vincent（Superpowers 作者）

---

### 🥈 Everything Claude Code（`affaan-m/everything-claude-code`）— 100k+ ⭐

**定位**：最全面的 Agent 框架，Anthropic Hackathon 获奖项目

**功能**：
- 135 个预置 Agents
- 安全扫描集成
- 内存优化策略
- NanoClaw v2 模型路由
- 支持 12 种语言生态系统
- 跨工具支持：Claude Code + Codex + OpenCode + Cursor

**适合场景**：企业团队、需要安全扫描和质量门禁、多 AI 工具混用环境

---

### 🥉 shanraisshan/claude-code-best-practice — GitHub Trending #1

**定位**：69条 actionable tips，Claude Code 原作者 Boris Cherny 参与

**覆盖类别**：
```
Prompting · Planning · Context · Session · CLAUDE.md+rules
Agents · Commands · Skills · Hooks · Workflows · Advanced
Git/PR · Debugging · Utilities
```

**特色**：维护跨模型工作流目录（Claude Code + Codex 双终端方案等）

---

### MuhammadUsmanGM/claude-code-best-practices — 社区手册

- 可运行的 plugins 和 drop-in starter kits
- 已发布的公开 benchmarks
- 完整 `.claude/` 配置，直接 copy 可用
- 持续更新，覆盖最新版本

---

### 其他值得关注的 Repo

| Repo | 特色 | 适合场景 |
|------|------|----------|
| `garrytan/gstack` | CEO/Designer/PM 等角色分工编排 | 研究 Role-based Agent 协调 |
| `gsd-build/get-shit-done` | Discussion→Planning→Execution→Verify | 大型项目防 AI 漂移 |
| `shareAI-lab/learn-claude-code` | 从 0 构建 Agent harness 教程 | 理解底层架构 |
| `awesome-claude-code` | 生态索引：Skills/Hooks/Plugins 精选 | 快速摸清社区生态 |
| `awattar/claude-code-best-practices` | 10个专用 Agent + 自定义命令集 | 参考 Agent 设计模式 |
| `x1xhlol/system-prompts-and-models-of-ai-tools` | 收集各 AI 工具的系统提示词 | 研究 Prompt 设计对比 |

---

## 10. 社区讨论平台

| 平台 | 类型 | 说明 |
|------|------|------|
| **r/ClaudeCode** | Reddit | Claude Code 专属社区，最活跃 |
| **r/ClaudeAI** | Reddit | 更广泛的 Claude 话题，含工程技巧 |
| **r/ChatGPTCoding** | Reddit | 跨工具对比讨论 |
| **Anthropic Discord** | Discord | 官方社区，有 #claude-code 专属频道 |
| **YouTube - Boris Cherny** | YouTube | Claude Code 原作者深度讲解 |
| **MLOps Community** | YouTube | 实战视频，含进阶模式讲解 |
| **code.claude.com/docs** | 官方文档 | 官方最权威参考 |
| **SAP Community Blog** | 博客 | 企业级最佳实践案例 |
| **PubNub Blog** | 博客 | Subagent 实战配置指南 |

---

## 11. 选型决策矩阵

| 你的情况 | 推荐方案 |
|----------|----------|
| 个人日常开发，快速上手 | 官方文档 + shanraisshan repo |
| 想要强制 TDD + 工程纪律 | **Superpowers**（obra/superpowers） |
| 企业团队，需要安全扫描 + 多工具 | **ECC**（everything-claude-code） |
| 大项目，防止 AI 跑偏漂移 | **get-shit-done** |
| 学习 Agent 架构原理 | learn-claude-code（shareAI-lab） |
| 需要角色分工 Agent 团队 | gstack（garrytan） |
| 探索整个社区生态 | awesome-claude-code |
| 研究各工具系统提示词设计 | system-prompts-and-models-of-ai-tools |

---

## 12. 速查清单

### 项目初始化清单

```markdown
□ 运行 /init 生成基础 CLAUDE.md
□ 精简 CLAUDE.md（每行问：删掉会出错吗？）
□ 创建 .claudeignore（排除 node_modules、dist、logs 等）
□ 配置 .claude/settings.json（基础 hooks）
□ 为高频任务创建 Skills（.claude/skills/）
□ 为专项工作定义 Subagents（.claude/agents/）
□ 把关键规则转为 Hooks（不只写在 CLAUDE.md）
□ 运行 /hooks 验证 hook 配置
```

### 日常工作清单

```markdown
□ 新任务前：确认 context 是否需要 /clear
□ 大型调研：委派给 Subagent 保护主 context
□ 实施前：用 plan mode 先探索再规划
□ 实施中：提供明确的验证标准（测试/截图）
□ 纠错超 2 次：停下来，/clear 重写 prompt
□ 任务完成：git commit 作为 session 检查点
□ 长会话：定期 /compact，指定保留重点
□ 使用 /btw 查快速问题，不污染对话历史
```

### Token 节省清单

```markdown
□ CLAUDE.md 保持精简（<100行）
□ .claudeignore 排除无关目录
□ 用 Subagent 隔离大规模文件读取
□ 精确引用文件（@具体路径）而非描述位置
□ 任务间主动 /clear 不让无关 context 累积
□ 快速查询用 /btw 而非普通消息
□ 批量任务用非交互模式（-p）
□ 使用 CLI 工具（gh、aws-cli）而非 API 调用
```

---

## 参考资源

- [Claude Code 官方最佳实践](https://code.claude.com/docs/en/best-practices)
- [Claude Code 官方文档](https://code.claude.com/docs)
- [Superpowers Framework](https://github.com/obra/superpowers)
- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code)
- [shanraisshan/claude-code-best-practice](https://github.com/shanraisshan/claude-code-best-practice)
- [MuhammadUsmanGM/claude-code-best-practices](https://github.com/MuhammadUsmanGM/claude-code-best-practices)
- [Anthropic Engineering Blog - Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)

---

*本文档整合自 Anthropic 官方文档及 GitHub 社区实战经验，持续更新中。*
