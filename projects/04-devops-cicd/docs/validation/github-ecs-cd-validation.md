# Validación — CD GitHub → ECS

## Resultado

Validación exitosa el 2026-09-14 mediante el workflow manual
`Project 04 Deploy ECS`.

- Workflow: [run exitoso de GitHub Actions](https://github.com/Chich4rrit0/aws-cloud-portfolio/actions/runs/34847963649).
- Autenticación: GitHub OIDC asumió el rol dedicado de despliegue; no se usaron
  Access Keys ni secretos AWS.
- Artefacto: se verificó una etiqueta ECR inmutable ya existente.
- Entrega: se registró la revisión 4 de la task definition y se actualizó el
  único servicio ECS temporal.
- Estabilización: ECS declaró el rollout `COMPLETED` con una tarea ejecutándose
  para un desired count de uno.
- Validación externa: `/health`, el target ALB y el servicio ECS respondieron
  correctamente después del deployment.

## Incidencia resuelta

La primera prueba descubrió que `ecs:DescribeTaskDefinition` no admite
restricción por ARN. El rol conserva permisos mutables acotados y recibe un
único wildcard de solo lectura para esa acción. Una segunda prueba detectó que
el waiter estándar expiraba antes del fin del drenaje ALB; el workflow ahora
inspecciona el rollout hasta 15 minutos y falla antes solo si ECS declara
`FAILED`.
