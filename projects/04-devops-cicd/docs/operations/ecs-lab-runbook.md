# Runbook — Laboratorio temporal ECS/Fargate

## Estado

Preparado y validado localmente. No se ha creado el stack.

## Preflight no destructivo

`Deploy-P04EcsLabStack.ps1` sin parámetros destructivos verifica:

- Sesión AWS activa y presupuesto `portfolio-zero-spend`.
- Existencia de la imagen ECR inmutable esperada.
- URI de imagen resuelto en tiempo de ejecución, sin incluir ARN de cuenta en
  archivos versionados.
- Template CloudFormation ya validado.

Sin `-Deploy`, el script siempre termina sin crear un stack.

## Despliegue pendiente de aprobación

La ejecución con `-Deploy` creará exactamente un stack
`portfolio-p04-ecs-lab` con VPC, dos subredes públicas, IGW, route table,
security groups, log group, execution role ECS, cluster, task definition,
target group, ALB, listener y servicio Fargate de una tarea. AWS podría crear
su service-linked role ECS si aún no existe.

La tarea usará la imagen SHA validada y el stack requerirá
`CAPABILITY_NAMED_IAM` solo para el execution role nombrado. El script se
niega a actualizar un stack existente.

## Validación posterior prevista

`Test-P04EcsLabRuntime.ps1` comprobará:

1. Endpoint HTTP `/health` detrás del ALB.
2. Una tarea ECS en ejecución.
3. Al menos un target healthy en el target group.

## Teardown destructivo pendiente de aprobación

`Remove-P04EcsLabStack.ps1 -ApproveDestroy` elimina exclusivamente el stack
`portfolio-p04-ecs-lab` y espera su terminación. El script bloquea cualquier
otro nombre de stack y no toca la imagen ECR ni la identidad OIDC de
publicación. Se debe ejecutar solo tras una autorización destructiva explícita
y después de conservar la evidencia necesaria.
