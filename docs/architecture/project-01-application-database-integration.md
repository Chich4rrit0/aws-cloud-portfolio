# Project 01 — Application to PostgreSQL integration

## Storage modes

The Task Manager has a storage boundary so the HTTP API is independent of its persistence mechanism.

- `TASK_STORE=memory` is the default for local development and automated tests. Data is intentionally lost when the process stops.
- `TASK_STORE=postgres` enables PostgreSQL only when every database setting is supplied explicitly.

The API routes remain unchanged in either mode: create, list, read, update and delete tasks.

## Database configuration

The PostgreSQL adapter reads these values only from the process environment:

| Variable | Purpose |
| --- | --- |
| `DB_HOST` | Private RDS endpoint |
| `DB_PORT` | PostgreSQL TCP port; defaults to 5432 |
| `DB_NAME` | `taskmanager` database |
| `DB_USER` | Future least-privilege `taskmanager_app` login |
| `DB_PASSWORD` | Retrieved at runtime from Parameter Store; never committed |
| `DB_SSL_CA_PATH` | Local path to the trusted RDS CA bundle |

TLS certificate validation is enabled by default in PostgreSQL mode. Disabling TLS requires the explicit local-only setting `DB_SSL=false`; it is not the deployment configuration.

## Security boundary still to implement

The current RDS master password was used only to provision the database. It must not be used by the running application. Before the first EC2 deployment we will:

1. Create a dedicated `taskmanager_app` PostgreSQL login with only the required privileges in the `taskmanager` database.
2. Store that application's password in its own SecureString parameter.
3. Narrow the EC2 role to that application-password parameter and remove access to the master-password parameter.
4. Connect the application through TLS using the RDS CA bundle.

This order avoids converting the RDS master account into a long-lived application credential.
