# Validación de teardown ECS — Proyecto 4

## Resultado

El teardown autorizado de `portfolio-p04-ecs-lab` terminó correctamente.

| Verificación | Resultado |
|---|---|
| CloudFormation `describe-stacks` | El stack ya no existe. |
| VPC con tag del laboratorio | Ausente. |
| ALB y target group | Ausentes. |
| Servicio ECS | Detuvo sus tareas antes de la eliminación. |
| Runtime activo | Ninguno. |

## Comportamiento observado

El servicio ECS pasó a `DRAINING` con cero tareas antes de que CloudFormation
eliminara ALB, target group y red. Este orden preserva el drenaje administrado
de conexiones; no se forzó la eliminación manual de recursos dependientes.

## Recursos fuera del stack

La imagen ECR y la identidad GitHub OIDC se conservaron por decisión explícita.
No pertenecían al stack temporal y no fueron eliminadas.
