# 架构政策(只读,偏离需写 decision doc)

> **Refs**: [#23](https://github.com/m42981454-tech/doc/issues/23) — 2026-05-20 Phase 1 / 从 PROGRESS.md §📚 架构政策抽出
> **Status**: Source of truth — 偏离必先 `docs/YYYY-MM/<date>_decision_<topic>.md` 说明 why
> **加载**: 每会话(无 `paths:` frontmatter,与 `.claude/rules/` 其他 sub-file 同 baseline)

---

## 2026-05-17 /v1/* 鉴权方案 A 落定(单轨 sk_*)

| 路径前缀 | 鉴权 | 谁能访问 |
|---|---|---|
| `/portal/*` | Cookie + Portal JWT session | 匿名可访 landing/register;登录后 cookie 自动 |
| `/admin/*` | Admin JWT / X-Admin-Key | admin 角色登录 |
| `/v1/*` | **`Authorization: Bearer sk_*` 强制** | sk_* 持有者(portal /api-keys 创建)|
| `/health` `/docs` `/openapi.json` `/redoc` `/favicon` `/metrics` | 匿名 | 任何人 |

**核心规则**:
1. 新用户场景完全不受 sk_* 影响(走 `/portal/*` cookie session)
2. `/v1/*` 一定要 sk_*:无 Bearer 或非 sk_*/sk- 前缀 → 401 `v1.auth.apiKeyRequired`
3. Kong 角色降为 TLS / IP allow / per-consumer rate-limit;不再做内部鉴权 mapping
4. `X-Tenant-ID` header 降级为 legacy fallback(sk_* 自带 tenant_id;sprint 260517 fix.v1-tenant-from-state 后无需 header)

**业界对照**:OpenAI `Bearer sk-` / GitHub `Bearer ghp_` / Stripe `sk_live_` / **WinClaw `/v1/*` `Bearer sk_*`** ✅。

---

## 偏离规约

如未来有人提议改 /v1/* 鉴权或新增鉴权路径:
1. **必先**在 `docs/YYYY-MM/<date>_decision_v1-auth-X.md` 写 decision doc(why / risks / rollback)
2. PM 与用户确认后方可实施
3. 实施 commit 必 link 到 decision doc + Refs issue

**禁止**:
- ❌ 不在 `kong-gateway/config/kong.yml` 公共路径下加内部鉴权 mapping
- ❌ 不删 `/health` `/metrics` 匿名(必要的健康检查 / monitoring scrape)
- ❌ 不混 Cookie + Bearer(/v1/* 只 Bearer / /portal/* 只 Cookie)
