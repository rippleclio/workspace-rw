# TODOS

## 共创模块 (Co-creation Module)

### ~~[高优先级] Vault 锁定后阻止招募新成员~~ ✅ 已完成
**Status:** Recruit/Apply/Approve/AcceptInvitation 全路径检查 `vault_locked`，返回 409。DB 迁移 0041 已添加字段。

### [高优先级] linkFailed 手动关联修复入口
**What:** DetailPage 展示「已发布但未关联共创项目」的视频列表，提供「现在关联」按钮。
**Why:** uploadStore 中 linkVideo 失败被静默处理。视频已发布但分成归因断路，Wabifair 订单将无法正确结算。
**Pros:** 给用户明确的修复路径，避免财务损失。
**Cons:** DetailPage 需新增 section，调用 creationApi.getUnlinkedVideos()（或复用现有 video list API 过滤）。
**Context:** 本次充刺范围内。linkFailed flag 在 uploadStore 中设置，UploadPage 显示 toast，DetailPage 提供永久修复入口。
**Depends on:** uploadStore linkFailed flag 实现。

### ~~[高优先级] 角色字段应用层校验~~ ✅ 已完成
**Status:** `validateRoles()` + `model.IsValidRole()` 在 creation-service handler 中实现，DB CHECK 约束 0044 同步。`GET /creation/v1/roles` 端点暴露合法角色列表。

### ~~[高优先级] 邀请卡片展示分成比例~~ ✅ 已完成
**Status:** InvitationsPage 已展示 `share_ratio`，当 `share_ratio > 0` 时显示百分比。

## 商品价值标签模块 (Product Value Tag Module)

### [中优先级] 为 wabifair-admin-console 创建 DESIGN.md
**What:** 运行 /design-consultation 为 wabifair-admin-console 建立正式的设计系统文档（色彩、间距、组件使用规范）。
**Why:** 当前无设计文档，每个新页面的色彩和间距选择依赖经验。长期会导致视觉不一致（已发现 `secondary-*` class 在 tailwind.config.js 中未定义但被使用）。
**Pros:** 为所有未来管理后台页面提供参考标准，避免人工每次决定颜色/间距。
**Cons:** 需要额外一次设计工作会话（约 20 分钟 CC 时间）。
**Context:** 从商品价值标签页面发现此问题：计划中使用了 `secondary-600` 但该 class 未在 tailwind.config.js 中定义，需手动修正为 `slate-600`。
**Depends on:** 无。

### [低优先级] Chip 选择器键盘导航
**What:** 为 ProductValueTagsPage 的 chip 选择交互添加键盘支持（Tab 切换 chip、Space 选中/取消、Delete 清除已选）。
**Why:** WCAG 2.1 AA 要求所有交互元素可键盘操作，尤其是自定义 chip 组件不使用原生 HTML 控件时需显式添加 ARIA 属性和键盘事件。
**Pros:** 满足无障碍合规要求，对使用键盘的用户体验更好。
**Cons:** 需要额外的 JS 键盘事件处理和 `role="option"`/`aria-selected` ARIA 属性。
**Context:** 当前计划中 chip 交互仅描述鼠标点选，键盘路径未指定。内部管理工具但建议统一实现以免后续补坑。
**Depends on:** ProductValueTagsPage 主体实现完成后。

## 技术债

### [中优先级] 成员接受后分成比例变更需要重新确认流程
**What:** 如果老板在成员接受邀请后修改其分成比例，成员需要重新确认（否则接受行为的法律/商业意义弱化）。
**Why:** 当前设计中，接受是一次性操作，之后老板可随意修改比例直到 vault 锁定。
**Context:** 本次充刺不实现。等产品方向确认后处理。

### [低优先级] rippleclio-web 关键弹窗添加 ErrorBoundary
**What:** 为 `RecruitMemberModal`、`CreateProjectModal`、`SetVaultModal` 等弹窗组件包裹 ErrorBoundary，捕获异步数据渲染异常。
**Why:** 这些弹窗涉及多个并发异步请求（honor 排行、用户搜索、角色列表），任一请求结果格式异常都可能导致白屏。CLAUDE.md 已标注 ErrorBoundary 为已知缺口。
**Pros:** 防止白屏，降级时展示友好提示而非崩溃。
**Cons:** 需要对 class-based ErrorBoundary 做 React 19 兼容封装。
**Context:** 本次改进后 RecruitMemberModal 的数据流更复杂，风险更高；但 ErrorBoundary 实现应作为单独 PR 处理，不阻塞本次改进。
**Depends on:** 无。

