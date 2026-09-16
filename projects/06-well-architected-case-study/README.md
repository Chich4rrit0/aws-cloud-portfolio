# Project 06 — AWS Well-Architected Case Study

Caso de estudio final del AWS Cloud Portfolio. Evalúa el Task Manager de
Proyecto 1 como workload principal frente a los seis pilares del AWS
Well-Architected Framework y transforma las observaciones en un backlog de
mejoras priorizado.

## Estado

**FASE 1 — assessment estático completado.** No se han creado ni modificado
recursos AWS para este proyecto. P6 es una revisión basada en evidencia, no un
redeploy de P1 ni un cambio a los proyectos cerrados.

## Alcance

El workload evaluado es el Task Manager de P1:

```text
Internet → CloudFront → S3 (frontend)
                     └→ ALB → ASG / EC2 → RDS PostgreSQL
                                  ├→ Parameter Store
                                  ├→ S3 de artefactos
                                  └→ CloudWatch / Session Manager
```

P2, P3, P4 y P5 no serán modificados ni evaluados como parte del score de P1.
Solo se usan como contexto documental cuando demuestran una práctica aplicable
a una evolución futura. El laboratorio temporal de P4 no representa el estado
del workload P1.

## Método

P6 sigue el ciclo oficial **Prepare → Review → Improve**:

1. Delimitar el workload y reunir evidencia verificable.
2. Evaluar fortalezas, riesgos y trade-offs por pilar.
3. Priorizar mejoras sin confundir recomendaciones con cambios aplicados.
4. Diseñar una arquitectura objetivo sin desplegarla.

La revisión será ligera, con fecha y fuentes explícitas; no pretende sustituir
una revisión formal de producción ni inventar evidencia ausente.

## Entregables previstos

- Registro de evidencia y límites de evaluación.
- Assessment de los seis pilares.
- Backlog de mejoras priorizado por impacto, esfuerzo, costo y dependencia.
- Arquitectura actual frente a arquitectura objetivo propuesta.
- Cost Check y cierre de P6.

## Documentación

- [Límites y método](docs/architecture/evaluation-boundaries.md)
- [ADR-001: revisión basada en evidencia](docs/decisions/ADR-001-evidence-based-case-study.md)
- [Registro de evidencia](docs/evidence/evidence-register.md)
- [Cost Check de fundamento](docs/cost-checks/phase-00-case-study-foundation.md)
- [Assessment de los seis pilares](docs/assessment/pillar-assessment.md)
- [Arquitectura objetivo no desplegada](docs/architecture/target-architecture.md)
- [Backlog de mejoras](docs/recommendations/improvement-backlog.md)
- [ADR-002: priorización](docs/decisions/ADR-002-improvement-prioritization.md)
- [Auditoría actual de solo lectura](docs/operations/current-state-audit.md)

## Fuentes principales

- [Arquitectura final de P1](../../docs/architecture/project-01-final-architecture.md)
- [Revisión histórica de P1](../../docs/well-architected/project-01-review.md)
- [Validación operacional de P1](../../docs/operations/project-01-validation.md)
- [Guía de limpieza de P1](../../docs/operations/project-01-cleanup.md)
- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/)

## Próximo checkpoint

Hacer una verificación AWS de solo lectura para separar estado histórico de
estado actual y, con ese resultado, consolidar el informe y cierre de P6. No
requiere crear, actualizar ni eliminar recursos.
