# Plugin 用途清单（user-level）

> 由 user-level `~/.claude/CLAUDE.md` 通过 `@import` 引用。
> 详细选型原则/已知边界/常用操作见 `~/.claude/archive/plugins-rationale.md`（按需查阅，不常驻）。
> 更新日期：2026-06-21

| Plugin | Tier | 触发场景 |
|---|---|---|
| `superpowers` | 必装 | 任何编码会话 |
| `claude-md-management` | 必装 | 改 CLAUDE.md / rules |
| `frontend-design` | 可选 | 前端项目（Next.js / React） |
| `context7` | 可选 | 查最新第三方 lib 文档 |
| `claude-hud` | 可选 | statusline 展示 |
| `session-report` | 可选 | 生成 session 用量报表 |
| `skill-creator` | 慎装（当前禁用） | 写自定义 skill 时再 enable |
| `andrej-karpathy-skills` | 慎装（当前禁用） | 强制 Karpathy 4 原则时再 enable |
| `plugin-dev` | 慎装（当前禁用） | 仅开发 Claude Code plugin 时 enable，token 开销最大 |
| `github` | 慎装（当前禁用） | 需要 gh Issue/PR 自动化时再 enable |
