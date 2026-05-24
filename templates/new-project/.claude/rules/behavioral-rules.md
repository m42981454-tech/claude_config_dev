# Behavioral Rules — DON'T 清单 + karpathy 4 原则

> **Owner**: 主 `CLAUDE.md` §9（DON'T）+ §5（Engineering rules）
> **何时 load**：每次 commit / 写代码 / Reviewer 看 PR / 用户说 "按 4 原则做" 时

---

## 8.1 通用行为（本文件 source of truth）

- ❌ 不删除既有测试或用 `@pytest.mark.skip` / `test.skip` 绕过失败
- ❌ 主线 PM 角色（决策 / 编排）不直接做编码工作——派给 Implementer subagent
- ❌ Tester subagent 不修代码，只报 bug 给 PM；修代码必须经 Implementer + Reviewer
- ❌ 不在 UI / API 变更后留下持续刷新的 console error 循环
- ❌ 不在修复聚焦问题时顺手做大范围重构（per `engineering.md` §3 Surgical Changes）

## 8.2 Git Workflow DON'T 摘要

> 完整规约见 [`git-workflow.md`](git-workflow.md) §7.2-§7.3 + §7.7

- ❌ 不绕过 hooks（`--no-verify` / `--no-gpg-sign` / `commit.gpgsign=false`）— 详 §7.2
- ❌ 不直接 commit 到主线（[MAIN_BRANCH]）— 详 §7.2
- ❌ 不代替人工 merge 到主线（[MAIN_BRANCH]）— H1 hook 拦截，详 §7.3
- ❌ 不 push 远端（除非用户明确要求）— 详 §7.2
- ❌ sprint merge 前必更新 progress.md 作为 sprint 分支最后一个 commit — 详 §7.7

> 项目专项 DON'T 项写在主 `CLAUDE.md §9` 或单独 rules 文件，不放本通用文件。
