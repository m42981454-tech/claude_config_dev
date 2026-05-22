---
paths:
  - "[frontend-dir]/**"
---

# Frontend 约定（path-scoped）

> 工作在 `[frontend-dir]/` 子树时自动加载。

## 技术栈

- [FRONTEND_FRAMEWORK]（如 Next.js 14 App Router / React + Vite / Vue 3）
- [LANGUAGE]（如 TypeScript / JavaScript）
- [STYLING]（如 Tailwind / CSS Modules / Styled Components）
- [STATE_MGMT]（如 Zustand / Redux / Context）
- [I18N]（如 next-intl，无则删除此行）
- [TEST_FRAMEWORK]（如 Jest + Playwright / Vitest）

## 测试命令

```bash
cd [frontend-dir]
[type-check-command]                    # type-check（如 tsc --noEmit）
[unit-test-command]                     # 单元测试
[e2e-command]                           # E2E 测试
```

## 约定

- **API 契约**：调用后端时使用 `lib/api/` 下的 client，contract 变更需同步 `[backend-dir]`
- **类型安全**：禁止 `any`，必要时用 `unknown` + 类型守卫
- [组件组织约定：components/ 目录结构 / 命名规范]
- [a11y 要求：WCAG 等级 / aria 规范]
- [性能要求：Core Web Vitals 目标 / Lighthouse 阈值]

## 不要做

- ❌ console 留下持续刷新的 error 循环（E2E 验证必须 console clean）
- ❌ [项目特有的反模式]
