# PayPulse Backend

Salary management API for HR managers. Built with Ruby 3.3 + Rails 8.0 (API-only) + PostgreSQL.

## Prerequisites

- Ruby 3.3.0
- PostgreSQL 14+
- Bundler

## Setup

```bash
cp .env.example .env
bundle install
rails db:create db:migrate
rails db:seed              # seeds 10,000 employees
```

## Running

```bash
rails server               # starts on http://localhost:3000
```

## Tests

```bash
bundle exec rspec                                          # full suite (includes slow seeder test)
bundle exec rspec --exclude-pattern "**/employee_seeder*"  # fast tests (~2s)
bundle exec rspec spec/models/                             # model specs
bundle exec rspec spec/requests/                           # API specs
bundle exec rspec spec/services/                           # service specs
```

## API Endpoints

### Employees

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/employees` | List employees (paginated, filterable) |
| GET | `/api/v1/employees/:id` | Show employee |
| POST | `/api/v1/employees` | Create employee |
| PATCH | `/api/v1/employees/:id` | Update employee |
| DELETE | `/api/v1/employees/:id` | Delete employee |

Listing supports optional query params: `page`, `per_page` (capped at 100), `email` (exact match, case-normalized), `country`, `job_title`, `employment_status`.

### Analytics

| Method | Path | Params |
|--------|------|--------|
| GET | `/api/v1/analytics/salary_stats` | `country` (required) — returns min / max / average / count |
| GET | `/api/v1/analytics/salary_by_job_title` | `country` (required), `job_title` (optional) — returns `{ average, titles }`; `titles` is always present, `average` is populated when `job_title` is passed |
| GET | `/api/v1/analytics/salary_summary_by_country` | — — returns count + average salary grouped by country |

All analytics responses are cached via `Rails.cache.fetch` with a 10-minute TTL.

### Response envelope

Every response uses a uniform envelope:

```json
{ "success": true, "data": { ... }, "meta": { ... } }   // meta only on paginated
{ "success": false, "error": "message" }                 // single error
{ "success": false, "errors": ["...", "..."] }           // validation errors
```

## Architecture

```
app/
├── controllers/
│   ├── application_controller.rb      # render_resource, render_error, clamp_per_page, rescues
│   └── api/v1/
│       ├── employees_controller.rb
│       └── salary_analytics_controller.rb
├── models/
│   └── employee.rb                    # enum employment_status, scopes, validations
└── services/
    └── salary_analytics_service.rb

db/
├── seeders/
│   └── employee_seeder.rb             # cycle-based, dev-gated delete_all, batched upsert_all, inline SALARY_RANGES bands
└── data/fixtures/
    ├── countries.json                 # name + currency
    ├── job_titles.json
    ├── first_names.txt
    └── last_names.txt
```

- Controllers are thin; use shared helpers from `ApplicationController`.
- Analytics use single-query SQL aggregations (`pick()` + `group/average`).
- Seeder cycles through `country × job_title` combinations via `Array#cycle`, uses `upsert_all(unique_by: :index_employees_on_lower_email)` for idempotent re-seeding, and gates `delete_all` to `Rails.env.development?`.
