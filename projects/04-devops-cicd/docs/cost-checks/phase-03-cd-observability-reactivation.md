# Cost Check — Fase 03: reactivación CD y observabilidad

## Recursos reactivados

- Un task Fargate de 0.25 vCPU / 0.5 GB.
- ALB público HTTP, target group y dos subredes públicas en una VPC aislada.
- CloudWatch Logs con retención de siete días.

## Recursos agregados

- Un dashboard CloudWatch con métricas AWS nativas.
- Dos alarmas CloudWatch sin acciones automáticas.
- Un rol OIDC adicional, de mínimo privilegio, para CD GitHub → ECS.

## Recursos que pueden generar costo

Fargate, ALB, transferencias asociadas, almacenamiento ECR, ingesta/retención
de logs y alarmas CloudWatch mientras estén activos. El budget sigue siendo una
alerta y no una detención automática; Billing puede reflejar gasto con retraso.

## Controles y exclusiones

No se creó NAT Gateway, EC2, RDS, dominio, Route 53, SNS, Container Insights,
métricas personalizadas ni secretos. El stack sigue siendo temporal y debe
eliminarse explícitamente al cerrar la validación.

## Evidencia de validación

Al finalizar la validación, el budget `portfolio-zero-spend` reportó gasto
actual de USD 0.00 de USD 1.00. Este es un valor informado por Billing y puede
tener retraso; no debe interpretarse como garantía de costo final cero.

El workflow de CD, el endpoint `/health`, el servicio ECS, el target del ALB,
el dashboard y las dos alarmas se validaron correctamente. El runtime queda
activo hasta que se apruebe su teardown explícito.
