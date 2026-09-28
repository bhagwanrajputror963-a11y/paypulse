# Architecture Decisions

## System Diagrams

### High-Level Structure

```mermaid
flowchart LR
    User[HR Manager]

    subgraph Frontend[Next.js 15 Frontend]
        Pages[App Router pages<br/>employees · analytics]
        Hooks[hooks<br/>useEmployees · useEmployee<br/>useSalaryInsights]
        Services[services<br/>employeesApi · analyticsApi]
    end

    subgraph Backend[Rails 8 API]
        EmpCtrl[EmployeesController]
        AnCtrl[SalaryAnalyticsController]
        AppCtrl[ApplicationController<br/>render_resource · render_error<br/>pagination · error rescue]
        Model[Employee model<br/>validations + normalize_email]
        Svc[SalaryAnalyticsService<br/>pick + group aggregations]
    end

    Cache[(Rails.cache<br/>10 min TTL)]
    DB[("PostgreSQL<br/>employees<br/>indexes: country · job_title · country+job_title · country+job_title+salary · employment_status")]

    User --> Pages
    Pages --> Hooks
    Hooks --> Services
    Services -->|HTTP/JSON| EmpCtrl
    Services -->|HTTP/JSON| AnCtrl
    EmpCtrl --- AppCtrl
    AnCtrl --- AppCtrl
    EmpCtrl --> Model
    AnCtrl --> Svc
    AnCtrl <--> Cache
    Model --> DB
    Svc --> DB
```

### Salary Analytics Request Flow

```mermaid
sequenceDiagram
    participant FE as Frontend (analytics page)
    participant Ctrl as SalaryAnalyticsController
    participant Cache as Rails.cache
    participant Svc as SalaryAnalyticsService
    participant DB as PostgreSQL

    Note over FE,Ctrl: Step 1 — Validate request
    FE->>Ctrl: GET /api/v1/analytics/salary_stats?country=India
    Ctrl->>Ctrl: before_action require_param!(:country)

    Note over Ctrl,Cache: Step 2 — Cache lookup (10 min TTL)
    Ctrl->>Cache: fetch("salary_stats/India")

    alt cache hit
        Cache-->>Ctrl: cached payload
    else cache miss
        Note over Ctrl,DB: Step 3 — Compute aggregates
        Ctrl->>Svc: stats_by_country("India")
        Svc->>DB: SELECT MIN, MAX, AVG, COUNT (single query via pick)
        DB-->>Svc: aggregated row
        Svc-->>Ctrl: { min, max, average, count }
        Ctrl->>Cache: write payload
    end

    Ctrl-->>FE: render_resource(result)
```

### Employee Create Flow

```mermaid
sequenceDiagram
    participant FE as Frontend (EmployeeForm)
    participant Ctrl as EmployeesController
    participant App as ApplicationController
    participant Model as Employee
    participant DB as PostgreSQL

    FE->>Ctrl: POST /api/v1/employees
    Ctrl->>Ctrl: employee_params (strong params)
    Ctrl->>Model: Employee.new(params)
    Model->>Model: before_validation normalize_email
    Model->>Model: validate presence, uniqueness, format, salary > 0

    alt valid
        Model->>DB: INSERT
        DB-->>Model: ok
        Ctrl->>App: render_employee(employee, status: :created)
        App-->>FE: 201 { success: true, data: { employee: {...} } }
    else invalid
        Ctrl->>App: render_validation_errors(errors.full_messages)
        App-->>FE: 422 { success: false, errors: [...] }
    end
```

### Employee Listing (paginated)

```mermaid
sequenceDiagram
    participant FE as Frontend (EmployeeTable)
    participant Ctrl as EmployeesController
    participant App as ApplicationController
    participant DB as PostgreSQL

    FE->>Ctrl: GET /api/v1/employees?page=2&per_page=25&country=India&email=…
    Ctrl->>Ctrl: filtered_employees (chains by_email / by_country / by_job_title / by_status)
    Ctrl->>App: render_resource(filtered_employees, key: :employees, paginate: true)
    App->>App: clamp_per_page (1..100)
    App->>DB: SELECT … LIMIT 25 OFFSET 25 (lazy via Kaminari)
    DB-->>App: 25 rows + total count
    App-->>FE: { success: true, data: { employees: [...] }, meta: { total_count, total_pages, current_page, per_page } }
```

## Backend Architecture

### Why Rails API-only
- The doc requires a backend with a relational database. Rails provides convention-over-configuration which accelerates development while maintaining structure.
- API-only mode strips unnecessary middleware (sessions, cookies, views) keeping the stack lean.

