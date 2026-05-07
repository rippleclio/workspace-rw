# Wabifair Core Commerce Closure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the four highest-risk gaps in Wabifair's buyer journey so quote, purchase eligibility, payment routing, shipping price, and delivery state are consistent from checkout to receipt.

**Architecture:** Keep `order-service` as the buyer-facing orchestrator. Introduce one canonical quote-calculation path shared by preview, create-order, and payment; enforce region availability in both `cart-service` and `order-service`; read region-aware payment routing from `sys.payment_provider_routing` inside `order-service`; and aggregate shipment/tracking data from fulfillment tables back into the order detail API.

**Tech Stack:** Go, Gin, pgx/PostgreSQL, React 18 + TypeScript, Vitest, API Gateway, existing Wabifair microservices.

---

## File Structure

### Phase 1: Canonical quote and tax consistency

- Create: `wabifair-commerce/db/migrations/000102_add_order_quote_snapshot_columns.up.sql`
  - Responsibility: snapshot order-level tax policy and subtotal values so preview, order creation, and payment all share the same persisted totals.
- Create: `wabifair-commerce/db/migrations/000102_add_order_quote_snapshot_columns.down.sql`
  - Responsibility: rollback for the phase 1 order quote snapshot columns.
- Create: `wabifair-commerce/services/order-service/internal/service/quote_service.go`
  - Responsibility: single quote builder used by preview, create-order, and later shipping-rate integration.
- Create: `wabifair-commerce/services/order-service/internal/service/quote_service_test.go`
  - Responsibility: unit tests for inclusive and exclusive tax, payable totals, and shipping contribution.
- Modify: `wabifair-commerce/services/order-service/internal/model/order.go`
  - Responsibility: add quote-breakdown response fields for preview and persisted order detail reads.
- Modify: `wabifair-commerce/services/order-service/internal/service/order_service.go`
  - Responsibility: stop duplicating money logic; call the canonical quote builder before commit.
- Modify: `wabifair-commerce/services/order-service/internal/service/payment_service.go`
  - Responsibility: charge from the persisted canonical order total only.
- Modify: `wabifair-commerce/services/order-service/internal/repository/order_repository.go`
  - Responsibility: persist quote snapshot fields on `oms.orders` and return them on order detail reads.
- Modify: `wabifair-commerce/services/order-service/internal/service/tax_integration_test.go`
  - Responsibility: prove preview/create/payment totals are identical under real tax-rule scenarios.
- Modify: `wabifair-commerce/services/order-service/internal/handler/order_handler_test.go`
  - Responsibility: validate the expanded preview response shape.
- Modify: `documents/wabifair/test-plans/order-checkout.md`
  - Responsibility: add region-tax checkout test matrix and fail-closed tax scenarios.
- Modify: `documents/wabifair/test-plans/payment.md`
  - Responsibility: add preview-total vs payment-amount consistency checks.

### Phase 2: Region hard gate

- Create: `wabifair-commerce/services/cart-service/internal/repository/region_guard_repository.go`
  - Responsibility: region authorization checks against `mms.merchant_region_authorization` and `pms.product_region_availability`.
- Modify: `wabifair-commerce/services/cart-service/internal/service/cart_service.go`
  - Responsibility: block add-to-cart in unsupported regions instead of relying on display-only checks.
- Modify: `wabifair-commerce/services/cart-service/internal/handler/cart_handler_test.go`
  - Responsibility: verify business errors for unauthorized merchant and unavailable product region.
- Modify: `wabifair-commerce/services/order-service/internal/repository/order_repository.go`
  - Responsibility: enforce the same region gate in `loadItemsByCartIDs` and `loadItemsBySkus`.
- Modify: `wabifair-commerce/services/order-service/internal/repository/order_repository_tx_mock_test.go`
  - Responsibility: regression coverage for direct create-order bypass attempts.
- Modify: `wabifair-commerce/services/order-service/internal/handler/order_handler_test.go`
  - Responsibility: verify create-order returns the correct business error when region gating fails.
- Modify: `wabifair-storefront-web/src/components/layout/CountrySelector.tsx`
  - Responsibility: stop presenting non-purchasable regions as fully sellable once backend gates are active.
- Modify: `documents/wabifair/multi-country-expansion-plan.md`
  - Responsibility: align documented sellable-country scope with the enforced runtime scope.

### Phase 3: Payment architecture unification

