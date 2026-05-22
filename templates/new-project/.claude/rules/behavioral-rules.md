# Behavioral Rules — DON'T 清单 + karpathy 4 原则

> **Owner**: 主 `CLAUDE.md` §9（DON'T）+ §5（Engineering rules）
> **何时 load**：每次 commit / 写代码 / Reviewer 看 PR / 用户说 "按 4 原则做" 时

---

## 8. 不要做（DON'T）

- ❌ 不删除既有测试或用 `@pytest.mark.skip` / `test.skip` 绕过失败
- ❌ 不绕过 hooks（`--no-verify` / `--no-gpg-sign` / `commit.gpgsign=false`）
- ❌ 不在主线 Opus（PM）上做编码工作——派给 Sonnet Implementer
- ❌ Tester 不修代码，只报 bug 给 PM；修代码必须经 Implementer + Review
- ❌ **不直接 commit 到主线（[MAIN_BRANCH]）**——所有改动必须先开子分支，详见 [.claude/rules/git-workflow.md §7.2](git-workflow.md#72-强制规则不直接-commit-到主线)
- ❌ **sprint merge 后不更新 PROGRESS.md 就开始下个 sprint**——必须紧接着走 chore 分支同步 PROGRESS.md，详见 [.claude/rules/git-workflow.md §7.7](git-workflow.md#77-progressmd-维护规约强制)
- ❌ 不在 UI / API 变更后留下持续刷新的 console error 循环
- ❌ 不在修复聚焦问题时顺手做大范围重构（per §10 surgical changes）
- ❌ 不 push 远端（除非用户明确要求）

> 项目专项 DON'T 项写在主 `CLAUDE.md §9` 或单独 rules 文件，不放本通用文件。