### Why PostgreSQL
- Required salary aggregations (MIN, MAX, AVG, COUNT) are handled efficiently at the database level.
- `LOWER(email)` unique index ensures case-insensitive email uniqueness at the DB level, not just Rails validation.
- CHECK constraints (`salary > 0`) provide defense-in-depth beyond application-layer validation.

### Controller Design
- Controllers are thin — they handle request/response only.
- A shared `render_resource` helper in `ApplicationController` handles both single-record and paginated responses, wrapping every payload in a `{ success, data, meta? }` envelope.
- A dedicated `render_employee` wrapper in `EmployeesController` avoids repeating `key: :employee` at every call site.
- `before_action :set_employee` extracts record lookup for show/update/destroy.
- A lambda `before_action -> { require_param!(:country) }` in `SalaryAnalyticsController` centralizes required-param validation.
- `filtered_employees` private method chains the `by_email` (exact match), `by_country`, `by_job_title`, `by_status` model scopes only when the matching params are present.

### Service Layer
- `SalaryAnalyticsService` encapsulates all salary aggregation logic with optimized SQL queries.
- `stats_by_country` uses `pick()` to fetch `MIN, MAX, AVG, COUNT` in a single query instead of 4 separate calls.
- `average_by_job_title` returns a unified `{ average, titles }` shape. `titles` is the full per-title ranking (computed via `.group(:job_title).average(:salary)` + Ruby-side sort); `average` is the scalar for the requested title (found in the `titles` list, no second query).

### Seeding Strategy
- Seed logic lives in `db/seeders/employee_seeder.rb`, not in `app/services/` — it's a data loading concern, not business logic.
- Fixture data (countries, job titles, first/last names) lives in `db/data/fixtures/` for easy modification without code changes.
- Headcount per country is **uneven** — a frozen `COUNTRY_WEIGHTS` hash (India 2,200 down to France 500, summing to `TOTAL`) instead of a flat 1,000/country split. A guard raises at boot if the weights ever drift from `TOTAL`. This exists purely so the dashboard's headcount and workforce-distribution charts show real variation instead of ten identical bars.
- Salary is **tiered by job title**, not one flat `rand` range for everyone — a frozen `JOB_TITLE_SALARY_RANGES` hash (Intern $20k–40k up to Director $150k–250k) so "Average Salary by Job Title" reads as a real hierarchy. A guard raises if `job_titles.json` ever adds a title with no configured range.
- Employees are generated per-country in `BATCH_SIZE` (1,000) sub-batches — a country's headcount doesn't have to be a multiple of 1,000, so the last sub-batch for a country can be smaller.
- A single `global_index` counter increments across the whole run (not reset per country/batch) so every generated email (`employee_#{i}@paypulse.com`) stays unique and every first/last name pair is still deterministic via `i % fn_size` / `i % ln_size`.
- `upsert_all(unique_by: :index_employees_on_lower_email)` per sub-batch within a transaction — re-running the seeder updates existing rows instead of duplicating them. Completes in under 10 seconds.
- `Employee.delete_all` is gated to `Rails.env.development?` — other environments upsert without wiping.
- Frozen constants (`DATA_PATH`, `COUNTRY_WEIGHTS`, `JOB_TITLE_SALARY_RANGES`) guard against accidental mutation.

## Frontend Architecture

### Why Next.js 15 + Ant Design
- Next.js provides App Router with file-based routing — maps cleanly to the two main pages (employees, analytics).
- Ant Design provides production-ready components (Table with pagination, Form with validation, Modal, Select, Statistic cards) out of the box.
- Recharts for salary visualizations — lightweight and composable.

### Project Structure
```
src/
├── app/            Pages (dashboard, employees, employees/[id], analytics)
├── components/     AppShell, EmployeeTable, EmployeeForm, Loader
├── hooks/          useEmployees, useEmployee, useSalaryInsights
├── services/       employeesApi, analyticsApi
├── types/          Shared TypeScript interfaces (Employee, EmployeeFilters, PaginationMeta, …)
├── constants/      Routes, API paths, countries, job titles, employment statuses, chart palette
├── lib/            Axios instance + response interceptor (unwraps the envelope)
└── styles/         Global CSS
```

