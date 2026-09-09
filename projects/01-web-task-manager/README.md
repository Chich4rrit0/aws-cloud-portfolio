# Project 01 — Task Manager

Aplicación mínima que sirve como carga de trabajo para la arquitectura web AWS del portafolio. Implementa CRUD de tareas y un health check; la complejidad de negocio se mantiene deliberadamente acotada.

## Desarrollo local

```powershell
Set-Location .\app
npm ci
npm test
npm run dev
```

La aplicación escucha en `http://localhost:3000`. Express sirve el frontend estático y expone la API bajo `/api/*`.

## Verificación local

```powershell
npm test
Invoke-RestMethod -Uri 'http://localhost:3000/health'
```

Open `http://localhost:3000` in a browser to use the frontend.

## Contrato API

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/health` | Health check operacional. |
| `GET` | `/api/tasks` | Lista tareas. |
| `POST` | `/api/tasks` | Crea una tarea. |
| `GET` | `/api/tasks/:taskId` | Obtiene una tarea. |
| `PATCH` | `/api/tasks/:taskId` | Edita una tarea. |
| `DELETE` | `/api/tasks/:taskId` | Elimina una tarea. |

Task fields are `title`, optional `description`, and `status` (`todo`, `in_progress`, or `done`).

## Persistencia

- Local: `TASK_STORE=memory` es intencional y efímero.
- Despliegue AWS: `TASK_STORE=postgres`; la API conecta a RDS PostgreSQL con TLS.

Las credenciales no existen en archivos del proyecto. La instancia EC2 recupera el secreto de aplicación desde Parameter Store al iniciar el servicio.

## Baseline de seguridad

- No se guardan credenciales, contraseñas, connection strings ni configuración AWS en Git.
- Request bodies se limitan a 16 KB y `X-Powered-By` está desactivado.
- No hay autenticación de usuarios en esta versión; Cognito es una evolución planificada.

## Validación desplegada

Desde la raíz del repositorio, `Test-Project01CloudFrontDelivery.ps1` valida HTTPS, health y CRUD contra CloudFront; elimina la tarea temporal creada para la prueba.
