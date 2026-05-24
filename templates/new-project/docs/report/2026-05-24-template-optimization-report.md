# `new-project` 模板优化完整报告

> **Date**: 2026-05-23 ~ 2026-05-24
> **Branch**: `feature/dev.template-optim` (10 commits, 待人工 merge 入 `feature/dev`)
> **Status**: SHIP-READY（本地全 verify 项 ✅；4 项外部依赖 by-design 可接受）
> **Design doc**: `templates/new-project/docs/superpowers/specs/2026-05-23-template-optimization-design.md`

---

## 0. TL;DR

对 `C:\Users\dev002\.claude\templates\new-project\` 做了 5 轮 review + 实施：

1. **初始深度评价** 发现 15 项问题（C/E 部分）
2. **Phase 1-5** 分阶段实施 + 多轮 reviewer rework
3. **端到端 dry-run** 验证：模板源（`--force`）和模拟新项目都拿到 exit 0
4. **10 个 logical commit** 切片入子分支
5. **未 verify 4 项** 全部为依赖外部环境（Claude Code 行为 / git 客户端配置），by-design 可接受

**核心成果**：模板从"装载即 8 agent 永远 active + Windows 首跑 crash + validate 永远红 + 多处文档矛盾"→ "按需启用 + 跨平台稳定 + validate 全绿 + 单一真源"。

---

## 1. 时间线

| 时间 | 动作 | 输出 |
|---|---|---|
| 第 1 步 | 完整 review 模板（10 文件全读）| 15 项问题清单 + E 改进建议 |
| 第 2 步 | 用户决策不丢精度、长期维护 | 设计原则定案 |
| Phase 1 | T1（撤销）/T2/T3/T4/T5 并行 5 agent | stack cd 修 / validate 工具 / hook 跨平台 |
| Phase 2 | T6 同步 init 双轨 + PROGRESS_PATH 简化 | settings.json + init.sh + init.md 一致 |
| Phase 3 | §1 .claudeignore 扩展 + §2 T7 去重 rules + #11 agent _available + #13 死链 | docs 历史保留 + 单一真源 |
| Phase 4 | Reviewer rework 4 项（blocker + 关键 suggestion）| settings.json _comment 修 / spec README banner / pwsh 兼容 |
| Phase 5 | Adversarial review 找新坑 + 修 8 项（C1+C2+H3+H4+H5+M6+M8+L10）| 改 file pattern / 跨文件术语中性化 / `--force` flag |
| Dry-run | 端到端 init + validate 在临时项目跑 | 5 真 bug 暴露（CRLF / hook 检测 / 占位符变量 / stackdump / _available 断言）|
| Bug fix | Bug 1+2+3a+4 修复（session limit 中断 → 重启后确认完成）| .gitattributes / CRLF strip / file pattern path 兼容 / I18N+TASK_QUEUE+REPO_OWNER 变量 |
| Final review | 端到端 dry-run 二次确认 | exit 0 全绿 |
| Commit | 10 logical commits 入 feature/dev.template-optim | working tree clean |

---

## 2. 5 轮 Review 发现度

| 轮次 | 发现总数 | 已修 | 不做（用户决策保留）| 转 followup |
|---|---|---|---|---|
| 初始 review C/E | 15 | 12 | 3（梯度模板 / AI merge 政策 / progress codeblock）| 0 |
| Code-review rework | 10（1 blocker + 9 sug） | 4（1 blocker + 3 关键 sug）| 1（postmortems 死链 reviewer 误判）| 5 nit |
| Adversarial review | 10（2 Critical + 3 High + 3 Med + 2 Low）| 8 | 0 | 2（validate scope / commit 切片）|
| Dry-run | 5 真 bug + 1 假设 | 4 | 0 | 1（_available 不递归无法本地验证）|

**修复闭环度**：28 / 40 真问题被修（70%），其余明确转 followup 或用户决策保留。

---

## 3. 32 项 Git 路径改动汇总

### 新增（6 个）
- `templates/new-project/.gitattributes`
- `templates/new-project/.claude/agents/README.md`
- `templates/new-project/.claude/scripts/validate.sh`
- `templates/new-project/.claude/scripts/validate.ps1`
- `templates/new-project/docs/superpowers/specs/README.md`
- `templates/new-project/docs/superpowers/specs/2026-05-23-template-optimization-design.md`

### 修改（18 个）
- `.claudeignore` / `.gitignore` / `CLAUDE.md` / `SETUP.md` / `init.sh` / `project.env`
- `.claude/settings.json` / `.claude/scripts/agent-loader.sh`
- `.claude/agents/.enabled.example`
- `.claude/commands/project/init.md`
- `.claude/rules/{behavioral-rules,docs-conventions,progress-conventions,stack-backend,stack-frontend,team-orchestration}.md`
- `.githooks/install.sh` / `.githooks/pre-commit`

### Rename（8 个 git 跟踪）
- `.claude/agents/<8 个 .md>` → `.claude/agents/_available/<8 个 .md>`

### 已删（2 个）
- `templates/new-project/bash.exe.stackdump`（Git Bash 崩溃产物）
- `templates/new-project/.claude/agents/<8 个 .md>`（→ rename 到 _available/）

---

## 4. 10 个 Commit 切片（feature/dev.template-optim）

```
1fa8b6c chore(template): 加 .gitattributes 强制 LF + 清 CRLF + 加固 hooks (Bug 1+4)
69338df fix(template):   T2 修 stack-*.md path-scoped cd bug
fab8810 feat(template):  settings.json hook 健壮性 + PROGRESS_PATH 简化 (T5+T6+H4)
cd476ce feat(template):  validate.sh / .ps1 + SETUP Step 6 (T4+H3+M8+Bug 2)
358967a refactor(template): T6 同步 init 双轨 + 补 I18N/TASK_QUEUE/REPO_OWNER (Bug 3a)
23b2205 refactor(template): T7 去重 rules + 术语中性化 + #13 死链 polish
5866ec3 refactor(template): #11 agent 移 _available/ 子目录默认 disabled
c5ec8cb feat(template):  .claudeignore 扩展 + docs/superpowers/specs/README banner
b7c4c78 docs(template):  CLAUDE.md §4 加 _available/ 说明 (L10)
6d14342 docs(template):  2026-05-23 模板优化 design doc
```

每个 commit 独立 buildable + 可 bisect + message 写 why。

---

## 5. 验证结果

### 5.1 本地 verify ✅

| 检查 | 方法 | 结果 |
|---|---|---|
| 端到端 init 流程 | `mktemp -d` 临时项目跑完整初始化 | exit 0 全绿 |
| validate.sh 模板源 + `--force` | dry-run | 0 errors / 2 警告（预期占位符 + 遗留产物） |
| `git-workflow.md` 全文未动 | git diff | 0 行 |
| settings.json JSON 合法 | python json.load | VALID |
| Opus/Sonnet 跨 rules 残留 | grep -i | 仅 team-orchestration.md §2.7 配置示例保留（设计意图）|
| Rules 内部 link | validate.sh | ✅ 全部有效 |
| Hook 拦截主线 commit | dry-run on main | ✅ 拦截 |
| 子分支 commit 通过 | dry-run on dev-test | ✅ 通过 |

### 5.2 未 verify（依赖外部环境）⚠️

| 项 | 为什么没 verify | 风险 |
|---|---|---|
| Claude Code 真的不递归 `_available/` 子目录吗？ | 依赖 Claude Code 内部 agent 注册逻辑 | 🟡 中（若假设错，8 agent 仍 active；模板可用性不受影响） |
| `.claudeignore` 是 Claude Code 真支持的吗？ | 官方文档无明文记载 | 🟡 中（若不支持，模板演化 spec 会污染新项目 context） |
| `.gitattributes` LF 在用户 clone 时真生效吗？ | 依赖 user 端 git 版本和配置 | 🟢 低（git 1.7+ 默认支持） |
| 真 Claude Code session 跑 hooks 与预期一致吗？ | 需要 init 后的新项目里启动真 session | 🟢 低（hook 命令逻辑已验证） |

---

## 6. 用户硬约束达成

| 约束 | 达成 |
|---|---|
| (a) 不丢精度 — 所有经验沉淀必须保留 | ✅ 所有删除动作撤销；agent 移 _available 而非删除；规约信息密度无损（link 到 source of truth） |
| (b) 长期维护 — 模板演化履历是资产 | ✅ docs/superpowers/specs/ 历史保留；新增本次 design doc 沉淀 |
| (c) 不动用户经验沉淀的设计选择 | ✅ AI merge 禁令 / 双层主线保护 / PROGRESS codeblock 全未动 |

---

## 7. 不做项（明确 followup 或用户决策保留）

| # | 项 | 决策 |
|---|---|---|
| E5 | 三档梯度模板（minimal/standard/full）| ❌ 用户硬约束"不丢精度"，不做 |
| E9 | AI merge "用户预授权"机制 | ❌ 用户经验沉淀的双层主线保护，不动 |
| E10 | 删 init.sh 仅保留 /project:init | ❌ 保兼容（无 Claude Code 环境用户的入口）|
| E12 | progress.md codeblock → frontmatter | ❌ 兼容性风险，不动 |
| 死链 #3 | postmortems 死链（reviewer 误判）| ❌ 文件实际存在，validate 不报 |
| Adv M7 | validate scope 扩展到 CLAUDE.md / docs/ | ⏸ 转 followup |
| Adv L9 | commit 切片粒度调整 | ✅ 在本次 commit 时已落实 10 个 |
| Dry-run #5 | _available 不递归本地验证脚本 | ⏸ 行为依赖外部，无法本地 verify |

---

## 8. 下一步（人工操作）

按项目级 `git-workflow.md §7.2` / settings.json H1 hook —— **AI 不替人 merge 主线**。请人工执行：

```bash
git checkout feature/dev
git merge --no-ff feature/dev.template-optim -m "Merge template-optim: 模板系统化优化 (Phase 1-5 + reviewer rework + bug fix)"
git branch -d feature/dev.template-optim
# 不 push（除非明示）
```

merge 前可选最后一道核验：

```bash
git diff feature/dev..feature/dev.template-optim --stat    # 总览
git log feature/dev..feature/dev.template-optim --oneline  # 10 commit
```

---

## 9. 教训沉淀（给 6 个月后回看的自己）

1. **"清理"动作要慎判性质** —— T1 第一次把模板演化 spec / 别项目备份当"污染"删，被用户纠正"长期维护项目的演化履历是资产"。后续 Phase 2 改用 .claudeignore 排除是更好的方案。
2. **brainstorming HARD-GATE 不可绕** —— 几次未先设计直接派 agent 都被用户截停。每次大改前 design doc 落地、用户拍板再动是稳态。
3. **adversarial reviewer 远比 confirmatory reviewer 有用** —— Phase 5 adversarial review 找出 2 个真 Critical（! 反向规则失效、跨文件术语 drift），前两轮 reviewer 都没看到。
4. **端到端 dry-run 不能省** —— 一切单元验证全过的情况下，dry-run 仍然暴露 5 真 bug（CRLF / hook 检测路径不一致 / 缺变量 / stackdump 残留）。
5. **session limit 不可控** —— 一次中断后状态恢复成本高。重要 commit 应即时进入子分支，不要积累过多 dirty 改动。

---

## Sources / 参考

- 本次会话完整对话历史
- `templates/new-project/docs/superpowers/specs/2026-05-23-template-optimization-design.md`
- 10 个 commit message
- 5 个 subagent review 报告（agentId 见 conversation history）
