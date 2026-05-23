---
paths:
  - "[frontend-dir]/**"   # ← 替换为实际前端目录名，如 "frontend/**" 或 "web/**" 或 "app/**"
---

<!--
╔══════════════════════════════════════════════════════╗
║  新项目初始化清单（填完后删除此注释块）               ║
║                                                      ║
║  第 1 步：把 frontmatter 的 [frontend-dir] 改为      ║
║           实际目录名，如 frontend / web / app        ║
║                                                      ║
║  第 2 步：逐行替换下方 [占位符]，参考行内说明        ║
║                                                      ║
║  第 3 步：删除所有 "# ← ..." 注释行和本注释块        ║
║                                                      ║
║  若项目无前端，直接删除本文件                        ║
╚══════════════════════════════════════════════════════╝
-->

# Stack: Frontend 约定（path-scoped）

> 工作在 `[frontend-dir]/` 子树时自动加载。  <!-- ← 同步修改目录名 -->

## 技术栈

<!-- 每行填写实际版本，删除不适用的行 -->

- Next.js 14 App Router  # ← [FRONTEND_FRAMEWORK]：如 React + Vite / Vue 3 / Nuxt / SvelteKit
- TypeScript 5           # ← [LANGUAGE]：TypeScript 版本 / JavaScript
- Tailwind CSS 3         # ← [STYLING]：样式方案，如 CSS Modules / Styled Components / UnoCSS
- Zustand                # ← [STATE_MGMT]：状态管理，如 Redux Toolkit / Jotai / Pinia（无则删）
- next-intl              # ← [I18N]：国际化库（无则删此行），如 react-i18next / vue-i18n
- Jest + Playwright      # ← [TEST_FRAMEWORK]：单元测试 + E2E，如 Vitest + Cypress

## 测试命令

<!-- 命令假设从项目根运行；本 rule path-scoped 到子树，Claude 已知上下文 -->

```bash
tsc --noEmit                            # ← [type-check-command]：类型检查（JS 项目删此行）
jest                                    # ← [unit-test-command]：单元测试，如 vitest / npm run test
playwright test                         # ← [e2e-command]：E2E 测试，如 cypress run / npx playwright test
```

## 约定

<!-- 保留适用的，删除不适用的，补充项目特有的 -->

- **API 契约**：调用后端统一通过 `lib/api/` 下的 client，contract 变更需同步 `[backend-dir]`
  <!-- ← [backend-dir] 替换为实际后端目录名；纯前端项目删此行 -->
- **类型安全**：禁止 `any`，必要时用 `unknown` + 类型守卫
- **组件组织**：[components/ 目录结构规范]
  <!-- ← 如 "UI 原子组件放 components/ui/，业务组件放 components/features/" -->
- **a11y**：[无障碍要求]
  <!-- ← 如 "所有交互元素必须有 aria-label / WCAG 2.1 AA" / 或删除 -->
- **性能**：[Core Web Vitals 目标]
  <!-- ← 如 "LCP < 2.5s / CLS < 0.1 / 图片必须用 next/image" / 或删除 -->

## 不要做

- ❌ console 留下持续刷新的 error 循环（E2E 验证必须 console clean）
- ❌ 裸 `fetch()` 调用后端（统一走 `lib/api/`）  # ← 按项目实际调整或删除
- ❌ [其他项目特有反模式]                          # ← 删除此行或替换为实际约束
