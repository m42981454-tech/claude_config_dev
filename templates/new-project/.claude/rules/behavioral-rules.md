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

---

<!-- ## 10. Engineering rules — Always invoke `karpathy-guidelines` skill

**强制 trigger 时机**（来源:`~/.claude/skills/karpathy-guidelines/SKILL.md`,2026-05-18 加入）:

- Writing new code（包括 small features / 小 utility / fixture / helper）
- Reviewing diff / PR
- Refactoring（any size,即使 1 行重命名也要过一遍 4 原则）
- 用户说 "按 4 原则做" / "用 karpathy" / "follow karpathy guidelines"

**4 原则速查**(详 skill 全文):

| # | 原则 | 关键行为 |
|---|---|---|
| 1 | **Think Before Coding** | 明示假设;不确定就问;多种解读时列出别独断;简单方案优先;push back when warranted |
| 2 | **Simplicity First** | 最小代码;不加未请求的 abstraction / 配置 / 错误处理;不为"将来可能用"加灵活性 |
| 3 | **Surgical Changes** | 不动无关代码;不删不懂的注释;不"顺手"重构(即使看到丑代码,任务外不动) |
| 4 | **Goal-Driven Execution** | 任务前定可验证完成标准(具体命令 / 期望输出);完成后真跑命令验证,evidence before assertions |

**与 §2 团队编排的关系**:karpathy-guidelines 是 PM / Implementer / Reviewer / Tester 等**所有角色**共同行为基础。每个 sprint 派单稿默认隐含遵循 4 原则。**不冲突** — 4 原则与 §2 设计契合度 + 测试覆盖等 review 标准互补。

**与 user-level CLAUDE.md 关系**:user-level 加了一份 cross-project 备忘;本节是项目级强制版(更明确 trigger 条件 + 派单融入)。 -->
