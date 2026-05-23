---
paths:
  - "docs/**/*.md"
---

# docs/ 文档规约（path-scoped rule）

> **作用**: 经 frontmatter `paths: ["docs/**/*.md"]` 自动在 Claude 改/读 `docs/` 下任何 `.md` 时载入（**不入 session start baseline**）。与主 `CLAUDE.md` / 其他 `.claude/rules/*.md` concatenated，不 override。
> **不重复**: 本文件**不**复制主 `CLAUDE.md` 内容，只覆盖 docs/ 子目录独有约定。

---

## 1. 命名规约（强制）

### 1.1 月份归档

**新建近月 doc 入 `docs/YYYY-MM/<file>.md`**（月份目录），不再裸放 docs/ 顶层。

| 类型 | 命名 | 示例 |
|---|---|---|
| 决策（architecture / tech / process 选型）| `docs/YYYY-MM/YYYY-MM-DD_decision_<topic_snake>.md` | `docs/2026-05/2026-05-19_decision_<topic>.md` |
| 分析 / audit / spike | `docs/YYYY-MM/YYYY-MM-DD_<topic_snake>.md` | `docs/2026-05/2026-05-19_<topic>.md` |
| 设计提案（未实施）| `docs/YYYY-MM/YYYY-MM-DD_proposal_<topic>.md` | — |
| 接力卡（handoff）| `docs/YYYY-MM/YYYY-MM-DD_handoff_<topic>.md` 或 sprint 专辑内 `99-next-session-handoff.md` | — |
| **例外保留顶层**（无日期 / 固化）| `<scope>_runbook.md` / `<topic>-proposal.md` | `admin_runbook.md` |

**铁律**:

- 新建 doc **必含 `YYYY-MM-DD_` 日期前缀**（除固化 runbook）
- 新建 doc **必入对应月份目录 `docs/YYYY-MM/`**
- 同一天多个 doc 用 `_<topic>` 区分
- 月份目录用 4 位年 + 2 位月，中间 `-`：`2026-05/` 不是 `202605/`（对齐 doc 日期 prefix 格式）

### 1.2 sprint 专辑（numbered set）

| 用途 | 目录 | 文件 |
|---|---|---|
| sprint 设计 / 实施 / review / 总结 | `YYYYMMDD/` 或 `YYYYMMDD-<phase>/` | `00-XX-NN.md` `01-XX.md` … 按章节编号 |

**铁律**: **sprint 专辑必 numbered prefix**（`00-` `01-` ...），总纲文件用 `00-`。

### 1.3 子目录用途

| 目录 | 内容 | 何时进 |
|---|---|---|
| **`docs/YYYY-MM/`**（月份目录，**新建首选**）| 该月单 doc（decision / analysis / proposal / handoff）| 新建首选 |
| `docs/`（顶层）| 仅例外：无日期固化 runbook + 历史无日期 proposal | 不新写 |
| `docs/archive/` | 历史 design / decision / proposal / sprint 报告 | doc 超 30 day 不被引用 → PM 在下次 chore 移入 |
| `docs/brainstorm/` | 启发式 brainstorming notes | brainstorm 阶段产出 |
| `docs/postmortems/` | 事故复盘（模板见 `postmortems/README.md`）| 每次重大事故必建独立 .md |
| `docs/YYYYMMDD/` 或 `YYYYMMDD-confirm/` `YYYYMMDD-future/` | sprint 专辑（numbered set）| sprint 进行中（整个 numbered 集）|

**铁律**:

- **不在 `docs/archive/` 下新写 doc**（只移入）
- **不在已 closed sprint 专辑下追加 doc**（若需追加，在 `docs/YYYY-MM/` 新建 `YYYY-MM-DD_<sprint>_followup_<topic>.md`）
- **新建单 doc 必入 `docs/YYYY-MM/`**；sprint 专辑仍按 `YYYYMMDD/` 整体形态（向下兼容，不动既有）

### 1.4 命名反模式（禁止）

