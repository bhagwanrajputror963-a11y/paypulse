# Testing Strategy & TDD Approach

## Development Cycle

Every backend feature follows a **test → feat** cycle, with a **refactor** step only where duplication actually emerged (not on a schedule):

1. **test** — Write failing specs covering happy path and edge cases. Commit.
2. **feat** — Write the minimum code to pass those specs. Commit.
3. **refactor** — Clean up duplication once it's real, not anticipated. Commit.

## Commit Evolution

The commit history is designed to be read sequentially — each commit builds on the previous one.

### Backend (action-by-action)

```
scaffold Rails 8 API application
add employee model and migration

Employee Listing + Show:
  test → feat (pagination from the start; ApplicationController gains
               render_resource/render_error/pagination helpers here)

Employee Create + Update:
  test → feat

Employee Delete:
  test → feat

  feat: add composite indexes for country, job title, and status lookups

Search + Filters on Employees Index:
  test → feat (Employee gains by_country / by_job_title / by_status / by_email
               scopes; controller gains filtered_employees)

Salary Stats by Country:
  test → feat

Average Salary by Job Title:
  test → feat

Salary Summary by Country:
  test → feat

  perf: cache analytics endpoints (Rails.cache, 10-minute TTL)

Bulk Employee Seeder:
  test → feat (10,000 records, fixture-driven, upsert_all in batches)

  docs: backend README
```

### Frontend (feature-by-feature)

```
chore: scaffold Next.js 15 frontend with Ant Design and Recharts
feat: API client, layout shell, and navigation
feat: employee listing page with pagination, search, and filters
feat: employee create and edit form with validation
feat: employee detail view page
feat: salary insights dashboard and country analytics with charts
chore: frontend .env example and README
```

### Docs

```
docs: architecture decisions and trade-offs
docs: TDD approach
docs: project README
```

### Follow-up work (same TDD discipline, after the initial build)

```
feat: add average-salary and workforce-distribution charts to dashboard
fix:  prevent country/job-title axis labels from overlapping in bar charts
feat: vary seeded headcount per country for more realistic charts
feat: apply job-title salary hierarchy in employee seeder
chore: track missing scaffold files, ignore next dev's generated docs
```

The last two seeder commits are a good example of the test-first habit holding after the initial build: the headcount-weighting change touched no assertions (existing specs already covered "10,000 total, valid currency per country"), but the job-title salary hierarchy change shipped with two new specs — one asserting every salary falls inside its title's configured range, one asserting the Director > Manager > Engineer > Intern ordering — before the ranges were wired into the seeder.

## What We Test

- **Model specs** — validations, enum definition, email normalization callback, `by_country` scope.
- **Request specs** — full HTTP cycle for every endpoint (happy path, validation errors, 404s, missing params, exact-email filter, filter combinations, pagination).
- **Service specs** — analytics logic with edge cases (single employee, empty country, decimal precision, single-query assertion).
- **Seeder specs** — correctness (count, name sources, currency mapping, job titles), dev-only `delete_all` behavior, per-title salary range and hierarchy, performance (<10s).

## What We Don't Test

- Controllers in isolation (request specs cover the full stack).
- Frontend components (would require Jest + Testing Library — deferred for scope).
- Authentication (not implemented).

## Test Characteristics

- **Fast** — 66 examples run in under 10 seconds, including the seeder performance test that generates and inserts all 10,000 records.
- **Deterministic** — no random data in assertions; factory-generated test data; fixed timestamps.
- **Independent** — each test creates its own data, transactional rollback between tests, no shared state.
- **Shared helpers** — `let(:body) { JSON.parse(response.body) }` and `let(:headers) { { 'CONTENT_TYPE' => 'application/json' } }` used across request specs for readability.

Run the suite:
```bash
cd backend
bundle exec rspec
```
