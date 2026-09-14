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
