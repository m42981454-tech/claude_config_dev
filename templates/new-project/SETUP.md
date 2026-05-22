# 新项目初始化手顺

> 把 `new-project/` 模板复制到目标目录后，按以下步骤完成初始化。
> 完成后删除本文件（`SETUP.md`）、`project.env`、`init.sh`。

---

## Step 1 — 填写 `project.env`

打开根目录的 `project.env`，按注释说明填写所有变量：

| 变量 | 影响的文件 |
|---|---|
| `PROJECT_NAME` / `PHASE` / `MAIN_BRANCH` | `CLAUDE.md`、`git-workflow.md`、`behavioral-rules.md` |
| `BACKEND_DIR` / `FRONTEND_DIR` | `stack-backend.md`、`stack-frontend.md` 的 path-scoped 触发路径 |
| `BACKEND_STACK` / `FRONTEND_STACK` / `INFRA` | `CLAUDE.md` 技术栈摘要 |
| 后端/前端技术栈详情 | `stack-backend.md` / `stack-frontend.md` 技术栈列表 |

---

## Step 2 — 运行初始化

**推荐（Claude Code 环境）**：

```
/project:init
```

Claude 会读取 `project.env`，智能替换所有占位符，清理未用的技术栈行，并推荐 agent 配置。

**备选（无 Claude Code / 纯 shell 环境）**：

```bash
bash init.sh
```

---

## Step 3 — 手动收尾（脚本无法自动化的部分）

1. **`stack-backend.md`** — 删除不适用的技术行（如无 Redis、无 Celery）；补充测试命令、约定、反模式
2. **`stack-frontend.md`** — 同上；删除无关技术行（如无 i18n）
3. **`.claude/agents/.enabled`** — 参照 `.enabled.example` 按需启用 agent
4. 若项目无后端 → 删除 `stack-backend.md`；若无前端 → 删除 `stack-frontend.md`

---

## Step 4 — 清理并首次 commit

```bash
rm project.env init.sh SETUP.md
git init
git add .
git commit -m "chore: init project from template"
```

重启 Claude Code，验证 SessionStart 摘要显示正确的分支和 PROGRESS 行数。

---

> **stack-*.md 占位符说明**：若某个变量值暂时不确定，可先在 `project.env` 里写一个占位值，
> 脚本跑完后再手动修改对应文件中的那一行。
