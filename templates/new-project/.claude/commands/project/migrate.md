---
description: Migrate template modules into an existing project without overwriting existing files.
---

# /project:migrate

将模板模块迁入已有项目。适用于不能用 `init.sh` 的存量项目迁移场景。

核心原则：**不覆盖已有文件**，只补充缺失的模块。

## 前提

- 已有项目必须是 git 仓库（或在迁移后执行 `git init`）。
- `project.env` 存在于目标目录时，占位符值从中读取；否则使用模板默认值，迁移后手动替换。

## 用法

```bash
bash .claude/scripts/migrate.sh [TARGET_DIR]
```

`TARGET_DIR` 省略时默认为当前目录。支持预览模式（不实际写入）：

```bash
DRY_RUN=1 bash .claude/scripts/migrate.sh [TARGET_DIR]
```

## Steps

1. 确认目标目录存在且是已有项目根目录。
2. 运行迁移脚本：

```bash
bash .claude/scripts/migrate.sh /path/to/existing-project
```

3. 脚本将按顺序迁入以下模块（目标已存在则跳过）：
   - `CLAUDE.md` / `progress.md`（缺失时从模板创建，含占位符替换）
   - `.claude/scripts/`
   - `.claude/commands/`
   - `.claude/agents/_available/` + README + `.enabled.example`
   - `.claude/rules/`（已存在的规则文件跳过，输出手动 merge 提示）
   - `.claude/skills/`
   - `.githooks/`（含 install + pre-commit 占位符替换）
   - `.gitattributes`
   - `.gitignore` / `.claudeignore`（追加缺失行）
   - `.claude/settings.json`
   - `docs/postmortems/README.md`
   - `docs/report/`（创建目录）

4. 按脚本末尾的手动 review 清单处理跳过项（尤其是 `.claude/rules/` 和 `settings.json`）。

5. 运行验证：

```bash
bash .claude/scripts/validate.sh
```

## 与 /project:init 的区别

| | `/project:init` | `/project:migrate` |
|---|---|---|
| 适用场景 | 从模板新建项目 | 已有项目迁入模板 |
| 入口文件 | `init.sh` | `migrate.sh` |
| CLAUDE.md | 替换占位符 | 已存在则跳过 |
| rules | 全量替换 | 已存在则跳过，提示手动 merge |
| 覆盖行为 | 全量写入 | 不覆盖，追加或跳过 |

## Completion Checklist

- `migrate.sh` 执行完毕，无 `cp:` 错误输出。
- 手动 merge 了所有标注 `📌` 的跳过项（尤其是已有的 rules 和 settings.json）。
- `validate.sh` exit 0。
- `CLAUDE.md` 和 `progress.md` 中的模板占位符已替换为实际项目信息。
- 在工作分支上做第一个 commit，不直接提交到主线。
