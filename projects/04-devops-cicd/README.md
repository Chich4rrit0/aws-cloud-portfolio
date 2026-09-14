# Project 04 — DevOps / CI-CD

Proyecto de entrega continua del AWS Cloud Portfolio. Construye una ruta de
despliegue reproducible para una imagen de contenedor, sin alterar los
Proyectos 1, 2 o 3, que permanecen cerrados.

## Objetivo

Demostrar una cadena de entrega profesional:

```text
GitHub push / pull request
  -> validación y pruebas
  -> Docker build
  -> ECR privado
  -> ECS/Fargate temporal
  -> CloudWatch Logs y verificación de salud
```

El backend cerrado del Proyecto 1 será una fuente de referencia de solo
lectura. La definición de contenedor, automatización y documentación vivirán
en este directorio.

## Estado

**CERRADO.** Se validaron Docker local, CI, publicación ECR mediante OIDC y
una ejecución temporal CloudFormation → ECS/Fargate → ALB → CloudWatch Logs.
El runtime temporal fue eliminado y verificado. Se conserva una imagen ECR
inmutable y la identidad OIDC de publicación; no existe infraestructura ECS,
ALB o red activa del Proyecto 4.

## Principios

- OIDC de GitHub Actions para AWS; nunca claves de acceso almacenadas en
  GitHub.
- Pruebas y build antes de publicar una imagen.
- Imágenes privadas y con etiquetas inmutables ligadas al commit.
- ECS/Fargate y ALB solo en una ventana de prueba aprobada; teardown el mismo
  día.
- Sin NAT Gateway, dominio, Route 53, datos de producción ni secretos en Git.
- Los Proyectos 1, 2 y 3 no se modifican.

## Documentación

- [Blueprint de CI/CD](docs/architecture/project-04-cicd-blueprint.md)
- [ADR-001: OIDC y entrega temporal](docs/decisions/ADR-001-oidc-and-temporary-delivery.md)
- [Cost Check de bootstrap](docs/cost-checks/phase-00-bootstrap.md)
- [Validación local del contenedor](docs/operations/local-container-validation.md)
- [Resultado de validación del contenedor](docs/validation/container-build-validation.md)
- [CI con GitHub Actions](docs/operations/github-actions-ci.md)
- [Resultado de validación CI](docs/validation/github-actions-ci-validation.md)
- [Topología futura de entrega AWS](docs/architecture/aws-delivery-topology.md)
- [Diseño del laboratorio ECS/Fargate](docs/architecture/temporary-ecs-fargate-lab-design.md)
- [Preparación para publicación a ECR](docs/operations/ecr-publication-readiness.md)
- [Diseño de publicador OIDC](docs/operations/github-oidc-ecr-publisher.md)
- [Validación IAM OIDC](docs/validation/github-oidc-iam-validation.md)
- [Validación de publicación ECR](docs/validation/ecr-publication-validation.md)
- [Validación del template ECS](docs/validation/cloudformation-ecs-lab-template.md)
- [ADR-002: laboratorio ECS/Fargate](docs/decisions/ADR-002-temporary-ecs-fargate-lab.md)
- [Cost Check predespliegue ECS](docs/cost-checks/phase-01-ecs-lab-plan.md)
- [Runbook del laboratorio ECS](docs/operations/ecs-lab-runbook.md)
- [Validación de preflight ECS](docs/validation/ecs-lab-preflight-validation.md)
- [Validación end-to-end ECS/Fargate](docs/validation/ecs-fargate-runtime-e2e-validation.md)
- [Cost Check de teardown y cierre](docs/cost-checks/phase-02-teardown-and-closure.md)
- [Validación de teardown](docs/validation/ecs-lab-teardown-validation.md)
- [Cierre profesional](docs/operations/project-04-closeout.md)

## Próximo checkpoint

Proyecto cerrado. La observabilidad avanzada se reserva para el Proyecto 5;
un despliegue automático de GitHub hacia ECS queda como extensión futura y no
forma parte del resultado declarado de este proyecto.
