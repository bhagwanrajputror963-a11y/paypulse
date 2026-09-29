# Decisions and Trade-offs

## Scope confirmed with the hiring team

Before building, we asked the hiring team to clarify four ambiguous areas of the assignment. Their answers, and what we did with each:

- **Reporting/metrics**: no predefined list required — a focused dashboard with filters/analytics answering reasonable HR-manager questions is sufficient; no NL/LLM query interface needed. We built the dashboard + analytics pages (country/job-title breakdowns, charts) and did not build a query interface.
- **Multi-country currency**: no prescribed approach — local currency, normalized reporting currency, or both are all acceptable, with a fixed/deterministic exchange rate if we convert. We chose **local currency only** (see "Currency stored per employee" below) — no conversion layer, since the doc never asks for a single reporting currency.
- **Authentication**: not required — single HR Manager user/role assumed, no RBAC expected. We built **zero auth** (see "No authentication" below), matching this directly.
- **Salary history**: maintaining current salary only is sufficient — history/raises/audit trail optional. We store only the current salary on the `Employee` record; no history table, no audit trail.

## What we chose and why

### No authentication
Confirmed with the hiring team as out of scope — single HR Manager user/role assumed, no RBAC expected. Adding auth (JWT/Devise) would add complexity without satisfying a stated requirement. In production, this would be the first addition.

### No service layer for CRUD
Employee create/update/delete logic is 3-5 lines each. Extracting to services would be premature abstraction — the controller is already thin with `render_resource` and `set_employee`. The analytics service exists because it has real logic (SQL aggregations, dual-purpose methods).

### Currency stored per employee, not derived — no conversion layer
Each employee record stores its own `currency` field, and salaries are shown in that local currency, never converted. The hiring team confirmed either approach (local-only, normalized, or both) was acceptable, with a fixed/deterministic rate if we converted. We picked local-only because:
- No need for a join or a live/fixed FX table on every query
- The seeder assigns currency from `countries.json` based on country
- Aggregates (min/max/avg) are computed and compared within a country's own currency, which is honest — cross-country averages in a single reporting currency would need a rate table we have no real data for

### No salary history
`Employee` stores only the current `salary` value; updates overwrite it in place. Confirmed with the hiring team that current-salary-only is sufficient — history, raises, and audit trails are optional. Worth adding later if the product needs raise trends or compliance audit trails, but nothing today depends on it.

### `upsert_all` for seeding (skips validations)
The doc says "performance of the script matters." `upsert_all` is ~10x faster than `create!` loops because it generates a single `INSERT … ON CONFLICT DO UPDATE` per batch. We use `unique_by: :index_employees_on_lower_email` so re-running the seeder refreshes existing rows instead of erroring on uniqueness. The tradeoff is no model validations — acceptable because seed data is generated programmatically from known-good sources.

### Hard delete, not soft delete
The doc says "delete employees." We use `destroy` which permanently removes the record. In production, we'd add a `deleted_at` column with `paranoia` gem for audit trails.

### Single `average_by_job_title` endpoint instead of separate "top paying titles"
Originally we had a separate endpoint. We refactored to make `job_title` optional:
- With `job_title` param: returns single average (doc requirement 2b)
- Without `job_title` param: returns all titles ranked by average (doc requirement 2c)

This reduces API surface area and code duplication while serving both use cases.

### CORS allows all origins in development
Set to `*` by default for local development. In production, this should be restricted via the `CORS_ORIGINS` environment variable.

### Seed data is shaped for legible charts, not just realism
Flat `rand(30_000..250_000)` salaries and an even 1,000-employees-per-country split are the "obvious" seed script, but they make every dashboard chart look nearly identical across countries and job titles — hard to eyeball, hard to demo. The seeder now uses a fixed but uneven `COUNTRY_WEIGHTS` headcount split and a per-job-title `JOB_TITLE_SALARY_RANGES` hierarchy (Intern lowest, Director highest) instead. This is a presentation decision, not a business rule — nothing downstream depends on these exact numbers, and both constants are simple hashes to retune.

### Workforce distribution is a stacked bar, not a pie
A pie/donut chart with 10 slices is hard to compare at a glance. A single 100%-stacked horizontal bar with a text legend reads faster, and folding the smallest countries into "Other" past 7 segments keeps the color count sane instead of generating an 8th+ hue.

### Known cleanup opportunity: unused nested analytics controller
`app/controllers/api/v1/analytics/salary_controller.rb` (`Api::V1::Analytics::SalaryController`) duplicates `SalaryAnalyticsController` action-for-action but was never wired into `routes.rb` — an earlier nested-namespace attempt abandoned in favor of the flat controller. It has no test coverage and isn't loaded by any route; safe to delete whenever someone gets to it.

## Performance Considerations

### Query optimization
- `stats_by_country` fetches `MIN, MAX, AVG, COUNT` in one SQL query using `pick()` — verified with a test that asserts exactly 1 database query.
- `average_by_job_title` uses `.group(:job_title).average(:salary)` (single SQL aggregate) plus a Ruby-side `sort_by`. The per-title result set is at most ~10 rows, so in-memory sort is negligible and we avoid raw SQL strings.
- Per-request responses in the analytics controller are cached via `Rails.cache.fetch` with a 10-minute TTL — repeat queries in the same window skip the DB entirely.
- Database indexes cover all analytics and filter query patterns:
  - `country`, `job_title`, `employment_status` — single-column filters
  - `country+job_title` — common group-by pattern
  - `country+job_title+salary` — covering index for aggregate queries (PostgreSQL can satisfy `MIN/MAX/AVG` via index-only scan)
  - `email+country+job_title+employment_status` — covers the list endpoint's full filter combination in one index lookup
  - `LOWER(email)` unique — both enforces case-insensitive uniqueness and serves as the conflict target for seeder `upsert_all`

### Pagination
- Backend caps `per_page` at 100 to prevent memory issues.
- Frontend offers 10/25/50/100 page sizes.
- `render_resource` in ApplicationController handles pagination logic once, reused by all list endpoints.
- **Lazy evaluation** — Kaminari's `.page().per()` chains `LIMIT` and `OFFSET` onto the ActiveRecord::Relation. The full collection is never materialized. Controller passes a Relation (e.g., `Employee.order(:id).by_country(...)`) to `render_resource`, which adds pagination. Only when Rails serializes the response does SQL execute: one `SELECT ... LIMIT 25 OFFSET 0` for the records and one `COUNT(*)` for meta. At most 25 records are loaded, never all 10,000.

### Seeding performance
- 10,000 employees generated per-country (uneven `COUNTRY_WEIGHTS` headcount, India highest at 2,200 down to France at 500) in sub-batches of up to 1,000, each upserted via `upsert_all(unique_by: :index_employees_on_lower_email)` inside its own transaction — one bad sub-batch doesn't roll back the rest, and re-running the seeder refreshes existing rows instead of duplicating them.
- Job title assigned via `i % job_titles.size` against a single `global_index` counter that increments across the whole run (not per country), keeping every generated email unique and every name/title pairing deterministic.
- Per-job-title salary bands defined as the frozen `JOB_TITLE_SALARY_RANGES` constant — a startup check raises if any title in `job_titles.json` is missing a range, instead of silently falling back to a default.
- `Employee.delete_all` is gated to `Rails.env.development?` — safe to run in other environments without wiping real data.
- Completes in under 10 seconds (verified by RSpec performance test).
