# Hook Noise Reduction and Session Learning 设计文档

本文设计下一阶段 Claude Code hooks、statusLine 和 session learning 的治理方案。目标是减少启动上下文噪音、降低无效输出进入会话的风险，同时保留必要的项目状态提醒和可追溯学习记录。

本文是设计文档，不直接修改运行配置。后续实施应基于本文再写 implementation plan。

## 背景

当前 agent governance 已完成 metadata、共享池、模板分层和用户级 agent 瘦身。剩余主要噪音源从 agent 默认加载转向 hooks、statusLine、插件启用和长 prompt。

当前配置中存在几类自动执行入口：

- `SessionStart`：会话启动、恢复或 compact 后触发。其命令输出可能以 `systemMessage` 形式进入会话上下文。
- `statusLine`：用于 UI 状态展示。它通常不是主要 token 来源，但脚本复杂度高，会带来执行成本、延迟和终端噪音。
- 项目模板 hooks：包含 `PreToolUse`、`PostToolUse`、`SessionStart`，用于安全拦截、progress 提醒和工作状态摘要。
- 用户希望新增“关闭 session 前自动学习”，用于沉淀本轮工作经验。

官方 hooks 文档参考：

```text
https://code.claude.com/docs/en/hooks
```

## 目标

1. 降低 `SessionStart` 输出进入上下文的概率和体积。
2. 保持 agent loader 的有用性，但避免正常情况下反复输出 “already present”。
3. 降低 `statusLine` 的执行成本和维护复杂度，不让它成为误判 token 消耗的主因。
4. 新增 session learning 机制，但不在每轮停止时调用模型、不自动注入长记忆。
5. 保持模板可迁移，不写死本机绝对路径。

## 非目标

- 不在本阶段做 agent prompt 大规模瘦身。
- 不在本阶段添加 `tools`、`maxTurns`、`effort` 边界。
- 不在 hook 中自动调用 subagent 或 LLM 总结。
- 不让 session learning 自动改变项目代码、agent prompt 或 CLAUDE.md。
- 不依赖某个具体项目路径。

## Token 与体验影响判断

| 机制 | 是否可能影响 token | 主要风险 | 治理策略 |
|---|---|---|---|
| `SessionStart` hook | 是 | `systemMessage` 输出进入上下文，重复启动会累积噪音 | 默认静默，只在新增、缺失、异常、compact 后提醒 |
| `PreToolUse` / `PostToolUse` hook | 可能 | 拦截消息或警告进入当前回合 | 只在风险命中时输出，正常路径返回 `{}` |
| `statusLine` | 通常不是主要 token 来源 | 每轮执行脚本、读 transcript、调用 node/python，影响延迟和可维护性 | 默认轻量模式，重 HUD 设为可选 |
| `Stop` hook | 高风险 | 每轮 assistant 回复结束都触发，容易制造额外学习/总结循环 | 不用于自动学习 |
| `SessionEnd` hook | 低到中 | 退出时写本地记录，若输出过多也可能造成噪音 | 只写本地文件，stdout 返回 `{}` 或短提示 |

## 推荐方案

采用 “静默优先 + 本地学习 + 手动加载” 的方案。

### 1. SessionStart 降噪

`agent-loader.sh` 调整为：

- 无 `.enabled` 时输出 `{}`。
- `.enabled` 中 agent 已全部存在时输出 `{}`。
- 只有以下情况输出短 `systemMessage`：
  - 成功复制了新 agent。
  - 存在 `.enabled` 中声明但共享池和项目本地都找不到的 agent。
  - 共享池目录不存在。

项目模板的 `SessionStart` 工作状态摘要调整为：

- 正常情况输出 `{}`。
- 只在以下情况输出短提醒：
  - `progress.md` 行数超过阈值。
  - 当前分支异常，例如 detached HEAD。
  - git ahead/behind 状态超过配置阈值。
  - `gh issue list` 或必要命令失败。
  - compact 后需要显示极短 reminder。

### 2. statusLine 轻量化

保留 statusLine，但引入模式切换：

```text
CLAUDE_STATUSLINE_MODE=light
CLAUDE_STATUSLINE_MODE=hud
```

