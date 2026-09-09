# Runbook — Project 01 rollback

## Principio

Rollback significa volver a una versión de artefacto y Launch Template previamente validada. No consiste en editar una EC2 en ejecución ni usar credenciales de base de datos manualmente.

## Señales para detener un despliegue

- Target Group sin targets saludables.
- Health endpoint no devuelve `200`.
- Fallo de CRUD contra PostgreSQL.
- CloudWatch Agent detenido o ausencia de logs después del warm-up.
- Error de entrega CloudFront que no se explica por propagación de caché.

## Procedimiento

1. No terminar instancias manualmente ni cambiar `desired` sin aprobación.
2. Identificar el último release ZIP y Launch Template validados desde Git, S3 y el historial del Launch Template.
3. Revisar que el release elegido no contenga secretos, y que mantenga el bootstrap CloudWatch, el role de EC2 y TLS a RDS.
4. Con aprobación explícita, configurar el ASG para usar la versión anterior del Launch Template.
5. Ejecutar un instance refresh protegido con capacidad saludable mínima de 100%.
6. Si el fallo corresponde solo al frontend, volver a publicar el frontend conocido y crear una sola invalidación CloudFront.
7. Ejecutar las tres validaciones del runbook de despliegue.

## Base de datos

No ejecutar un restore RDS como primer paso de rollback de aplicación. Las operaciones CRUD actuales no incluyen migraciones destructivas. Si una futura versión introduce migraciones, la estrategia de schema rollback y restore debe diseñarse y probarse antes del despliegue.

## Comunicación y evidencia

Registrar el commit/release fallido, versión restaurada, señal observada, resultado de health/Target Group/CloudWatch/CRUD e impacto de costo de la recuperación.
