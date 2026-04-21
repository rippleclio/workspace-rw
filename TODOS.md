# TODOS

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
