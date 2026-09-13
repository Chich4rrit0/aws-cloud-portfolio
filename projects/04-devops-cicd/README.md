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

**Fase 2 — CI validado y ECR preparado.** La imagen se validó localmente y el
workflow de GitHub Actions completó pruebas y Docker build. No existe todavía
infraestructura AWS ni publicación de imágenes para este proyecto.

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
- [Preparación para publicación a ECR](docs/operations/ecr-publication-readiness.md)

## Próximo checkpoint

Verificar Docker y GitHub CLI locales. Si están disponibles, se implementará
la imagen reproducible y sus pruebas locales antes de diseñar cualquier
identidad AWS o workflow remoto.
