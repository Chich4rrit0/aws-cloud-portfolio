# Project 01 — Task Manager API

Small API used to demonstrate the AWS web-application architecture in this portfolio.

## Local development

From `app`:

```powershell
npm install
npm run dev
```

The local application listens on `http://localhost:3000` by default. Express serves the static frontend from `frontend`, while `/api/*` reaches the API. Set `PORT` only through an environment variable when a different port is needed.

## Verification

```powershell
npm test
Invoke-RestMethod -Uri 'http://localhost:3000/health'
```

Open `http://localhost:3000` in a browser to use the frontend.

## API contract (initial version)

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/health` | Load balancer and operational health check. |
| `GET` | `/api/tasks` | List tasks. |
| `POST` | `/api/tasks` | Create a task. |
| `GET` | `/api/tasks/:taskId` | Get a task. |
| `PATCH` | `/api/tasks/:taskId` | Update one or more task fields. |
| `DELETE` | `/api/tasks/:taskId` | Delete a task. |

Task fields are `title`, optional `description`, and `status` (`todo`, `in_progress`, or `done`).

## Current limitation

Tasks are stored only in memory. They are deliberately lost when the API process restarts. This keeps the first local milestone dependency-free; a repository backed by Amazon RDS for PostgreSQL will replace it in a later phase.

## Security baseline

- No credentials, passwords, connection strings, or AWS configuration are stored in this project.
- Request bodies are parsed with a 16 KB limit.
- The `X-Powered-By` header is disabled.
- Authentication is deferred until the Amazon Cognito phase.
