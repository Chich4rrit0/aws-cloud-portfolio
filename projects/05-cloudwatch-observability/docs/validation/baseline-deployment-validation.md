# Validación — despliegue baseline CloudWatch

Fecha: 2026-09-14.

## Resultado

El stack `portfolio-p05-observability` alcanzó `CREATE_COMPLETE` después de
corregir la derivación de dimensiones ALB desde ARN.

Se validó mediante API de solo lectura:

- dashboard P5 con paneles Lambda, HTTP API, DynamoDB, ECS, ALB y alarmas;
- tres alarmas P5 sin acciones automáticas;
- dos query definitions de Logs Insights;
- P2 Lambda activa, DynamoDB ACTIVE y HTTP API presente;
- P4 stack UPDATE_COMPLETE y servicio ECS en rollout COMPLETED con 1/1 tareas.

## Estado de alarmas

Las alarmas P5 pueden iniciar en `INSUFFICIENT_DATA` hasta que CloudWatch
disponga de una ventana completa de métricas. No se forzó tráfico ni se
provocaron errores para cambiarlas de estado.

## Exclusiones verificadas

No se modificaron recursos, aplicaciones, retención de logs, configuración de
red, IAM ni despliegues de P1–P4. No se creó SNS, Container Insights, X-Ray,
Synthetics ni una métrica personalizada.
