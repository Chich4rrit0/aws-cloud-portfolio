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

**Fase 3 — imagen publicada y validada en ECR.** La imagen se validó localmente,
el workflow de GitHub Actions completó pruebas y Docker build, y una ejecución
manual OIDC publicó una única imagen privada con tag inmutable derivado del
commit. No existe infraestructura ECS/Fargate, ALB o red para este proyecto.

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

## Próximo checkpoint

Diseñar la demostración temporal ECS/Fargate y ALB con presupuesto, controles
de seguridad y teardown explícito. No se creará infraestructura de cómputo o
red sin una aprobación independiente.
