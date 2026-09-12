# Project 03 — Infrastructure as Code

Reconstrucción declarativa de la arquitectura cerrada del Proyecto 1 mediante **AWS CloudFormation** y **Terraform**. El objetivo es comparar una implementación nativa AWS con una implementación portable, manteniendo el mismo diseño funcional y los mismos límites de seguridad.

## Estado

**Fase 0 — blueprint local aprobado.** Se crearán templates, módulos, parámetros de ejemplo y validaciones de plan. No se aplicará infraestructura AWS durante esta fase, no se importarán recursos existentes y no se modifican los Proyectos 1 o 2.

## Alcance

La representación objetivo incluye la VPC, subnets, Security Groups, IAM, Parameter Store, RDS PostgreSQL de desarrollo, ALB, Launch Template, Auto Scaling Group, buckets S3 privados, CloudFront, CloudWatch Logs y alarma de salud que ya componen el baseline del Proyecto 1.

No se crearán recursos al escribir o validar los archivos. Un despliegue futuro requerirá un Cost Check y aprobación explícita.

## Organización

```text
cloudformation/
  stacks/        Templates por capa
  parameters/    Parámetros de ejemplo sin secretos
terraform/
  environments/lab/  Ensamblaje del entorno de laboratorio
  modules/           Módulos reutilizables por capa
scripts/             Validación PowerShell, sin apply implícito
docs/                Arquitectura, ADRs, Cost Checks y evidencia
```

## Principios de seguridad

- No se versionan contraseñas, JWTs, Access Keys, endpoints sensibles ni archivos de estado Terraform.
- Ningún template administra ni importa recursos existentes del Proyecto 1 o 2.
- Terraform empezará con backend local ignorado por Git; no se creará un bucket de estado hasta aprobar una fase específica.
- CloudFormation y Terraform se validarán antes de cualquier `deploy` o `apply`.

## Documentación

- [Alcance de reconstrucción](docs/architecture/project-01-reconstruction-scope.md)
- [ADR-001: modo plan e aislamiento](docs/decisions/ADR-001-plan-only-and-isolation.md)
- [Cost Check de bootstrap](docs/cost-checks/phase-00-bootstrap.md)
- [Estrategia de validación](docs/validation/plan-only-validation.md)
- [Validación del template de red](docs/validation/cloudformation-network-validation.md)
- [Diseño del Security stack](docs/architecture/security-stack-design.md)
- [Validación del Security stack](docs/validation/cloudformation-security-validation.md)
- [Diseño del Data stack](docs/architecture/data-stack-design.md)
- [Validación del Data stack](docs/validation/cloudformation-data-validation.md)
- [Diseño del Storage stack](docs/architecture/storage-stack-design.md)
- [Validación del Storage stack](docs/validation/cloudformation-storage-validation.md)
- [Diseño del Compute stack](docs/architecture/compute-stack-design.md)
- [Validación del Compute stack](docs/validation/cloudformation-compute-validation.md)
- [Diseño del Edge stack](docs/architecture/edge-stack-design.md)
- [Validación del Edge stack](docs/validation/cloudformation-edge-validation.md)
- [Diseño del Operations stack](docs/architecture/operations-stack-design.md)
- [Validación del Operations stack](docs/validation/cloudformation-operations-validation.md)
- [Diseño de la foundation Terraform](docs/architecture/terraform-foundation.md)
- [Validación de la foundation Terraform](docs/validation/terraform-foundation-validation.md)
- [Diseño del módulo Terraform Network](docs/architecture/terraform-network-module.md)
- [Validación del módulo Terraform Network](docs/validation/terraform-network-validation.md)
- [Diseño del módulo Terraform Security](docs/architecture/terraform-security-module.md)
- [Validación del módulo Terraform Security](docs/validation/terraform-security-validation.md)
- [Diseño del módulo Terraform Data](docs/architecture/terraform-data-module.md)
- [Validación del módulo Terraform Data](docs/validation/terraform-data-validation.md)
- [Diseño del módulo Terraform Storage](docs/architecture/terraform-storage-module.md)
- [Validación del módulo Terraform Storage](docs/validation/terraform-storage-validation.md)
- [Diseño del módulo Terraform Compute](docs/architecture/terraform-compute-module.md)
- [Validación del módulo Terraform Compute](docs/validation/terraform-compute-validation.md)
- [Validación del módulo Terraform Operations](docs/validation/terraform-operations-validation.md)
- [Validación del módulo Terraform Edge](docs/validation/terraform-edge-validation.md)
- [Cost Check final](docs/cost-checks/project-03-final-plan-only.md)
- [Guía de despliegue y teardown](docs/operations/project-03-deployment-and-teardown-guide.md)
- [Auditoría inicial E2E](docs/e2e-readiness/phase-00-environment-audit.md)
- [Prerequisitos AWS E2E](docs/e2e-readiness/phase-01-aws-prerequisites.md)
- [Orquestación E2E por etapas](docs/e2e-readiness/phase-02-staged-orchestration.md)
- [Validación E2E Foundation](docs/e2e-readiness/phase-03-foundation-validation.md)
- [Diseño E2E de bootstrap PostgreSQL](docs/e2e-readiness/phase-04-database-bootstrap-design.md)
- [Diseño E2E de publicación de artefactos](docs/e2e-readiness/phase-05-artifact-publication-design.md)
- [Validación E2E Runtime](docs/e2e-readiness/phase-06-runtime-validation.md)
- [Diseño y validación E2E Edge](docs/e2e-readiness/phase-07-edge-validation.md)
- [Bootstrap E2E ejecutable y seguro](docs/e2e-readiness/phase-08-bootstrap-script-validation.md)
- [Runbook E2E por etapas](docs/e2e-readiness/phase-09-execution-runbook.md)
- [Preflight E2E actual](docs/e2e-readiness/phase-10-current-preflight.md)
- [Cost Check E2E actual](docs/cost-checks/project-03-e2e-current-estimate.md)
- [Gate de plan E2E Foundation](docs/e2e-readiness/phase-11-foundation-plan-gate.md)
