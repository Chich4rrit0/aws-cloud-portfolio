# Registro de evidencia — Proyecto 6

## Evidencia base de P1

| ID | Evidencia | Uso en la revisión | Estado |
| --- | --- | --- | --- |
| E-01 | Arquitectura final P1 | Topología, flujos y límites de desarrollo | Documentada y validada en fase P1. |
| E-02 | Validación operacional P1 | Health check, ASG, CloudWatch y CRUD | Documentada; fecha histórica. |
| E-03 | Revisión histórica Well-Architected P1 | Riesgos y recomendaciones iniciales | Insumo, no conclusión final automática. |
| E-04 | Runbook de limpieza P1 | Límites de costo y dependencias de teardown | Documentada; no prueba estado actual. |
| E-05 | ADRs P1 | Razonamiento de seguridad, secretos, edge y RDS | Decisiones históricas aceptadas. |
| E-10 | Auditoría P6 de 2026-09-16 | Estado puntual y seguro de recursos P1 | Lectura AWS sin cambios; no valida carga ni costos históricos. |

## Evidencia de madurez posterior, fuera de alcance

| ID | Fuente | Patrón que puede informar una mejora futura |
| --- | --- | --- |
| E-06 | P2 cierre serverless | JWT gestionado, autorización y validación positiva/negativa. |
| E-07 | P3 E2E | IaC, convergencia y validación edge/runtime aislada. |
| E-08 | P4 CI/CD | OIDC, pruebas, build, ECR y despliegue temporal. |
| E-09 | P5 revisión final | Dashboard, alarmas sin acciones, Logs Insights y runbook. |

## Evidencia pendiente

- Resultado de restore de RDS: **PENDIENTE DE VERIFICAR**; no existe evidencia
  de una práctica de recuperación.
- Métricas de latencia y carga sostenida P1: **PENDIENTE DE VERIFICAR**.
- Costos reales acumulados P1: **PENDIENTE DE VERIFICAR** en Billing, que
  puede tener retraso.
