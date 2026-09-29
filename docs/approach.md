# Approach — PayPulse Salary Management Tool

How this assessment was tackled, end to end. For *what* was built and *why* specific calls were made, see [requirements.md](requirements.md) and [decisions.md](decisions.md); this doc covers the *process*.

## 1. Clarify before building

The assignment left four areas ambiguous (reporting scope, multi-currency handling, auth, salary history). Rather than guess, we raised them with the hiring team up front and built to their answers — see "Scope confirmed with the hiring team" in [decisions.md](decisions.md). This kept the build focused: no auth system, no FX conversion layer, no history table, no NL query interface — all deliberate omissions, not gaps.

## 2. Build in vertical, test-first slices

Each feature (listing, create, update, delete, filters, salary-stats-by-country, average-by-job-title, seeding) went through the same **test → feat → refactor** cycle end to end before moving to the next, with a commit at each step. Refactoring happened only when duplication actually showed up (e.g. composite indexes added once real filter/analytics query patterns existed), not preemptively. Full breakdown in [testing-strategy.md](testing-strategy.md).

Order of work: data model → CRUD → filtering/pagination → analytics endpoints → seeding at realistic volume (10k records) → frontend (employee UI, then dashboard/analytics UI) → Docker packaging for one-command local run.

## 3. Design for the actual query patterns, not in the abstract

Indexes, caching (10-minute TTL on analytics), and the response envelope shape were added in response to the queries the controllers/service actually issued, verified with N+1 assertions in specs rather than assumed. Architecture and request-flow diagrams: [architecture.md](architecture.md).

## 4. Make it runnable, not just reviewable

Docker Compose brings up Postgres + backend + frontend with one command, migrating and seeding on startup, so the assessment can be evaluated without local Ruby/Node/Postgres setup.

## Result

- 66 backend RSpec examples (models, services, seeders, request specs), all passing
- Indexed, cached analytics endpoints; sub-20ms for most list/analytics queries
- 10,000 seeded employees across 10 countries / 10 job titles with realistic, non-uniform distribution
- Every out-of-scope item is a documented, confirmed decision rather than an oversight
