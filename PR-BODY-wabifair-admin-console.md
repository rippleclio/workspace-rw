## Summary

Admin console UI for per-country inventory + presale configuration. Merchants + platform admins can configure 8 markets (CN/TH/SG/JP/KR/US/GB/DE) per product, with SKU-level stock + per-region presale. Optimistic concurrency prevents SKU ghost-zeroing.

**Commits (2)**
- `e36fb73` /review fixes: Tailwind tokens + draft rehydration + modal ESC + mount gate + success state
- `52fbb8b` RegionConfigSection + 6 React Query hooks + 8-country whitelist

## Depends on

wabifair-commerce PR: https://github.com/rippleclio/wabifair-commerce/pull/new/feat/per-region-inventory-presale

Backend must merge first — admin endpoints `/merchant|/admin/cms/products/:id/regions/:code/inventory|presale` only exist when `FEATURE_PER_REGION_INVENTORY=true`. Hooks gracefully treat 404 as "flag OFF → show all-regions-use-global" without erroring.

## What the merchant sees

New "市场与库存(按国家独立)" card on the product edit page, positioned after 分成配置:

- Accordion row per country (flag + name + collapsed badge showing "N SKU · M 件" or "使用全局")
- Expanding a country reveals: per-SKU stock table (with "用全局值" shortcut), low-stock threshold, and presale configuration (toggle + deposit rate + ship date + end time + limit-per-user)
- Per-region Save buttons with "✓ 已保存" success chip
- Remove this region → confirm modal with explicit "hard delete" copy + ESC-to-close
- Optimistic-lock 409 → "他人已修改,请刷新" toast + auto query invalidation

## Files

- `src/components/admin/region-config/supported-regions.ts` — 8-country whitelist
- `src/components/admin/region-config/RegionConfigSection.tsx` — main component (~500 lines)
- `src/components/admin/region-config/index.ts` — barrel
- `src/hooks/admin/useRegionConfigData.ts` — 6 React Query hooks (list + CRUD × 2)
- `src/pages/merchant/MerchantProductEditPage.tsx` — mount point

## Interaction states covered (per /autoplan §17.7 R5)

| # | State | Status |
|---|---|---|
| 1 | Accordion collapsed badge | ✓ |
| 2 | Mid-save UI (button state + toast + success chip) | ✓ |
| 5 | Confirm modal (rose destructive + ESC + click-outside) | ✓ |
| 7 | Keyboard nav (Space/Enter via native button, aria-expanded/aria-controls) | ✓ partial |
| 8 | ARIA labels on all inputs | ✓ |
| 11 | "Copy from global" per SKU | ✓ |

Deferred (separate PRs): arrow-key nav between accordions, `PrimaryOnlyGate` wrap, matrix bulk edit, CSV export, legacy 预售 card retirement.

## Paired PRs

- wabifair-commerce: https://github.com/rippleclio/wabifair-commerce/pull/new/feat/per-region-inventory-presale
- wabifair-storefront-web: https://github.com/rippleclio/wabifair-storefront-web/pull/new/feat/per-region-inventory-presale

## Test plan
- [x] `tsc --noEmit` clean
- [x] `vite build` clean (1.28s, +24KB merchant page chunk)
- [ ] Manual (flag OFF): open product edit → "市场与库存" card shows all 8 countries as "使用全局", no errors
- [ ] Manual (flag ON): prick US → fill stock per SKU → Save → "✓ 已保存" appears → reload page → values persist
- [ ] Manual: two tabs editing same US stock → second Save returns 409 → toast + query refetches → second Save succeeds
- [ ] Manual: click "移除 US 配置" → confirm modal → ESC closes → click confirm → region deletes

## Known follow-ups
- `AdminMerchantProductEditPage` mirror (same component, different mount scope)
- Arrow-key navigation between accordion panels
- "已保存 · 2 秒前" relative timestamp instead of simple ✓
- Bulk CSV export + per-region kill switch (plan §17.7 R6 bulk ops)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