- Create: `wabifair-commerce/services/order-service/internal/repository/payment_routing_repository.go`
  - Responsibility: read region-to-provider routing from `sys.payment_provider_routing`.
- Modify: `wabifair-commerce/services/order-service/internal/model/payment.go`
  - Responsibility: keep the existing provider contract but support region-aware provider listing.
- Modify: `wabifair-commerce/services/order-service/internal/payment/factory.go`
  - Responsibility: separate provider capability registration from provider routing.
- Modify: `wabifair-commerce/services/order-service/internal/service/payment_service.go`
  - Responsibility: resolve provider by region and order currency before creating the payment intent.
- Modify: `wabifair-commerce/services/order-service/internal/handler/payment_handler.go`
  - Responsibility: make `GET /payments/providers` return the providers valid for the current buyer region.
- Modify: `wabifair-commerce/services/order-service/internal/handler/payment_handler_test.go`
  - Responsibility: cover provider-list filtering and unsupported-provider rejection.
- Modify: `wabifair-storefront-web/src/services/orderService.ts`
  - Responsibility: add `getPaymentProviders()` and keep `createPayment()` on the gateway path.
- Modify: `wabifair-storefront-web/src/services/__tests__/orderService.test.ts`
  - Responsibility: cover the provider-list API client.
- Modify: `wabifair-storefront-web/src/pages/order/CheckoutPage.tsx`
  - Responsibility: fetch payment providers dynamically instead of hard-coding Stripe.
- Create: `wabifair-storefront-web/src/pages/__tests__/CheckoutPage.test.tsx`
  - Responsibility: verify provider list rendering, default selection, and unsupported-region fallback.
- Modify: `documents/wabifair/test-plans/payment.md`
  - Responsibility: add region-provider matrix coverage.

### Phase 4: Shipping-rate integration and fulfillment closure

- Create: `wabifair-commerce/services/order-service/internal/service/shipping_client.go`
  - Responsibility: backend-to-backend client from `order-service` to `shipping-service`.
- Modify: `wabifair-commerce/services/order-service/internal/config/config.go`
  - Responsibility: add `SHIPPING_SERVICE_BASE_URL` and timeout configuration.
- Modify: `wabifair-commerce/services/order-service/cmd/main.go`
  - Responsibility: wire the shipping client into the order quote path.
- Modify: `wabifair-commerce/services/order-service/internal/service/quote_service.go`
  - Responsibility: replace hard-coded shipping fee rules with a shipping-service quote.
- Modify: `wabifair-commerce/services/shipping-service/internal/router/router.go`
  - Responsibility: keep Shopify routes intact and add a storefront-native quote endpoint.
- Create: `wabifair-commerce/services/shipping-service/internal/handler/storefront_quote_handler.go`
  - Responsibility: accept order quote inputs and return a shipping fee for checkout.
- Create: `wabifair-commerce/services/shipping-service/internal/handler/storefront_quote_handler_test.go`
  - Responsibility: verify the storefront shipping-quote contract without Shopify callback payloads.
- Modify: `wabifair-commerce/services/shipping-service/internal/service/rates_test.go`
  - Responsibility: cover currency, weight, and country routing used by checkout.
- Modify: `wabifair-commerce/services/fulfillment-service/internal/service/clients.go`
  - Responsibility: add internal order-state callbacks for delivered reconciliation.
- Modify: `wabifair-commerce/services/fulfillment-service/internal/service/fulfillment_service.go`
  - Responsibility: trigger order delivered reconciliation when tracking reaches `delivered`.
- Modify: `wabifair-commerce/services/fulfillment-service/internal/service/repository.go`
  - Responsibility: expose shipment status updates needed by order reconciliation.
- Modify: `wabifair-commerce/services/fulfillment-service/internal/service/fulfillment_service_test.go`
  - Responsibility: prove delivery callbacks fire only on valid delivered transitions.
- Modify: `wabifair-commerce/services/order-service/internal/handler/internal_handler.go`
  - Responsibility: add an internal delivered-state endpoint alongside the existing ship endpoint.
- Modify: `wabifair-commerce/services/order-service/internal/router/router.go`
  - Responsibility: register the internal delivered endpoint.
- Modify: `wabifair-commerce/services/order-service/internal/model/order.go`
  - Responsibility: extend order detail with shipment list and tracking timeline fields while keeping legacy top-level `shipping_company` and `tracking_no` fields for compatibility.
