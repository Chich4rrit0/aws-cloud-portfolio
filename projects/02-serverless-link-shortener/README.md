# Project 02 — Serverless Link Shortener

Aplicación serverless para acortar enlaces personales. Complementa el Proyecto 1 demostrando cuándo una carga pequeña o irregular no necesita servidores, balanceadores ni una base de datos relacional administrada.

## Estado

**Blueprint aprobado; bootstrap local en curso.** No existen recursos AWS de Project 02, código desplegado, credenciales, endpoints ni datos persistidos.

## Alcance aprobado

| Ruta | Acceso | Propósito |
| --- | --- | --- |
| `GET /r/{code}` | Público | Redirige a un enlace previamente creado. |
| `POST /urls` | Cognito JWT | Crea un enlace corto para el usuario autenticado. |
| `DELETE /urls/{code}` | Cognito JWT | Elimina un enlace que pertenece al usuario autenticado. |

La primera versión no tendrá frontend AWS. La administración se validará mediante pruebas API; una interfaz estática será una mejora posterior solo si añade valor al portafolio.

## Arquitectura aprobada

```mermaid
flowchart LR
    Viewer((Viewer)) -->|GET /r/{code}| API[API Gateway HTTP API]
    Admin((Authenticated user)) -->|POST /urls\nDELETE /urls/{code}| Cognito[Cognito JWT authorizer]
    Cognito --> API
    API --> Lambda[Lambda]
    Lambda --> DDB[(DynamoDB on-demand)]
    Lambda --> Logs[CloudWatch Logs]
```

- Región propuesta y aprobada para el proyecto: `us-east-1`.
- API Gateway HTTP API, Lambda y DynamoDB On-Demand.
- Sin VPC, NAT Gateway, EC2, ALB, RDS ni CloudFront en la primera versión.
- DynamoDB usará escrituras condicionales para evitar colisiones y tendrá TTL opcional.
- CloudWatch Logs tendrá retención corta; no se habilitan dashboards, tracing ni access logs inicialmente.

## Principios operativos

1. No crear recursos AWS sin explicación, costo aproximado, estrategia de limpieza y aprobación explícita.
2. No guardar JWTs, contraseñas, Access Keys ni endpoints privados en Git.
3. Usar IAM de mínimo privilegio: Lambda solo accederá a la tabla y log group necesarios.
4. Validar primero localmente y luego por API; eliminar datos de prueba.
5. Mantener la capa pública mínima: solo el redirect; crear y eliminar enlaces exige JWT.

## Documentación

- [Blueprint técnico](docs/architecture/serverless-blueprint.md)
- [Modelo DynamoDB](docs/architecture/dynamodb-data-model.md)
- [Contrato HTTP](docs/architecture/http-api-contract.md)
- [Controles de abuso](docs/architecture/abuse-controls.md)
- [Preflight de despliegue](docs/architecture/deployment-preflight.md)
- [ADRs](docs/decisions/)
- [Cost Checks](docs/cost-checks/)
- [Guía de screenshots](docs/screenshots/README.md)

## Próximo paso

Revisar y aprobar el preflight de despliegue y su Cost Check. Solo después se solicitará autorización explícita para crear cada recurso AWS.
