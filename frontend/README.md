# PayPulse Frontend

Salary management UI for HR managers. Built with Next.js 15, Ant Design, and Recharts.

## Setup

```bash
cp .env.example .env.local
npm install
```

## Running

```bash
npm run dev    # starts on http://localhost:3001
```

Backend must be running on `http://localhost:3000`.

## Pages

- `/employees` — Paginated employee table with filters (exact email, country, job title, status), plus create/edit/delete
- `/employees/:id` — Employee detail view
- `/analytics` — Salary insights dashboard (stats by country, averages by job title, country summary)

## Tech Stack

- Next.js 15.5 (App Router)
- React 19
- TypeScript
- Ant Design 6
- Recharts
- Axios (with a response interceptor that unwraps the `{ success, data, meta }` envelope)

## Structure

```
src/
├── app/                 Pages (App Router)
├── components/          EmployeeTable, EmployeeForm, AppShell, Loader
├── hooks/               useEmployees (with filters), useEmployee, useSalaryInsights
├── services/            employeesApi, analyticsApi
├── types/               Shared TypeScript interfaces
├── constants/           Routes, API paths, countries, job titles, statuses
├── lib/                 Axios instance + response interceptor
└── styles/              Global CSS
```
