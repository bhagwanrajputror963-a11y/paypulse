# PayPulse — Salary Management Tool

A minimal yet practical salary management system for organizations, designed to help HR Managers manage employee compensation efficiently.

## Monorepo Structure

```
paypulse/
├── backend/    Ruby 3.3 + Rails 8.0 API with PostgreSQL
├── frontend/   Next.js 15 + React 19 + Ant Design + Recharts
└── docs/       Architecture decisions and planning artifacts
```

## Quick Start
### Backend
```bash
cd backend
cp .env.example .env
bundle install
rails db:create db:migrate db:seed
rails server                    # http://localhost:3000
```

### Frontend
```bash
cd frontend
cp .env.example .env.local
npm install
npm run dev                     # http://localhost:3001
```

### Tests
```bash
cd backend
bundle exec rspec               # 64 specs, all passing
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
