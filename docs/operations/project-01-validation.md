# Runbook — Project 01 validation

## Validaciones no destructivas

| Objetivo | Script | Resultado esperado |
| --- | --- | --- |
| Contexto AWS local | `Test-AwsPortfolioPreflight.ps1` | Región acordada, sesión válida y advertencia si se usa root. |
| API interna y PostgreSQL | `Test-Project01ApplicationDeployment.ps1` | `/health` y CRUD local vía Session Manager. |
| Observabilidad | `Test-Project01Observability.ps1` | ASG/ALB saludables, agente activo, dos streams y alarma sin acciones. |
| Entrega externa | `Test-Project01CloudFrontDelivery.ps1` | HTTPS, health y CRUD vía CloudFront. |

Todos los scripts requieren `-Execute` para enviar comandos remotos o realizar solicitudes de validación. Sin ese switch describen el plan o no modifican recursos.

## Criterios de aceptación

- ASG `min=1`, `desired=1`, `max=2`; al menos una EC2 `InService/Healthy`.
- Un target sano en el ALB y health check `GET /health` con HTTP 200.
- CloudFront entrega frontend HTTPS; `/api/*` llega a la API.
- PostgreSQL persiste la tarea temporal y la tarea es eliminada al terminar la prueba.
- CloudWatch Agent entrega streams `application` y `bootstrap`.
- La alarma de salud está en `OK` y no tiene acciones hasta aprobar un destino SNS.

## Si una validación falla

1. No repetir comandos de creación ni forzar terminación de instancias.
2. Revisar Target Group, estado de ASG, logs `bootstrap` y `application`.
3. Determinar si el fallo es de bootstrap, acceso a secretos, conectividad a RDS, release o CloudFront.
4. Aplicar el [runbook de rollback](project-01-rollback.md) con aprobación antes de cambiar una versión o capacidad.