- Modify: `wabifair-commerce/services/order-service/internal/repository/order_repository.go`
  - Responsibility: hydrate shipment list, tracking events, and delivered-state aggregation from `oms.fulfillment_shipments` and `oms.fulfillment_tracking_events`.
- Modify: `wabifair-storefront-web/src/types/order.ts`
  - Responsibility: type the new shipment list and tracking-event payloads.
- Modify: `wabifair-storefront-web/src/mocks/data/orders.ts`
  - Responsibility: add shipment collections and tracking events to mock orders.
- Modify: `wabifair-storefront-web/src/mocks/handlers/order.ts`
  - Responsibility: return the expanded order detail payload in mock mode.
- Modify: `wabifair-storefront-web/src/pages/user/UserOrderDetailPage.tsx`
  - Responsibility: render shipment timeline and multi-shipment state instead of only one carrier and one tracking number.
- Create: `wabifair-storefront-web/src/pages/__tests__/UserOrderDetailPage.test.tsx`
  - Responsibility: verify timeline rendering and multi-shipment behavior.
- Modify: `documents/wabifair/yunexpress-fulfillment-integration-20260430.md`
  - Responsibility: document the new delivery reconciliation callback.
- Modify: `documents/wabifair/test-plans/order-checkout.md`
  - Responsibility: add real shipping-rate and tracking-timeline acceptance cases.

## Architecture Locks

- Keep `order-service` as the only buyer-facing order and payment orchestration entrypoint in this project phase.
- Do not make storefront call `payment-adapter` directly in phase 3.
- Do not introduce multi-merchant orders in this plan. Single-merchant-per-order remains the explicit phase boundary.
- In phase 4, expose shipment data through `GET /orders/:id` first. Do not make storefront call fulfillment-service directly for order detail.
- Keep Shopify carrier callback routes in `shipping-service` untouched. Add a second storefront-native contract instead of mutating the callback schema.

## Implementation Sequence

1. Phase 1 first: money correctness is the release gate for everything else.
2. Phase 2 second: once totals are correct, make sure only legally and operationally sellable items can enter cart and order creation.
3. Phase 3 third: move payment-provider selection onto the same region-aware rules the catalog and tax layers already expect.
4. Phase 4 last: replace fake shipping with a real shipping quote, then close the shipment/tracking loop into order detail and delivery state.

## Task 1: Canonical Quote and Tax Consistency

**Migration checklist**

- [x] Add `subtotal_before_tax`, `tax_rate`, `tax_type`, and `tax_is_inclusive` to `oms.orders` in `wabifair-commerce/db/migrations/000102_add_order_quote_snapshot_columns.up.sql`.

```sql
ALTER TABLE oms.orders
  ADD COLUMN IF NOT EXISTS subtotal_before_tax NUMERIC(12,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS tax_rate NUMERIC(5,4) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS tax_type VARCHAR(20) NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS tax_is_inclusive BOOLEAN NOT NULL DEFAULT TRUE;
```

- [x] Drop the same columns in `wabifair-commerce/db/migrations/000102_add_order_quote_snapshot_columns.down.sql`.

**API checklist**

- [x] Extend `OrderPreviewResponse` in `wabifair-commerce/services/order-service/internal/model/order.go` to return:

```json
{
  "subtotal_before_tax": "130000.00",
  "tax_amount": "13000.00",
  "tax_rate": 0.1,
  "tax_type": "Consumption Tax",
  "tax_is_inclusive": false,
  "total_amount": "143000.00"
}
```

- [x] Keep `CreateOrderResponse.total_amount` equal to the same canonical payable total shown in preview.
- [x] Make `payment_service.go` create payment intents from the persisted `oms.orders.total_amount` only.

**Implementation checklist**

- [x] Create `quote_service.go` with one quote builder that accepts item totals, shipping fee, and region tax rule, then returns canonical subtotal, tax, and payable total.
- [x] Change `order_service.go` so preview and create-order both call the canonical quote builder instead of calculating totals in separate paths.
- [x] Make tax lookup fail closed when a region is configured for tax but the rule cannot be loaded or applied.
- [x] Persist the quote snapshot columns in `CommitOrder` and surface them on order detail reads.

**Test checklist**

- [x] Update `tax_calculator_test.go`, `quote_service_test.go`, and `tax_integration_test.go` for inclusive and exclusive tax regions.
- [x] Update `order_handler_test.go` so `/orders/preview` asserts tax fields are returned.
- [x] Run:

