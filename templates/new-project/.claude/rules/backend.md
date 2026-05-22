---
paths:
  - "[backend-dir]/**"
---

# Backend 约定（path-scoped）

> 工作在 `[backend-dir]/` 子树时自动加载。

## 技术栈

- [BACKEND_LANGUAGE_VERSION]（如 Python 3.11 / Node 20 / Go 1.22）
- [BACKEND_FRAMEWORK]（如 FastAPI / Express / Gin）
- [ORM_AND_MIGRATIONS]（如 SQLAlchemy + Alembic / Prisma / Sqlx）
- [DATABASE]（如 PostgreSQL 15 + Redis 7）
- [TASK_QUEUE]（如 Celery + Redis，无则删除此行）
- [TEST_FRAMEWORK]（如 pytest / Jest / go test）

## 测试命令

```bash
cd [backend-dir]
[test-command]                          # 全量测试
[test-command] tests/path/to/test_file  # 单文件
[compile-check-command]                 # 编译/导入检查（如有）
```

## 约定

- **API 契约**：影响共享 API 契约 / 路由的变更，必须同步更新前端 client（`[frontend-dir]/lib/api`）
- [其他后端专项约定：session 管理 / 异步规则 / 事务边界 / 错误码规范等]
- [日志、监控、metrics 相关要求]

## 不要做

- ❌ [项目特有的反模式]
