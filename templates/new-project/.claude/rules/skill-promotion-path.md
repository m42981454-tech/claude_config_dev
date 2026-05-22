# Skill 晋升路径（Skill Promotion Path）

> **加载**: 每会话（无 `paths:` frontmatter）
> **目的**: 规范化"项目级 skill → user-level skill → plugin"三阶段晋升，实现真通配工程

---

## 0. 三阶段晋升

```
项目级 .claude/skills/my-*/
  ↓ （满足 user-level promotion 条件）
user-level ~/.claude/skills/my-*/
  ↓ （满足 plugin 条件）
plugin ~/.claude/plugins/<toolkit>/skills/
```

每阶段去除越多 project-specific 内容，通配性越强。

---

## 1. 项目级 → user-level 晋升

### 触发条件（任一满足即可考虑）

| 条件 | 说明 |
|---|---|
| **跨项目用 ≥ 2 次** | 同样的 skill 在另一项目想复用，只需改 ~30% 内容 |
| **去 hardcoded 后可用** | 把 repo / 分支 / 路径等替换成通用占位符（`[REPO]` / `[MAIN_BRANCH]` / `[PROGRESS_PATH]`）后，skill 100% 可用 |
| **设计 pattern 价值高** | 即使内容项目专属，设计模式（如 Issue-First gate / PROGRESS 三件套）有跨项目参考价值 |

### 反指标（不要晋升）

- ❌ skill 包含项目领域知识（如特定 schema / 网关配置 / 项目 ADR 编号）
- ❌ skill 调用项目级 agent / sub-rule（如调用 `.claude/rules/team-orchestration.md` 的 §2.5 决策表）
- ❌ skill description 含项目特定关键字

### 晋升步骤

1. **fork to user-level**: `cp .claude/skills/my-X/ ~/.claude/skills/my-X/`
2. **去 hardcoded**:
   - repo name → `[REPO]` 或 inline 注释 "替换为目标 repo"
   - branch name → `[MAIN_BRANCH]` 或 "替换为你的主线分支"
   - 路径 → `[PROGRESS_PATH]` / `[CLAUDE_RULES_PATH]`
3. **简化关联**: 删除引用项目级 sub-rule / agent 的 link，改写为通用描述
4. **保留 project version**: 项目级 `.claude/skills/my-X/` **不删**，保留作项目特定版本
5. **验证**: 在另一项目跑 1 次 user-level skill，确认 work

---

## 2. user-level → plugin 晋升

### 触发条件（任一满足即可考虑）

| 条件 | 说明 |
|---|---|
| **想分享给团队 / 社区** | 不只个人用，有公开价值 |
| **跨 ≥ 3 项目稳定使用** | 已验证 user-level skill 真通用 |
| **可独立成完整 toolkit** | 单 skill 太散；5+ 个相关 skill 才值得 plugin 化 |

### 反指标（不要 plugin）

- ❌ 还在频繁迭代（plugin schema 改动有版本管理负担）
- ❌ 含 secrets / 私有 API endpoint（plugin 公开后泄露）
- ❌ 依赖项目特定 agent / hook（plugin 需要 self-contained）

### 晋升步骤

1. **建 plugin 目录**: `~/.claude/plugins/<toolkit>/`（本地 marketplace）
2. **写 plugin.json**: 含 `name` / `version` / `skills` / `hooks` / `agents` 元信息
3. **bundle 资源**: 把 user-level skill / hook / agent 复制进 plugin 目录
4. **加 namespace**: `/<toolkit>:<skill>` 防命名冲突
5. **验证**: `claude` restart + plugin 自动 register；test invoke 各 skill / command
6. **发布**: GitHub repo or npm（若公开）

---

## 3. 通配工程 — 占位符变量模式

### 推荐占位符变量

| 变量 | 含义 | 示例 |
|---|---|---|
| `[REPO]` | GitHub repo `<owner>/<repo>` | `user/myapp` |
| `[MAIN_BRANCH]` | 主线分支名 | `feature/dev` / `main` |
| `[PROGRESS_PATH]` | PROGRESS.md 相对路径 | `progress.md` |
| `[CLAUDE_RULES_PATH]` | `.claude/rules/` 相对路径 | `.claude/rules/` |
| `[ISSUE_LABEL_FEATURE]` | "feature" label 在 repo 的实际命名 | `enhancement` / `feature` |
| `[POSTMORTEMS_DIR]` | 事故复盘目录 | `docs/postmortems/` |
| `[SPRINT_BRANCH_PREFIX]` | sprint 子分支前缀 | `[MAIN_BRANCH].` |
| `[CHORE_BRANCH_PREFIX]` | chore 子分支前缀 | `[MAIN_BRANCH].chore.` |

### 注入机制（2 选 1）

**方案 A — SessionStart hook 注入**:
- hook 读项目 `.claude/project-vars.yaml`
- 注入变量到 systemMessage（or env）
- skill / command 内用 `$REPO` 引用

**方案 B — cookiecutter template repo**:
- 新项目 `cookiecutter <template-url>` 生成
- jinja2 替换占位符为实际值
- 一次性 init，后续 skill 直接含具体值

**推荐**: **方案 B**（cookiecutter）— 一次性生成，后续 skill 简单可读；不依赖运行期注入。

---

## 4. 反模式（DON'T）

- ❌ 不在项目级 skill 改用 `[VAR]` 占位符（项目级应含实际值，template repo 才用占位符）
- ❌ 不删 project-specific 版本（晋升 user-level 后，项目级保留作 fallback）
- ❌ 不在 plugin 含 secrets / API key / private endpoints
- ❌ 不太早 plugin 化（< 3 项目验证就打包，反复改 plugin schema 麻烦）
- ❌ 不混 namespace（plugin skill 用 `/toolkit:skill`，项目级用 `/skill` no namespace）

---

> 📌 **Maintainer 注**：晋升动作时，在 chore commit message 含 `Refs skill-promotion-path` + 更新现状表（如有）。