建议默认 `light`：

- 显示 cwd、branch、dirty counts、简短 token/usage 信息。
- 不读 transcript 最近 300 行。
- 不调用重型 HUD 插件链路。
- 不调用多进程 node + python 管道。

`hud` 模式保留现有信息密度，用于需要强状态可视化的项目。

### 3. SessionEnd 本地学习

新增 `SessionEnd` hook，而不是 `Stop` hook。

设计原则：

- 不调用 LLM。
- 不调用 agent。
- 不向上下文注入长内容。
- 不修改项目业务文件。
- 只在本地 `.claude/session-memory/` 写短记录。
- `.claude/session-memory/` 必须加入 ignore，不进入 git tracking。
- 脚本必须保持 1 秒级完成；不要跑网络命令、不要做深度 git 扫描、不要读取大段 transcript。

建议输出文件：

```text
<project>/.claude/session-memory/YYYY-MM-DD-session.md
<project>/.claude/session-memory/latest.md
```

建议记录内容：

- 时间。
- 退出原因。
- cwd。
- git branch。
- git dirty summary。
- last commit。
- progress 文件路径、行数、最后修改时间。
- 可选：最近 session transcript 的短摘要元数据，但不复制大段对话。

给 AI 后续读取时，不自动全文加载，只由 `SessionStart` 输出一句短提示：

```text
Session memory updated: .claude/session-memory/latest.md
```

如果该提示仍被认为增加上下文噪音，可以改为完全静默。

## 建议文件结构

后续实现建议涉及以下文件：

| 文件 | 责任 |
|---|---|
| `scripts/agent-loader.sh` | 减少正常路径输出，只报告新增、缺失和异常 |
| `scripts/statusline-light.sh` | 新增轻量 statusLine，可选替代现有 HUD wrapper |
| `scripts/session-end-learn.sh` | SessionEnd 本地学习记录，不调用模型 |
| `settings.json` | 用户级 hook/statusLine 配置 |
| `templates/new-project/.claude/settings.json` | 新项目模板 hook 配置 |
| `templates/new-project/docs/superpowers/specs/<this-doc>` | 设计记录 |

## Hook 行为草案

### agent-loader 输出规则

```text
no .enabled                         -> no stdout, exit 0
all enabled agents already present  -> no stdout, exit 0
new agents copied                   -> {"systemMessage":"Agent loader: +N new"}
missing agents                      -> {"systemMessage":"Agent loader: N missing: ..."}
pool missing                        -> {"systemMessage":"Agent pool not found"}
```

说明：正常路径优先完全静默。如果某个 hook runner 必须读取 JSON，才返回 `{}`；不要把 `{}` 当作必须打印的成功消息。

### SessionEnd 学习命令草案

给 AI 实施时使用英文任务描述：

```text
Create a SessionEnd hook script that writes a short local session memory file.
Do not call an LLM.
Do not modify project source files.
Return no stdout on success, or {} only if the hook runner requires JSON.
Finish in about one second; do not run network commands, deep git scans, or transcript-body reads.
Record only timestamp, reason, cwd, branch, git dirty summary, last commit, and progress file metadata.
```

### statusLine 轻量模式草案

```text
If CLAUDE_STATUSLINE_MODE is unset or "light", run the lightweight statusline.
If CLAUDE_STATUSLINE_MODE is "hud", run the existing HUD wrapper.
If required commands are missing, return a short fallback line and exit 0.
```

## 风险与缓解

| 风险 | 说明 | 缓解 |
|---|---|---|
| SessionEnd 记录泄露敏感内容 | 如果复制 transcript 片段，可能写入密钥或私密对话 | 不复制正文，只记录元数据 |
| 自动学习变成 token 消耗源 | Stop hook 或 LLM 总结会每轮触发 | 使用 SessionEnd，本地写文件，不调用模型 |
| statusLine 过度简化 | 用户失去活跃 agent 或 token 状态感知 | 保留 `hud` 模式开关 |
| SessionStart 太静默 | 重要 warning 被漏看 | 只对异常输出短提醒 |
| 脚本跨平台失败 | Windows Git Bash、PowerShell、路径差异 | 脚本使用 POSIX shell 基础命令；必要时用 PowerShell 版本补充 |