- ❌ 全英文驼峰 / kebab 但**无日期**（除固化 runbook）: `fooBarReport.md` / `foo-bar-report.md` → 找不到时间脉络
- ❌ 大写 `PROPOSAL_<X>.md` 等遗留风格（只在 archive 保留；新建用 `YYYY-MM-DD_proposal_<x>.md`）
- ❌ 数字开头但无目录（`00-summary.md` 顶层）: 务必放进 sprint 专辑目录
- ❌ 重复日期 + 重复 topic（同 topic 改了多次？用 `YYYY-MM-DD_<topic>-v2.md` 显式编号，**不覆盖**原 doc）

---

## 2. 格式约定（强制）

### 2.1 头部 frontmatter（每 doc 顶部 5 行内必含）

```markdown
# <doc 标题（短句，可中英混排）>

> **Refs**: [#N](<issue-url>)  (issue 必带 — 若无 issue，留 "n/a")
> **Date**: YYYY-MM-DD                                              (可选；文件名已含)
> **Status**: Draft / Reviewed / Implemented / Archived             (decision/proposal 必含)
> **Cross-ref**: 关联的 issue / 其他 doc / commit hash             (有则填)
```

### 2.2 内文风格

- **中文优先，英文 jargon 用反引号包**: `async / await` / `git merge --no-ff` / `pytest`
- **结论先，依据后**: 每段第一句话给结论，后面展开
- **bullet / 表格优先，长段落次之**: 扫读友好
- **代码块标语言**: ` ```bash ` / ` ```python ` / ` ```markdown `

### 2.3 必含结构（decision / proposal / analysis）

| 段 | 必含? | 内容 |
|---|---|---|
| `## TL;DR` 或 `## 0. 摘要` | 强烈推荐（给 30 秒回看的人）| 1-3 行核心结论 |
| `## 背景` | 必含 | why 这个 doc 存在 |
| `## 决策 / 方案` | 必含（decision/proposal）| what 拍板的 |
| `## 风险 / 反对意见 / Rollback` | 必含（decision）| 接受了什么风险 + 怎么退出 |
| `## 验收 / 实施 / 后续` | 必含（proposal）| 怎么落地 + 谁负责 |
| `## Sources / 参考` | 必含（含外部链接的 doc）| 引用源（markdown link）|

### 2.4 链接规约

- **GitHub issue / PR**: `[#N](<issue-url>)`（repo 名必含，跨项目可读）
- **本 repo 内其他 doc**: `` `../foo.md` `` 或 `path/foo.md`（相对路径）
- **commit hash**: 反引号包，可附 link
- **外部 URL**: 总是用 markdown link 格式，不裸贴

---

## 3. 何时新建 doc vs 续写

| 场景 | 新建 / 续写 |
|---|---|
| 新 sprint 启动设计 | 新建 `docs/<YYYYMMDD>/00-<sprint-name>.md` |
| sprint 中产出 review / test / runbook | 新建在 `docs/<YYYYMMDD-confirm>/` 或 `<...-future>/` 内 numbered |
| 已 merge sprint 发现 1 处需补充 | 新建 `docs/YYYY-MM/YYYY-MM-DD_<sprint>_followup_<topic>.md`，**不**改原 sprint 专辑 |
| 一次性决策（本会话内拍板）| 新建 `docs/YYYY-MM/YYYY-MM-DD_decision_<topic>.md` |
| 同 topic 第二次决策（推翻 / 演进）| 新建 `YYYY-MM-DD_decision_<topic>-v2.md` + 头部 link 到 v1 |
| 事故复盘 | 新建 `docs/postmortems/YYYY-MM-DD_<incident>.md`（模板见 `postmortems/README.md`）+ 更新 `postmortems/README.md` 索引表 |
| brainstorm | 新建 `docs/brainstorm/YYYY-MM-DD_R<N>_<topic>.md`（numbered）|
| **修复 typo / 链接错** | **直接 edit 原 doc**（不新建）|
| **doc 内容明显过时**（版本号 / commit hash 引用已 revert / sprint 状态）| 优先**头部加 deprecated 标注 + link 到替代 doc**；不直接覆盖（保留历史）|

