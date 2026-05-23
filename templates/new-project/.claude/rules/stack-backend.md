---
paths:
  - "[backend-dir]/**"    # ← 替换为实际后端目录名，如 "backend/**" 或 "api/**" 或 "server/**"
---

<!--
╔══════════════════════════════════════════════════════╗
║  新项目初始化清单（填完后删除此注释块）               ║
║                                                      ║
║  第 1 步：把 frontmatter 的 [backend-dir] 改为       ║
║           实际目录名，如 backend / api / server      ║
║                                                      ║
║  第 2 步：逐行替换下方 [占位符]，参考行内说明        ║
║                                                      ║
║  第 3 步：删除所有 "# ← ..." 注释行和本注释块        ║
║                                                      ║
║  若项目无后端，直接删除本文件                        ║
╚══════════════════════════════════════════════════════╝
-->

# Stack: Backend 约定（path-scoped）

> 工作在 `[backend-dir]/` 子树时自动加载。  <!-- ← 同步修改目录名 -->

## 技术栈

<!-- 每行填写实际版本，删除不适用的行 -->

- Python 3.11          # ← [BACKEND_LANGUAGE_VERSION]：语言 + 版本，如 Node 20 / Go 1.22 / Java 21
- FastAPI              # ← [BACKEND_FRAMEWORK]：Web 框架，如 Express / Gin / Spring Boot / Django
- SQLAlchemy + Alembic # ← [ORM_AND_MIGRATIONS]：ORM + 迁移工具，如 Prisma / Drizzle / Sqlx / GORM
- PostgreSQL 15        # ← [DATABASE]：主数据库 + 版本，如 MySQL 8 / MongoDB 7 / SQLite
- Redis 7              # ← 缓存 / 消息队列（无则删此行）
- Celery               # ← [TASK_QUEUE]：任务队列（无则删此行），如 BullMQ / Sidekiq
- pytest               # ← [TEST_FRAMEWORK]：测试框架，如 Jest / go test / JUnit

## 测试命令

<!-- 命令假设从项目根运行；本 rule path-scoped 到子树，Claude 已知上下文 -->

```bash
pytest                                  # ← [test-command]：全量测试
pytest tests/path/to/test_file.py       # ← 单文件测试（路径格式按实际调整）
python -c "import app"                  # ← [compile-check-command]：导入/编译检查，无则删此行
```

## 约定

<!-- 保留适用的，删除不适用的，补充项目特有的 -->

- **API 契约**：影响共享路由 / 请求响应 schema 的变更，必须同步更新前端 client（`[frontend-dir]/lib/api`）
  <!-- ← [frontend-dir] 替换为实际前端目录名；纯后端项目删此行 -->
- **错误码**：[统一错误码规范，如 RFC 7807 / 业务错误码枚举路径]
  <!-- ← 填写项目错误处理规范，或删除 -->
- **异步边界**：[async/await 规则 / 事务边界 / 连接池限制]
  <!-- ← 如 "所有 DB 操作必须在 async 函数内" / "禁止在路由层直接操作 DB" -->
- **日志**：[日志格式 / 级别约定 / 禁止 print]
  <!-- ← 如 "使用 structlog JSON 格式，禁止裸 print" -->

## 不要做

- ❌ 裸 `print()` 调试（用 logger）   # ← 按项目实际补充反模式
- ❌ [其他项目特有反模式]              # ← 删除此行或替换为实际约束