```bash
cd wabifair-commerce
go test ./services/order-service/internal/service ./services/order-service/internal/handler ./services/order-service/internal/repository -v
```

**Exit criteria**

- [x] The number shown in preview, the number persisted on the order, and the number charged by payment are identical for CN, JP, SG, and TH test cases.

## Task 2: Region Hard Gate

**Migration checklist**

- [x] No new migration in this phase. Reuse `pms.product_region_availability` and `mms.merchant_region_authorization`.

**API checklist**

- [x] Return stable business errors for unsupported region purchase attempts from both cart and order flows:

```json
{ "message": "order.region_unavailable" }
{ "message": "merchant.region_unauthorized" }
```

- [x] Keep the gateway country source as `X-User-Country`; do not introduce a second country-resolution source.

**Implementation checklist**

- [x] Add a repository-level region guard in `cart-service` and call it before add-to-cart succeeds.
- [x] Join the same region-authorization rules in `order_repository.go` for both `loadItemsByCartIDs` and `loadItemsBySkus`.
- [x] Update `CountrySelector.tsx` so phase-2 storefront copy no longer implies all 15 regions are immediately purchasable.

**Test checklist**

- [x] Extend `cart_handler_test.go` for add-to-cart blocked by merchant-region authorization and product-region availability.
- [x] Extend `order_repository_tx_mock_test.go` and `order_handler_test.go` for direct create-order bypass attempts.
- [x] Run:

```bash
cd wabifair-commerce
go test ./services/cart-service/... ./services/order-service/internal/repository ./services/order-service/internal/handler -v
```

**Exit criteria**

- [x] A product that is display-visible but not authorized for the buyer region cannot be added to cart or ordered through any current buyer API path.

## Task 3: Payment Architecture Unification

**Migration checklist**

- [x] No new migration in this phase. Reuse `sys.payment_provider_routing`.

**API checklist**

- [x] Make `GET /payments/providers` region-aware while keeping the existing payload shape:

```json
{
  "providers": [
    { "name": "stripe", "display_name": "Stripe", "icon": "stripe", "enabled": true }
  ]
}
```

- [x] Keep `POST /payments` on the same gateway route, but reject provider names that are not valid for the buyer region.

**Implementation checklist**

- [x] Add `payment_routing_repository.go` so `order-service` reads `sys.payment_provider_routing` directly.
- [x] Keep provider registration in `factory.go`, but move region selection into `payment_service.go`.
- [x] Add `getPaymentProviders()` in storefront `orderService.ts` and fetch providers in `CheckoutPage.tsx`.
- [x] Keep Stripe as the only active provider where no alternative implementation exists, but stop hard-coding Stripe in the checkout page.

**Implementation note**

- Runtime routing now prefers `sys.payment_provider_routing`, but safely falls back to enabled-and-implemented providers when a region only routes to providers that `order-service` cannot execute yet, such as `omise` or `alipay_cn`.
- `CheckoutPage` only continues into the existing Stripe `client_secret + Elements` flow when the selected provider is actually `stripe`; regions with no available runtime provider now show an explicit fallback notice and disable submission.

**Test checklist**

- [x] Extend `payment_handler_test.go` for region-aware provider lists and invalid-provider rejection.
- [x] Extend storefront `orderService.test.ts` for the new provider-list call.
- [x] Add `CheckoutPage.test.tsx` coverage for dynamic provider rendering.
- [x] Run:

```bash
cd wabifair-commerce
go test ./services/order-service/internal/handler ./services/order-service/internal/service -v
cd ../wabifair-storefront-web
npm run test -- src/services/__tests__/orderService.test.ts src/pages/__tests__/CheckoutPage.test.tsx
```

**Exit criteria**

- [x] Checkout no longer assumes Stripe in code. Provider options are resolved from the buyer region at runtime, even if some regions still return only Stripe in phase 3.

## Task 4: Shipping-Rate Integration and Fulfillment Closure

**Migration checklist**

- [x] Add the shipping-quote prerequisite migration `000103_add_product_shipping_weight_grams` so `pms.products` can carry checkout weight inputs end-to-end.
- [x] No new database migration in this phase. Reuse `oms.fulfillment_shipments`, `oms.fulfillment_tracking_events`, and existing `oms.orders.delivered_at`.

**API checklist**

- [x] Add a storefront-native shipping quote endpoint in `shipping-service`:

