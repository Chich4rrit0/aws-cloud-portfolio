# Cost Check — Project 04 / Phase 02 teardown y cierre

## Auditoría posterior al teardown

| Control | Resultado |
|---|---|
| Stack `portfolio-p04-ecs-lab` | Ausente. |
| VPC temporal | Ausente. |
| ECS/Fargate, ALB, target group y listener | Eliminados por CloudFormation. |
| Subredes, IGW, rutas y security groups temporales | Eliminados por CloudFormation. |
| Log group y execution role del stack | Eliminados por CloudFormation. |
| Imagen ECR | Una imagen inmutable retenida intencionalmente. |
| Proveedor OIDC y publisher role | Retenidos intencionalmente; no son cómputo. |
| Presupuesto observado | USD 0.00 de USD 1.00. |

## Recursos que aún pueden generar costo

- La imagen privada de ECR conserva almacenamiento hasta que se elimine con
  una aprobación destructiva independiente. La lifecycle policy limita el
  crecimiento futuro.
- OIDC y el rol IAM no se esperan como cargos directos, pero siguen siendo
  identidades que deben revisarse si el repositorio deja de necesitar AWS.

## Nota sobre costo real

El valor de USD 0.00 es el gasto reportado al momento de la auditoría. AWS
Billing puede tener retraso, por lo que no equivale a una garantía de costo
final cero. El control de costo principal —eliminar ALB, Fargate, IPv4 pública
y logs temporales— ya se verificó.

## Estado

No quedan recursos de runtime activos del Proyecto 4. El presupuesto de cuenta
debe seguir vigilándose en los días posteriores.