## 验证计划

静态验证：

```powershell
git diff --check -- scripts settings.json templates/new-project/.claude/settings.json
```

agent-loader 验证：

```text
Run agent-loader with no .enabled and expect {}
Run agent-loader with all agents present and expect {}
Run agent-loader with one missing pool agent and expect a short missing warning
Run agent-loader with one new shared agent and expect +1 new
```

SessionEnd 验证：

```text
Run session-end script with sample hook JSON.
Expect .claude/session-memory/latest.md to be written.
Expect stdout to be empty, or {} only when JSON output is explicitly required.
Expect runtime to stay around one second.
Verify no transcript body or secret-looking values are copied.
```

statusLine 验证：

```text
Run statusline in light mode with sample JSON input.
Expect one short line and exit 0.
Run statusline in hud mode when HUD plugin exists.
Expect existing behavior.
Run statusline when HUD plugin is missing.
Expect fallback line and exit 0.
```

运行时验证：

```text
Start a new session in a project with no .enabled.
Confirm no noisy SessionStart message.
Start a new session in a project with all enabled agents already present.
Confirm no "already present" message.
End a session and confirm local session memory is updated.
Confirm session memory is not automatically injected into the next prompt.
```

## 分阶段实施建议

### Phase 1: 低风险降噪

1. 修改 `agent-loader.sh`，正常路径静默。
2. 更新用户级和模板设计文档。
3. 验证 `.enabled` 场景。
4. 提交。

### Phase 2: SessionEnd 本地学习

1. 新增 `session-end-learn.sh`。
2. 把 `.claude/session-memory/` 加入用户级和模板 ignore 规则。
3. 在用户级 `settings.json` 加 `SessionEnd`。
4. 在模板 `settings.json` 加可移植版本。
5. 用 sample JSON 验证输出、文件内容和 1 秒级运行时间。
6. 提交。

### Phase 3: statusLine 轻量模式

1. 新增 `statusline-light.sh`。
2. 保留现有 HUD wrapper 作为 `hud` 模式。
3. 增加模式开关。
4. 验证 light/hud/fallback。
5. 提交。

## 开放问题

1. `latest.md` 是否要被 `SessionStart` 提示？
   - 建议：初期不提示，避免新噪音；只在用户手动查看。
2. statusLine 是否马上替换？
   - 建议：先做 agent-loader 和 SessionEnd，再做 statusLine，避免一次改动过多。

## 推荐结论

优先顺序：

1. 先做 `SessionStart` 降噪，尤其是 `agent-loader.sh` 正常路径静默。
2. 再做 `SessionEnd` 本地学习，避免使用 `Stop`。
3. 最后再做 statusLine 轻量模式。

这样可以先减少最可能进入上下文的噪音，再补本地学习能力，最后处理主要影响体验和性能的状态栏脚本。

## 实施状态

当前已推进：

- Phase 1：`agent-loader.sh` 正常路径静默。
- Phase 2：新增 `SessionEnd` 本地学习脚本，并在用户级和 new-project template 配置中接入。
- Phase 2：`.claude/session-memory/` 已加入 ignore 规则，避免本地学习记录进入 git tracking。
- Template portability：new-project template 已新增项目内 `scripts/agent-loader.sh`，模板 `SessionStart` 不再依赖用户级 loader 脚本路径。

当前暂缓：

- Phase 3：statusLine 轻量模式尚未实施。现有 statusLine 脚本耦合 HUD、node、python 和 transcript 读取，建议单独提交，避免把 UI 状态栏改动混入 hook 降噪提交。

已验证：

```text
agent-loader: no .enabled -> no stdout, exit 0
agent-loader: all enabled agents already present -> no stdout, exit 0
agent-loader: one new shared agent -> short +1 new systemMessage
agent-loader: one missing agent -> short missing systemMessage
session-end-learn: writes .claude/session-memory/latest.md
session-end-learn: stdout empty
session-end-learn: runtime around one second in local sample runs
settings.json: valid JSON
templates/new-project/.claude/settings.json: valid JSON
```
