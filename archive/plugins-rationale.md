# Plugin 选型与维护说明（详细版）

> 从 `~/.claude/rules/plugins.md` 拆出，按需查阅，不再常驻加载。
> 精简版清单见 `~/.claude/rules/plugins.md`。

## 选型原则

1. **按需安装，避免全家桶** — 业界共识（调研报告 §3.2），每个 plugin 都消耗 token（参考 `wshobson/agents`：1 个 plugin 装载 ≈ 1000 tokens）
2. **优先纪律性 > 工具性** — 纪律性 plugin（superpowers）让你做对的事，工具性 plugin（context7）让事做得快
3. **官方 `@claude-plugins-official` 优先** — Anthropic 维护，稳定性高
4. **检查 trigger 条件** — 装了但 CLAUDE.md 不触发 = 浪费 context

## 已知边界 / 冲突

- `superpowers` 与 `andrej-karpathy-skills` 在"工程原则"上有重叠（4 原则 vs systematic-debugging），由项目 CLAUDE.md 仲裁优先级
- `plugin-dev` 的 skill 在非 plugin 项目里基本不会 trigger，加载本身仍占 context（实测 ~1,566 tok，已禁用）
- 没有 plugin 应该改写 user CLAUDE.md 或 `~/.claude/settings.json`——若发生立即卸载

## 常用操作

```bash
# 列出当前装的 plugin
/plugin
claude plugin list

# 查看单个 plugin 的组件清单与 token 开销
claude plugin details <name>

# 禁用 / 启用（比卸载更安全，可随时恢复）
claude plugin disable <name>
claude plugin enable <name>

# 卸载
/plugin uninstall <name>@<marketplace>

# reload（无需重启 session）
/reload-plugins
```

实际配置见 `~/.claude/plugins/installed_plugins.json`。

## Token 实测记录（2026-06-21，`claude plugin details` 结果）

| Plugin | 状态 | Always-on token |
|---|---|---:|
| superpowers | 启用 | ~482 |
| claude-md-management | 启用 | ~121 |
| frontend-design | 启用 | ~54 |
| session-report | 启用 | ~48 |
| context7 | 启用 | ~0 |
| claude-hud | 启用 | ~0 |
| skill-creator | 禁用 | 0（启用后 75） |
| andrej-karpathy-skills | 禁用 | 0（启用后 64） |
| plugin-dev | 禁用 | 0（启用后 1,566） |
| github | 禁用 | 0 |
