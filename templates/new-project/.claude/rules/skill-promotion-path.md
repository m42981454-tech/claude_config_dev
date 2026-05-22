# Skill 晋升路径(Skill Promotion Path)

> **Refs**: [#23](https://github.com/m42981454-tech/doc/issues/23) follow-up — retrospective evaluation §3 差距 2 "缺 promotion path"
> **加载**: 每会话(无 `paths:` frontmatter)
> **目的**: 规范化"项目级 skill → user-level skill → plugin"三阶段晋升,实现真通配工程

---

## 0. 三阶段晋升

```
项目级 .claude/skills/my-*/
  ↓ (满足 user-level promotion 条件)
user-level ~/.claude/skills/my-*/
  ↓ (满足 plugin 条件)
plugin ~/.claude/plugins/<toolkit>/skills/
```

每阶段去除越多 project-specific 内容,通配性越强。

---

## 1. 项目级 → user-level 晋升

### 触发条件(任一满足即可考虑)

| 条件 | 说明 |
|---|---|
| **跨项目用 ≥ 2 次** | 同样的 skill 在另一项目想复用,只需改 ~30% 内容 |
| **去 hardcoded 后可用** | 把 `m42981454-tech/doc` / `feature/dev` / 路径等替换成通用变量(`{{REPO}}` / `{{MAIN_BRANCH}}` / `{{PROGRESS_PATH}}`)后,skill 100% 可用 |
| **设计 pattern 价值高** | 即使内容项目专属,设计模式(如 Issue-First gate / PROGRESS 三件套)有跨项目参考价值 |

### 反指标(不要晋升)

- ❌ skill 包含项目领域知识(如 `request_logs` schema / Kong 配置 / 项目 ADR 编号)
- ❌ skill 调用项目级 agent / sub-rule(如调用 `.claude/rules/team-orchestration.md` 的 §2.5 决策表)
- ❌ skill description 含项目特定关键字(如 "P0-1" / "WinClaw")

### 晋升步骤

1. **fork to user-level**:`cp .claude/skills/my-X/ ~/.claude/skills/my-X/`
2. **去 hardcoded**:
   - repo name → `{{REPO}}` 或 inline 注释 "替换为目标 repo"
   - branch name → `{{MAIN_BRANCH}}` 或 "替换为你的主线分支"
   - 路径 → `{{PROGRESS_PATH}}` / `{{CLAUDE_RULES_PATH}}`
3. **简化关联**:删除引用项目级 sub-rule / agent 的 link,改写为通用描述
4. **保留 project version**:项目级 `.claude/skills/my-X/` **不删**,保留作项目特定版本
5. **验证**:在另一项目跑 1 次 user-level skill,确认 work

### 现状(2026-05-20)

| 项目级 skill | 状态 | 可晋升? |
|---|---|---|
| `my-start-sprint` | hardcoded(repo / branch / Issue-First 路径) | ⏳ 需 hardcoded 抽变量 |
| `my-dispatch-sprint` | hardcoded(项目级 §2.5 决策表 + 13 agent 模板) | ❌ 项目领域知识深;暂留项目级 |
| `my-pm-progress-sync` | hardcoded(PROGRESS 路径 + §7.7 引用) | ⏳ 抽变量后可晋升 |
| `my-start-container` | hardcoded(§7.8 5 条件) | ❌ 项目"滚动容器"概念专属;暂留 |
| `my-issue-first-gate` | hardcoded(repo + body template 项目专属) | ⏳ 抽 repo / body template 后可晋升 |
| `my-postmortem` | ✅ **已晋升 user-level**(2026-05-20)— `~/.claude/skills/my-postmortem/` generic 化(README 路径改 fallback);项目级仍保留作 override | — |
| `my-gh-issue-create` (user-level) | ✅ 已 user-level(label 命名跨 repo 不一致教训已 update) | — |

---

## 2. user-level → plugin 晋升

### 触发条件(任一满足即可考虑)

| 条件 | 说明 |
|---|---|
| **想分享给团队 / 社区** | 不只个人用,有公开价值 |
| **跨 ≥ 3 项目稳定使用** | 已验证 user-level skill 真通用 |
| **可独立成完整 toolkit** | 单 skill 太散;5+ 个相关 skill 才值得 plugin 化 |

### 反指标(不要 plugin)

- ❌ 还在频繁迭代(plugin schema 改动有版本管理负担)
- ❌ 含 secrets / 私有 API endpoint(plugin 公开后泄露)
- ❌ 依赖项目特定 agent / hook(plugin 需要 self-contained)

### 晋升步骤

1. **建 plugin 目录**:`~/.claude/plugins/<toolkit>/`(本地 marketplace)
2. **写 plugin.json**:含 `name` / `version` / `skills` / `hooks` / `agents` 元信息
3. **bundle 资源**:把 user-level skill / hook / agent 复制进 plugin 目录
4. **加 namespace**:`/<toolkit>:<skill>` 防命名冲突(如 `/itc-jin:sprint:start`)
5. **验证**:`claude` restart + plugin 自动 register;test invoke 各 skill / command
6. **发布**:GitHub repo or npm(若公开)

### 现状(2026-05-20)

无 plugin。**Phase 3** 等本项目跑稳 2-3 sprint 后启动(per `2026-05-19_decision_extension-architecture.md §5`)。

---

## 3. 通配工程 — 变量注入模式(template 化)

### 推荐 placeholder 变量(per cookiecutter / jinja2 风格)

| 变量 | 含义 | 示例 |
|---|---|---|
| `{{REPO}}` | GitHub repo `<owner>/<repo>` | `m42981454-tech/doc` |
| `{{MAIN_BRANCH}}` | 主线分支名 | `feature/dev` / `main` |
| `{{PROGRESS_PATH}}` | PROGRESS.md 相对路径 | `20260403/plan1a-kong/PROGRESS.md` |
| `{{CLAUDE_RULES_PATH}}` | `.claude/rules/` 相对路径 | `.claude/rules/` |
| `{{ISSUE_LABEL_FEATURE}}` | "feature" label 在 repo 的实际命名 | `enhancement` (本 repo) / `feature` (其他 repo) |
| `{{POSTMORTEMS_DIR}}` | 事故复盘目录 | `docs/postmortems/` |
| `{{SPRINT_BRANCH_PREFIX}}` | sprint 子分支前缀 | `feature/dev.` |
| `{{CHORE_BRANCH_PREFIX}}` | chore 子分支前缀 | `feature/dev.chore.` |

### 注入机制(2 选 1)

**方案 A — SessionStart hook 注入**:
- hook 读项目 `.claude/project-vars.yaml`(新规约)
- 注入变量到 systemMessage(or env)
- skill / command 内用 `${REPO}` 引用

**方案 B — cookiecutter template repo**:
- 新项目 `cookiecutter <template-url>` 生成
- jinja2 替换 placeholder 为实际值
- 一次性 init,后续 skill 直接含具体值

**推荐**:**方案 B**(cookiecutter)— 一次性生成,后续 skill 简单可读;不依赖运行期注入。

---

## 4. 现状评估 → 下一步建议

### 4.1 短期(1 个 sprint 内)

- ✅ **Fix `my-issue-first-gate` label template**(2026-05-20 done — `feature` → `enhancement` + fallback 注释 + 实测案例)
- ✅ **晋升 `my-postmortem` 到 user-level**(2026-05-20 done — `~/.claude/skills/my-postmortem/` generic 化;项目级保留)
- ⏳ **完成本 P0-1 sprint** — 真 dispatch + 跑通,作 e2e demo 完整闭环

### 4.2 中期(下个 sprint 后)

- ⏳ **抽 cookiecutter template repo**(`~/projects/cookiecutter-claude-project/`)
- 含 skeleton:CLAUDE.md / .claude/rules/{team,git,project,behavioral} / .claude/skills/my-{start-sprint,pm-progress-sync,issue-first-gate,start-container,postmortem,dispatch-sprint} / .claude/commands/sprint/* / .claude/settings.json hooks
- jinja2 占位符(per §3 变量表)

### 4.3 长期(3-6 月,本项目跑稳)

- ⏳ **plugin 化首批 user-level skills** — `~/.claude/plugins/itc-jin-toolkit/`
- 包 `my-gh-issue-create` + `my-postmortem`(user-level)+ 通用 commands

---

## 5. 反模式(DON'T)

- ❌ 不在项目级 skill 改用 `{{VAR}}` 占位符(项目级应含实际值,template repo 才用占位符)
- ❌ 不删 project-specific 版本(晋升 user-level 后,项目级保留作 fallback)
- ❌ 不在 plugin 含 secrets / API key / private endpoints
- ❌ 不太早 plugin 化(< 3 项目验证就打包,反复改 plugin schema 麻烦)
- ❌ 不混 namespace(plugin skill 用 `/toolkit:skill`,项目级用 `/skill` no namespace)

---

> 📌 **Maintainer 注**:本规约 2026-05-20 引入,作 retrospective 评估 §3 差距 2 的 fix。后续晋升动作时,在 chore commit message 含 `Refs skill-promotion-path` + 更新 §1.4 / §2.4 现状表。