### Key Decisions
- Types extracted into `src/types/` — single source of truth for Employee, EmployeeFilters, PaginationMeta, SalaryStats, etc.
- `useEmployees` hook encapsulates fetch logic with `page`, `per_page`, and optional filters (`email`, `country`, `job_title`, `employment_status`).
- `EmployeeTable` is a presentational component — receives data and callbacks, no internal state.
- `EmployeeForm` auto-maps country to currency using a shared `COUNTRY_CURRENCY` constant.
- Fixed sidebar with sticky page headers — only content area scrolls.
- Per-page size changer (10/25/50/100) + exact-email input + 3 filter selects (country / job title / status) wired end-to-end from UI to API.
- `lib/api.ts` installs an axios response interceptor that unwraps `{ success, data, meta }` so services and hooks see the inner payload directly.
- Country/job-title bar-chart axes use `angle={-35}` + `interval={0}` so all 10 labels stay legible instead of overlapping or getting skipped.

### Dashboard Charts
`useSalarySummary()` fetches `salary_summary_by_country` once and feeds three views of the same data — no extra network calls:
- **Headcount by Country** — single-hue bar chart, one query, no restyle needed since it's plain magnitude.
- **Average Salary by Country** — a second single-hue bar chart (teal, `--brand-primary`) so it reads as a distinct chart from Headcount rather than a repaint of it; tooltip formats each bar in that country's own currency via `COUNTRY_CURRENCY`.
- **Workforce Distribution by Country** — a single 100%-stacked horizontal bar instead of a pie chart (part-to-whole data reads more reliably as a stacked bar than as wedge angles). Countries beyond the top 7 fold into a grey "Other" segment rather than adding an 8th+ hue. Colors come from `CHART_CATEGORICAL_COLORS`, a fixed-order, CVD-validated 7-hue palette (`src/constants/index.ts`); "Other" uses a separate muted grey (`CHART_OTHER_COLOR`) so it never collides with a real country's color. A text legend beneath the bar gives every segment a labeled percentage, since color alone shouldn't carry identity for 7+ series.

## Database Design

```
employees
├── full_name         (string, NOT NULL)
├── email             (string, NOT NULL, LOWER unique index)
├── job_title         (string, NOT NULL, indexed)
├── country           (string, NOT NULL, indexed)
├── salary            (decimal 10,2, NOT NULL, CHECK > 0)
├── currency          (string, default "USD")
├── employment_status (string, NOT NULL, default "active", indexed, enum)
├── date_of_joining   (date)

Indexes: country · job_title · country+job_title · country+job_title+salary · email+country+job_title+employment_status · employment_status · LOWER(email) unique
```

### Why these indexes
- `country` — every analytics query filters by country.
- `job_title` — `by_job_title` filter when country is not specified (leftmost-prefix rule means the composite can't serve this query).
- `country+job_title` — composite index covers the `average_by_job_title` group-by pattern.
- `country+job_title+salary` — covering index for aggregate queries; PostgreSQL can satisfy MIN/MAX/AVG via an index-only scan without touching the heap.
- `email+country+job_title+employment_status` — covers the list endpoint's full filter combination (exact email + filters) in a single index lookup.
- `employment_status` — HR managers frequently filter by status.
- `LOWER(email)` unique — case-insensitive email uniqueness enforced at the DB; also used as the conflict target for `upsert_all` in the seeder.

## API Design

Three endpoint groups with consistent patterns:
- **Employees CRUD** — standard REST. Payload keyed by resource name (`employee` / `employees`) inside the envelope. Listing accepts `page`, `per_page`, `email` (exact match), `country`, `job_title`, `employment_status`.
- **Analytics** — read-only endpoints returning aggregated data. `salary_by_job_title` always returns `{ average, titles }`; the `average` scalar is populated only when `job_title` is passed. All analytics responses cached via `Rails.cache.fetch` (10-minute TTL).
- **Error handling** — centralized in `ApplicationController` with `StandardError → 500`, `RecordNotFound → 404`, `ParameterMissing → 400`.

### Response envelope

Every response follows the same shape so the frontend can parse uniformly.

Success (single / analytics):
```json
{ "success": true, "data": { "employee": { ... } } }
```

Success (paginated):
```json
{
  "success": true,
  "data": { "employees": [ ... ] },
  "meta": { "total_count": 128, "total_pages": 6, "current_page": 1, "per_page": 25 }
}
```

Validation errors (array):
```json
{ "success": false, "errors": ["Email has already been taken", "Salary must be greater than 0"] }
```

Single error (param missing, not found, server error):
```json
{ "success": false, "error": "country param is required" }
```

The frontend `lib/api.ts` installs an axios response interceptor that unwraps `{ success, data, meta }` so downstream services and hooks see the inner payload directly (plus a lifted `meta` for paginated responses).
