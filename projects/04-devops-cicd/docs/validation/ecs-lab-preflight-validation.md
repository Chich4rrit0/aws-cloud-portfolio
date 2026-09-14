# Validación de preflight ECS — Proyecto 4

## Resultado

| Control | Resultado |
|---|---|
| Sintaxis de scripts deploy/runtime/teardown | Válida. |
| Template CloudFormation | Válido y sin stack creado. |
| Imagen ECR esperada | Tag SHA inmutable localizado. |
| Presupuesto observado | USD 0.00 de USD 1.00 durante el preflight. |
| Comportamiento sin `-Deploy` | Preflight finalizó sin crear stack. |
| Guardrail de teardown | Requiere `-ApproveDestroy` y nombre exacto del stack. |

## Nota de costo

El presupuesto es un indicador con retraso potencial y no un mecanismo de
apagado. El ALB, la tarea Fargate, IPv4 públicas, logs y transferencia solo se
aceptarán durante una ventana temporal explícitamente aprobada.
