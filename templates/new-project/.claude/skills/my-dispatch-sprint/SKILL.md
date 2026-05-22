---
name: my-dispatch-sprint
description: 派 sub-agent 干 sprint 工作 — 当用户说"派单" / "dispatch backend" / "派 Code Reviewer"等显式 invoke 时使用。disable-model-invocation true（派单有副作用，要 PM 显式确认）。详细 13 agent 模板见 .claude/rules/team-orchestration.md。
disable-model-invocation: true
---

# my-dispatch-sprint

> **作用**：派 plugin sub-agent（Backend Architect / Code Reviewer / API Tester / Security Engineer / 等 13 个角色）干 sprint 工作
> **触发**：**只手动** `/my-dispatch-sprint` 或 [`my-start-sprint`](../my-start-sprint/SKILL.md) Step 5 内部调用（`disable-model-invocation: true` 防误派 agent — 单次 agent ~$0.20-0.40 sonnet，误派浪费成本）
> **关联规约**: [`.claude/rules/team-orchestration.md`](../../rules/team-orchestration.md) §2.1-§2.7（完整 13 agent 派单模板 + 4 channel 强制）

---

## 派单 5 步 SOP

### Step 1 — 任务性质决策（找正确角色）

查 [`.claude/rules/team-orchestration.md §2.5 触发决策表`](../../rules/team-orchestration.md)。常用速查:

| 任务性质 | Implementer | Reviewer | Tester | 追加 |
|---|---|---|---|---|
| 后端 API / Service | Backend Architect | Code Reviewer | API Tester | — |
| 前端 UI | Frontend Developer | Code Reviewer | Evidence Collector | — |
| 单文件 bug fix | Minimal Change Engineer | Code Reviewer | API Tester | — |
| auth / token / migration | Backend Architect | Code Reviewer | API Tester | **Security Engineer** |
| DB schema / migration | Backend Architect | Code Reviewer | API Tester | **Database Optimizer** |
| docker / monitoring | DevOps Automator | Code Reviewer | API Tester | **SRE** |
| GA 前 release | （按域）| Code Reviewer | API Tester + Evidence Collector | **Security + Reality Checker + SRE** |

### Step 2 — 4 Channel 强制（每个 dispatch 必含）

| Ch | 位置 | 强制格式 |
|---|---|---|
| **1** | Agent `description` 字段 | `[T#·Role·Sprint·Phase] <任务一句话>` |
| **2** | commit message subject role tag | `<type>(<sprint>·<Role>): <what>` |
| **3** | PROGRESS `§🔄` 表 | `Track ｜ Sprint ｜ Role(s) ｜ Phase ｜ Branch ｜ Status ｜ ETA` |
| **4** | sub-agent 返回 message **第一行 header** | `Agent: <Role> ｜ Track: <T#> ｜ Sprint: <N#-xx> ｜ Phase: <impl/review/test> ｜ Branch: <branch>` |

### Step 3 — 派单模板填空（13 个 agent 模板 link）

完整 13 个派单模板 → [`.claude/rules/team-orchestration.md §2.7`](../../rules/team-orchestration.md)。

**关键提醒**：`subagent_type` **必用 Title Case friendly name**（如 `"Backend Architect"`），**不是** kebab-case file name（`"engineering-backend-architect"` 会 not found）。

**Implementer 派单标准格式**（挑 1 个 Implementer）:

```javascript
Agent({
  description: "[T1·BackendArchitect·N1-bk·impl] <任务一句话>",
  subagent_type: "Backend Architect",  // 或 "Frontend Developer" / "Minimal Change Engineer"
  prompt: `
    上下文：贴 spec 章节 + 文件路径 + 行号
    任务：明确动作，最小变更范围
    验收：pytest 命令 / 期望测试通过 / 设计文档章节引用
    禁止：扩大重构 / 修改无关文件 / 跳过测试
    起手：必跑 \`git fetch && git checkout [MAIN_BRANCH]\` 防 stale base（per stale base 教训）
    Commit 约定（ch2）：subject 必含 \`<type>(<sprint>·<Role>): <what>\` role tag
    报告约定（ch4）：返回 message 第一行必为 \`Agent: <Role> ｜ Track: <T#> ｜ Sprint: <N#> ｜ Phase: impl ｜ Branch: <branch>\`，后接变更文件清单 + 测试结果
  `
})
```

**Code Reviewer 派单**:

```javascript
Agent({
  description: "[T#·CodeReviewer·<sprint>·review] Review <PR>",
  subagent_type: "Code Reviewer",
  prompt: `
    审查范围：具体文件列表 + diff hash
    Review 标准:
      1. 代码质量：可读性 / 错误处理 / 边界条件
      2. 设计契合：对照 design/ 章节
      3. 测试覆盖：核心 ≥ 90% / 整体 ≥ 80%
      4. 向后兼容：既有 baseline 全绿
    输出格式：✅ 通过 / ⚠️ 建议 / ❌ 阻断，每项 file:line
  `
})
```

**Tester (API) / Tester (UI) / Security Engineer / Reality Checker / 其他 8 模板** — 详 `.claude/rules/team-orchestration.md §2.7`。

### Step 4 — 并发规则

- **独立任务必须并行**：同一条消息内多个 `Agent` tool calls
- **串行依赖不可并行**：Architect 设计 → Implementer 实装 → Reviewer → Tester → (Security / Reality / SRE 按需) → PM 收尾
- **并发 ≤ 5 agent**（成本 + 串扰风险）

### Step 5 — 必经双签 + 按需追加 — merge 前 gate

- ✅ Code Reviewer + Tester **双签** = 最低 merge 前提
- ✅ Security / Reality / SRE / Database Optimizer 按 §2.5 触发表 ✓ 必经签字；❌ 阻断 merge
- Tester 报 bug → PM 派 Implementer 修 → Tester 重测，**循环直到 console 干净**

---

## DON'T

- ❌ 不用 kebab-case `engineering-backend-architect`（会 not found，用 `"Backend Architect"`）
- ❌ 不并发 > 5 agent（成本 + 串扰）
- ❌ 不省略 4 channel 任一（ch1 漏 → PM 退回派单）
- ❌ 不在 hook 里调 agent（费用 + 不确定）
- ❌ 派 future doc agent 漏 sprint 完成清单
- ❌ 不主线 Opus 上做编码 — Sonnet sub-agent 干活（§2.1）
- ❌ Tester ❌ 不修代码，只报 bug 给 PM（§2.6）
