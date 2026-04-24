## Summary

Storefront product detail now renders per-region effective stock + presale when backend supplies them. Adds `region_out_of_stock` amber state distinct from global "out of stock". Zero regression risk — all fields optional, old code paths preserved.

**Commits (2)**
- `1f8d9e0` /review fix: `product.region_out_of_stock` i18n key across all 22 locales
- `caa2924` Render per-region `effective_stock` + `effective_presale` when backend supplies them

## Depends on

wabifair-commerce PR: https://github.com/rippleclio/wabifair-commerce/pull/new/feat/per-region-inventory-presale

Backend must merge first — adds the `effective_stock` / `effective_presale` / `stock_source` fields to `ProductDetail` response. Without that, this PR's new UI paths never activate (optional fields stay undefined → fallback to existing `stock` / `is_presale`).

## What changes visually

- Stock source `"region"` with 0 count → amber **"本地区暂无库存"** (was red "out of stock")
- Presale display reads `effective_presale` first (per-region presale config takes precedence over global)
- Other branches unchanged — products with `effective_*` = undefined render exactly as before

## Files

- `src/types/product.ts` — added `effective_stock` / `stock_source` on `ProductSku` + `ProductDetail`; new `EffectivePresaleConfig`
- `src/components/product/ProductInfo.tsx` — fallback chain + new amber state + `stockIsRegionResolved` flag
- `src/i18n/locales/*.json` — new `product.region_out_of_stock` key in all 22 locales (zh-CN + 6 English variants get proper copy, 15 others stubbed with `[EN]` prefix matching existing convention)

## Paired PRs

- wabifair-commerce: https://github.com/rippleclio/wabifair-commerce/pull/new/feat/per-region-inventory-presale
- wabifair-admin-console: https://github.com/rippleclio/wabifair-admin-console/pull/new/feat/per-region-inventory-presale

## Test plan
- [x] `tsc --noEmit` clean
- [x] `vite build` clean (1.34s)
- [ ] Manual: load product detail with `X-User-Country: JP` against backend with flag ON + JP stock row present → `effective_stock` renders
- [ ] Manual: same product with flag OFF → falls back to `product.stock`
- [ ] Manual: switch locale to en-US / ja-JP → amber state shows English / `[EN]` stubbed copy

## Known follow-ups
- Notify-me hook wire on `region_out_of_stock` amber state (UI exists, backend endpoint + button connect pending)
- Proper translations for 15 `[EN]` stubbed locales

🤖 Generated with [Claude Code](https://claude.com/claude-code)
