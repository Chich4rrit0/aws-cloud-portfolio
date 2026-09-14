# Operación — CD GitHub → ECS temporal

## Flujo

`Project 04 Deploy ECS` es un workflow manual. Recibe una etiqueta inmutable
`sha-<commit>` ya publicada en el ECR privado del Proyecto 4.

1. GitHub Actions asume el rol OIDC `portfolio-p04-github-actions-ecs-deployer`.
2. Verifica que la imagen indicada existe en el único repositorio ECR permitido.
3. Lee la task definition activa del único servicio temporal.
4. Registra una revisión que cambia únicamente la imagen del contenedor
   `task-manager-api`.
5. Actualiza el único servicio ECS y espera su estabilización.

No usa Access Keys, secretos de AWS ni tags mutables. El ARN del rol se guarda
como variable no secreta del repositorio privado:
`AWS_P04_ECS_DEPLOY_ROLE_ARN`.

La consulta `ecs:DescribeTaskDefinition` usa el único wildcard de la política
porque AWS no permite restringir dicha acción a un ARN de task definition. Es
lectura; las operaciones mutables permanecen limitadas al laboratorio.

## Límite operacional

El workflow no crea infraestructura, no publica imágenes, no escala el
servicio, no puede usar otros clusters y no ejecuta teardown. Si el stack no
existe, falla por diseño. La validación externa `/health` sigue siendo un paso
operacional posterior al despliegue.
