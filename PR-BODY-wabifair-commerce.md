## Summary

Per-country independent inventory and presale configuration, shipped end-to-end behind two separate feature flags (dark rollout, zero default behavior change).

**Commits (7)**
- `bbcba31` Order-time per-region stock deduction + restore
- `b8d726b` /review fixes: R2-A flag split + audit actor attribution + remove dead middleware
- `36198ac` Storefront product detail resolves per-region stock+presale (read path)
- `8ae7361` Admin + merchant CRUD endpoints behind feature flag
- `4e9411f` Repos + service + middleware (fallback resolver, optimistic lock)
- `9ca75b5` Schema: `pms.product_region_inventory` + `pms.product_region_presale` + `sys.audit_logs`
- `fd48bbe` (prior) Locale-primary media + /localizations listing endpoint

## Plan + Reviews

- Design doc: `documents/wabifair/per-country-inventory-presale-plan.md` (520+ lines, §17 covers the /autoplan review + approved revisions)
- `/autoplan` verdict: **APPROVED_WITH_REVISIONS** (Option A — user accepted all CEO/Eng/Design/DX concerns)
- `/review` verdict: `CHANGES_REQUESTED` → all CRITICAL + HIGH fixed in `b8d726b`

## Schema (migrations 000091 / 000092 / 000093)

```sql
pms.product_region_inventory (product_id, sku_id, region_code, stock, low_stock_threshold, reserved_stock)
  UNIQUE (product_id, sku_id, region_code)
  CHECK stock >= 0, reserved <= stock

pms.product_region_presale (product_id, region_code, is_presale, deposit_rate, expected_ship_date, presale_end_time, limit_per_user)
  UNIQUE (product_id, region_code)
  CHECK deposit_rate ∈ (0, 1], presale_end_time <= expected_ship_date

sys.audit_logs (actor_type, actor_id, action, entity_type, entity_id, region_code, before JSONB, after JSONB)
```

All migrations pure additive + idempotent. Down migrations included.

## Feature flags (server-side gating)

- `FEATURE_PER_REGION_INVENTORY` — admin write endpoints only (default OFF)
- `FEATURE_PER_REGION_INVENTORY_READ_PATH` — storefront read + oms deduction (default OFF)

Rollout: Stage B flips write flag → seed data + QA → Stage D flips read flag when oms + storefront are both coordinated. Order-path deduction ships in the same PR as read-path, so flipping read flag doesn't create the drift risk `/review` CEO+Eng both BLOCK'd on.

## Architecture

```
storefront → ProductAvailabilityService.ResolveStock → region_inventory (if row) → sku.stock → product.stock
                                     ↓ fail-closed on DB error
admin UI → RequireProductOwnership + RequireRegionAuthorization → inventory/presale repos → audit_logs
oms → catalog-service /internal/stock/deduct (RegionCode threaded through) → region row + global in same tx
```

## Paired PRs (companion branches)

- wabifair-storefront-web: https://github.com/rippleclio/wabifair-storefront-web/pull/new/feat/per-region-inventory-presale
- wabifair-admin-console: https://github.com/rippleclio/wabifair-admin-console/pull/new/feat/per-region-inventory-presale

Merge order: this repo first (schema + API), then storefront-web + admin-console (both depend on shape).

## Test plan
- [x] `go build ./services/catalog-service/... ./services/order-service/... ./pkg/serviceclient/...` clean
- [x] `go vet ./services/...` clean
- [ ] Apply migrations locally: `./run-migrations.sh`
- [ ] Manual smoke: admin PUT `/admin/cms/products/:id/regions/US/inventory` returns 404 (flag OFF), 200 (flag ON)
- [ ] Manual smoke: storefront `GET /products/:id` with `X-User-Country: US` returns `effective_stock` only when read-path flag ON

## Known follow-ups (deferred per /autoplan §17.7 R9)
- 45 named tests from `/autoplan §17.3 test plan artifact`
- Audit `Before` snapshot on UPSERTs (pre-read SQL)
- Drift monitoring dashboard (`sum(region_inventory.stock) vs product_skus.stock`)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