```json
POST /api/v1/shiprate/quote
{
  "region_code": "JP",
  "currency": "JPY",
  "items": [
    { "sku_id": 1001, "quantity": 1, "grams": 1200 }
  ]
}
```

```json
{
  "shipping_fee": "2800.00",
  "service_level": "yunexpress_standard"
}
```

- [x] Extend `GET /orders/:id` to include shipment collection and tracking timeline while preserving legacy top-level fields:

```json
{
  "shipping_company": "YunExpress",
  "tracking_no": "YT123456789",
  "shipments": [
    {
      "shipment_id": 12,
      "carrier": "yunexpress",
      "carrier_name": "YunExpress",
      "tracking_no": "YT123456789",
      "status": "in_transit",
      "events": [
        { "status": "picked_up", "description": "Package received", "occurred_at": "2026-05-06T08:30:00Z" }
      ]
    }
  ]
}
```

- [x] Add an internal delivered callback from fulfillment-service to order-service:

```json
POST /api/v1/internal/orders/:id/deliver
{
  "shipment_id": 12,
  "carrier_status": "delivered",
  "delivered_at": "2026-05-08T11:45:00Z"
}
```

**Implementation checklist**

- [x] Replace the hard-coded `10` shipping fee and `199` free-shipping threshold in the buyer checkout path with a `shipping_client.go` call from `order-service` before canonical tax/total recomputation.
- [x] Add a storefront-native shipping quote handler in `shipping-service` without changing the Shopify callback routes.
- [x] Trigger order delivered reconciliation from `fulfillment_service.go` when tracking updates enter `delivered`.
- [x] Read shipment and tracking-event collections in `order_repository.go` and include them in user order detail responses.
- [x] Render shipment timeline in `UserOrderDetailPage.tsx`.
- [x] Add `shipping_weight_grams` to the merchant/admin product entry chain so create/edit flows can persist the grams used by future checkout quotes.

**Implementation note**

- `shipping-service` now exposes `POST /api/v1/shiprate/quote`, picks the cheapest available rate, and returns `{ shipping_fee, service_level }` where `service_level` is the carrier service code.
- `order-service` now loads `shipping_weight_grams` alongside checkout items, calls `shipping_client.go` in both preview and create-order flows, and applies canonical tax/total recalculation after the quoted shipping fee is injected.
- The old hard-coded shipping numbers remain only as repository fallback values when no shipping client is injected in tests; the buyer runtime path now resolves shipping through `shipping-service`.

**Test checklist**

- [x] Add `storefront_quote_handler_test.go` and extend order-service quote-path coverage for checkout shipping calculations.
- [x] Extend `fulfillment_service_test.go` for delivered-callback behavior.
- [x] Extend `UserOrderDetailPage.test.tsx` for shipment timeline rendering.
- [x] Add `productShippingWeight.test.ts` and `pkg/merchantform` coverage for pending-pricing weight validation.
- [x] Run scoped verification for `order-service`, `shipping-service` handler/router, `fulfillment-service`, and storefront shipment/tax-panel tests.

```bash
cd wabifair-commerce
go test ./services/shipping-service/... ./services/fulfillment-service/... ./services/order-service/internal/repository ./services/order-service/internal/handler -v
cd ../wabifair-storefront-web
npm run test -- src/pages/__tests__/UserOrderDetailPage.test.tsx src/components/checkout/__tests__/CheckoutTaxPanel.test.tsx
```

**Exit criteria**

- [x] Checkout uses a real shipping quote in preview and create-order flows.
- [x] Buyer order detail shows shipment timeline data from the fulfillment tables.
- [x] Orders move to delivered state from fulfillment tracking, not only from manual receipt confirmation.

**Verification note**

- `go test ./services/order-service/... -count=1` passes.
- `go test ./services/fulfillment-service/... -count=1` passes.
- `go test ./services/shipping-service/internal/... -count=1` passes.
- `npm run test -- src/pages/__tests__/UserOrderDetailPage.test.tsx src/components/checkout/__tests__/CheckoutTaxPanel.test.tsx` passes.
- `npm run build` in `wabifair-storefront-web` passes.

## Rollout Notes

- Ship each phase independently and keep the previous phase green before starting the next one.
- Phase 1 and phase 2 are release blockers for any market expansion.
- Phase 3 can ship before non-Stripe provider implementations are ready, as long as runtime provider selection is no longer hard-coded.
- Phase 4 should launch only after the shipping quote contract has replay coverage for the current top regions.
