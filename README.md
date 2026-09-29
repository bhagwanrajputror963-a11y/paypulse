# PayPulse — Salary Management Tool

A minimal yet practical salary management system for organizations, designed to help HR Managers manage employee compensation efficiently.

## Monorepo Structure

```
paypulse/
├── backend/            Ruby 3.4 + Rails 8.1 API with PostgreSQL
├── frontend/           Next.js 16 + React 19 + Ant Design + Recharts
├── docs/               Architecture decisions and planning artifacts
└── docker-compose.yml  One-command local stack (Postgres + backend + frontend)
```

## Quick Start

### Option A — Docker (recommended, no local Ruby/Node/Postgres needed)
```bash
docker compose up --build
```
- Backend: [http://localhost:3000](http://localhost:3000) — migrates and seeds 10,000 employees on startup
- Frontend: [http://localhost:3001](http://localhost:3001)
- Postgres: exposed on host port `5433` (container-internal `5432`, to avoid clashing with a local Postgres install) — `psql -h localhost -p 5433 -U postgres -d paypulse_development` (password `postgres`)

Run the backend test suite against the running stack:
```bash
docker compose exec -e RAILS_ENV=test backend bash -c "bundle exec rails db:create db:migrate && bundle exec rspec"
```

Stop everything (add `-v` to also drop the Postgres volume and reseed from scratch next time):
```bash
docker compose down
```

### Option B — Run natively
#### Backend
```bash
cd backend
cp .env.example .env
bundle install
rails db:create db:migrate db:seed
rails server                    # http://localhost:3000
```

#### Frontend
```bash
cd frontend
cp .env.example .env.local
npm install
npm run dev                     # http://localhost:3001
```

#### Tests
```bash
cd backend
bundle exec rspec               # 66 specs, all passing
```

## Documentation

Component READMEs:
- [Backend README](backend/README.md) — Rails API setup, env vars, testing, DB seeding
- [Frontend README](frontend/README.md) — Next.js setup, env vars, running the UI

Design and planning:
- [Architecture](docs/architecture.md) — system diagrams, backend/frontend design, DB schema, API envelope
- [Decisions](docs/decisions.md) — trade-offs taken, what was deferred, performance considerations
- [Testing Strategy](docs/testing-strategy.md) — TDD approach, the commit-by-commit test→feat narrative, what's covered

## Features

### Employee Management
- Add, view, update, delete employees via UI
- Paginated employee listing with configurable page size
- Employee detail view page

### Salary Insights
- Min, max, average salary by country
- Average salary by job title in a country (with/without filter)
- Salary summary across all countries with local currency
- Interactive bar chart for salary comparison

### Seeding
- 10,000 employees generated from first_names.txt and last_names.txt
- Country-specific currency assignment
- Bulk insert in batches of 1,000 within a transaction
- Completes in under 10 seconds
