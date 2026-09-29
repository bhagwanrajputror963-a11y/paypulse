# Requirements — PayPulse Salary Management Tool

## Problem

An HR Manager needs a tool to manage employee compensation data and answer basic pay questions (by country, by job title, across the org) without a predefined report list or a natural-language query interface.

## In scope

**Employee management**
- Create, view, update, delete employee records via UI
- Paginated, filterable employee listing (country, job title, employment status)
- Employee detail view

**Salary insights**
- Min / max / average salary by country
- Average salary by job title (org-wide, or filtered to one country)
- Salary summary across all countries in each country's local currency
- Dashboard charts: average salary by country, headcount/workforce distribution by country

**Data**
- 10,000 seeded employees across 10 countries and 10 job titles, generated in batches, each with its own local currency

## Explicitly out of scope (and why)

| Feature | Decision | Reasoning |
|---|---|---|
| Authentication / RBAC | Not built | Confirmed with hiring team: single HR Manager user assumed, no login or role model required for this assessment |
| Natural-language / LLM query interface | Not built | Confirmed with hiring team: a focused dashboard with filters answers reasonable questions; NL querying isn't required |
| Currency conversion / single reporting currency | Not built | Confirmed acceptable to keep salaries in local currency only; no FX rate table exists to convert honestly, so aggregates stay within each currency |
| Salary history, raises, audit trail | Not built | Confirmed current-salary-only is sufficient; `Employee.salary` is overwritten in place on update, no history table |
| Soft delete | Not built | Delete is a hard `destroy`; a `deleted_at` + audit trail is a reasonable production follow-up, not required here |
| Service-layer for CRUD | Not built | Employee create/update/delete is 3–5 lines each — extracting to a service would be premature abstraction |

Full reasoning for each of these, plus other implementation trade-offs (indexing, caching, pagination, seeding strategy), is in [decisions.md](decisions.md).

## Tech stack

- Backend: Ruby 3.4 / Rails 8.1 (API-only), PostgreSQL
- Frontend: Next.js 16 / React 19, Ant Design, Recharts
- Local dev: Docker Compose (Postgres + backend + frontend), or native Ruby/Node

## Non-functional targets

- Seed script completes in under 10 seconds for 10,000 records
- List/analytics endpoints answer from indexed queries, most under 20ms; analytics responses cached 10 minutes
- 66 backend RSpec examples covering models, services, seeders, and request specs