### [低优先级] 每视频 Vault 结算对账工具
**What:** 管理后台 / 运营工具，用于查看哪些 vault 结算失败、每个共创者的实际收款状态。
**Why:** 多视频多共创者时，结算对账复杂度线性增长，需要工具支持。
**Context:** 等共创模块稳定运行后再建。


Deferred items captured during engineering reviews. Each item is ready to pick up — context is here so you don't start cold.

---

## [Phase 4] US Sales Tax — Avalara vs. TaxJar

**What:** Integrate a sales tax SaaS for the US market before launch there.

**Why:** The US has 11,000+ tax jurisdictions (state + county + city + special district). A single rate (0.0875 "average") will miscalculate for every non-average user — either overcharge (consumer complaint risk) or undercharge (tax compliance risk). This is a legal requirement, not a nice-to-have.

**Pros of doing it properly:** Correct tax calculation on every US order; automated nexus tracking (as sales volume triggers nexus in new states, the SaaS handles it automatically).

**Cons:** Integration cost (~2 days), ongoing SaaS fee.

**Context:** The plan explicitly deferred US market to Phase 4. When that evaluation begins, the first engineering question will be vendor selection. The `sys.tax_rules` table intentionally has no `US` row — it's left empty as a reminder.

**Vendor options:**
- **TaxJar** — SMB-friendly. $19/month up to 1,000 API calls. REST API, Go SDK available. Good for < $10M US GMV/year.
- **Avalara AvaTax** — Enterprise. ~$500/month base. More accurate for complex nexus situations. Better audit support.

**Recommendation:** Start with TaxJar for Phase 4 pilot. Migrate to Avalara if US GMV exceeds ~$5M/year.

**Depends on:** US market go/no-go decision (Phase 3 evaluation node per the plan).

**Where to start:** `sys.tax_rules` (no US row currently). Integration point: `order-service` tax calculation, same `sys.tax_rules` lookup pattern, but instead of a local rule, call the SaaS API with buyer address + product category.


---

## Shipping Service (CarrierService 全链路)

### [Phase 1 Ops] Pre-flight checklist before Shopify CarrierService registration

**What:** Before running Step 3 (curl POST /carrier_services.json), verify three conditions.

**Why:** Each condition is a silent failure mode: (a) wrong Shopify origin country → every checkout returns empty rates and the integration looks dead; (b) migration not applied in prod → Yanwen DB lookup returns 500; (c) duplicate registration creates two conflicting carrier services in Admin.

**Checklist:**
1. Shopify Admin → Settings → Locations → confirm primary location country = CN
2. `SELECT COUNT(*) FROM fallback_rates;` in prod DB → should return ≥ 20 rows (5 countries × 4 bands)
3. `curl -s /admin/api/2026-01/carrier_services.json | jq '.carrier_services[] | select(.callback_url | contains("yanwen-rates"))'` → if empty, safe to POST; if found, use PUT or skip

**Pros:** Prevents three distinct silent-failure scenarios at registration time.

**Cons:** Extra manual steps before registration. Low cost (~5 minutes).

**Context:** Found during /plan-eng-review outside voice (codex). The non-CN origin risk is particularly acute — the E2E curl test in Step 5 hardcodes origin.country="CN", so it would pass even if real Shopify checkouts send a different origin.

**Depends on:** None.

**Where to start:** Do this in the design doc Step 3 sequence before running the registration curl.

---

### [Phase 2] Add GRANT SELECT ON fallback_rates TO svc_shipping

**What:** A new DB migration granting SELECT on `fallback_rates` to `svc_shipping` role.

**Why:** Migration 000099 only grants to `svc_catalog` (correct for Phase 1). Phase 2 switches the shipping service DB user to `svc_shipping` per the migration comment. Without this grant, every Yanwen rate lookup returns 500 in Phase 2.

**Pros:** Unblocks Phase 2 DB migration without any code change.

**Cons:** None — safe, additive change.

**Context:** `wabifair-commerce/db/migrations/000099_create_fallback_rates.up.sql` comment already anticipates this: "Phase 1 uses svc_catalog; Phase 2 will use svc_shipping".

**Depends on:** Phase 2 kickoff decision, svc_shipping role being created in prod DB.

**Where to start:** New migration file after 000099, e.g. `000100_grant_fallback_rates_to_svc_shipping.up.sql`.
