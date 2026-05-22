# Plugin 用途清单（user-level）

> 由 user-level `~/.claude/CLAUDE.md` 通过 `@import` 引用。
> 更新日期：2026-05-20（B1 调研落地）

## Tier 分级

| Plugin | Tier | 触发场景 | 备注 |
|---|---|---|---|
| `superpowers@claude-plugins-official` | **必装** | 任何编码会话 | 14 skill 覆盖 TDD / verification / brainstorming / writing-plans / git-worktrees |
| `claude-md-management@claude-plugins-official` | **必装** | 改 CLAUDE.md / `.claude/rules/*.md` | 帮助维护 ≤200 行 adherence 约束 |
| `skill-creator@claude-plugins-official` | 可选 | 写自定义 skill 时 | 不写 skill 时无 context 开销 |
| `frontend-design@claude-plugins-official` | 可选 | 前端项目（Next.js / React） | 只在前端目录工作时显著加载 |
| `context7@claude-plugins-official` | 可选 | 查最新第三方 lib 文档 | token 消耗较大，按需触发 |
| `andrej-karpathy-skills@karpathy-skills` | 可选 | 强制 Karpathy 4 原则时 | 需在项目 CLAUDE.md 显式 trigger，否则不生效 |
| `plugin-dev@claude-plugins-official` | 慎装 | 仅在开发 Claude Code plugin 时 | 平时可移除以省 context |

## 选型原则

1. **按需安装，避免全家桶** — 业界共识（调研报告 §3.2），每个 plugin 都消耗 token（参考 `wshobson/agents`：1 个 plugin 装载 ≈ 1000 tokens）
2. **优先纪律性 > 工具性** — 纪律性 plugin（superpowers）让你做对的事，工具性 plugin（context7）让事做得快
3. **官方 `@claude-plugins-official` 优先** — Anthropic 维护，稳定性高
4. **检查 trigger 条件** — 装了但 CLAUDE.md 不触发 = 浪费 context

## 已知边界 / 冲突

- `superpowers` 与 `andrej-karpathy-skills` 在"工程原则"上有重叠（4 原则 vs systematic-debugging），由项目 CLAUDE.md 仲裁优先级
- `plugin-dev` 的 skill 在非 plugin 项目里基本不会 trigger，加载本身仍占 context
- 没有 plugin 应该改写 user CLAUDE.md 或 `~/.claude/settings.json`——若发生立即卸载

## 常用操作

```bash
# 列出当前装的 plugin
/plugin

# 卸载
/plugin uninstall <name>@<marketplace>

# 装回
/plugin install <name>@<marketplace>

# reload（无需重启 session）
/reload-plugins
```

实际配置见 `~/.claude/plugins/installed_plugins.json`。