---

## 4. archive 触发（强制）

**自动触发条件**（下次 chore 检视时 PM 移入 `docs/archive/`）:

- 顶层 / 月份目录 doc `YYYY-MM-DD_<topic>.md` 创建日期 > **30 天前**
- 30 天内 0 次 grep 引用（同仓库其他 .md / .py / 主 CLAUDE.md / PROGRESS.md 都无引用）
- **例外保留**: 近 7 day 决策 / 持续 in-progress sprint / 固化 runbook

**手动触发**: 用户说"归档 X" / PM 在 chore.docs-archive 内主动整理。

**archive 移入步骤**:

1. `git mv docs/<file>.md docs/archive/<file>.md`（保留同名，git 历史 follow）
2. grep 全 repo 检查引用 → 找到引用处全更新路径（或在原 doc 头加 `Archived: see docs/archive/<file>.md` redirect）
3. **不**改 archive 内任何 doc 内容（只移动）

**禁止**:

- ❌ 不 `git rm` 历史 doc（永远保留，即使过时）
- ❌ 不 `archive/` → 顶层"复活"（若需重新激活，**新建** v2 + link 到 archive 原版）
- ❌ 不在 archive 内续写 / 修改

---

## 5. DON'T 清单（本目录独有）

- ❌ **不在 docs 下放代码 / 配置 / 二进制**（SQL migration / Python / JSON / 图片大于 100KB 等）— 这些进 `<src-dir>/` / 项目根
- ❌ **不复制 CLAUDE.md / .claude/rules/ 内容到 docs**（只能 link）— 否则规约多源不一致
- ❌ **不在 doc 里嵌入 secrets / API key / `.env` 内容** — 即使示例也用 placeholder（`<your-api-key>`）
- ❌ **不动 `design/` 顶部正式契约文档**（那是 source-of-truth，偏离需在 docs/ 写 decision_*.md 说明 why）
- ❌ **不在 sprint 专辑外横挂顶层 numbered file**（`00-foo.md` 在顶层 = 错误位置）
- ❌ **不删 / 不 rewrite 历史 postmortems**（只增不改；补充用新 postmortem）
- ❌ **不在 archive/ 下做活跃工作**（只读 + 移入）

---

## 6. 关联规约（主 CLAUDE.md / 其他 .claude/rules/ 已规定的不重复）

| 不在本文件 | 在哪 |
|---|---|
| Git workflow（子分支 / merge --no-ff / push）| 主 `CLAUDE.md` §7 + `.claude/rules/git-workflow.md` |
| 派 agent / 团队编排 | 主 `CLAUDE.md` §4 + `.claude/rules/team-orchestration.md` |
| Issue-First gate（开 sprint 必先 issue）| `.claude/rules/git-workflow.md §7.9` |
| PROGRESS.md 维护 | `.claude/rules/progress-conventions.md` |
| 设计契约 / 技术栈 / 测试 | 主 `CLAUDE.md` §3-§6 + `.claude/rules/project-context.md` |
| 行为 4 原则（karpathy）| `.claude/rules/behavioral-rules.md §10` + skill `karpathy-guidelines` |

---

## 7. 本文件的加载机制（path-scoped）

本文件位于 `.claude/rules/`，通过 frontmatter `paths: ["docs/**/*.md"]` 实现 **path-scoped 按需 load**:

- **不入 session start baseline**（无 `paths:` 的 rules 才入 baseline）
- Claude 读 `docs/` 下任何 `.md` 时 → 本文件载入到 context
- 与主 `<repo>/CLAUDE.md`（每会话 load）+ `~/.claude/CLAUDE.md`（每会话 user-level）+ 路径上其他 CLAUDE.md **全部 concatenated**（不 override）
- 顺序: filesystem root → cwd（深层最后读 = 权重稍大）
- 不限层数（walking up to filesystem root）

参 [Claude Code memory docs](https://code.claude.com/docs/en/memory)。
