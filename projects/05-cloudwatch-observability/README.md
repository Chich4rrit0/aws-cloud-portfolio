# Project 05 — CloudWatch / Observability

Proyecto transversal de observabilidad del AWS Cloud Portfolio. Su objetivo es demostrar que una arquitectura se puede operar: observar señales, detectar degradación, investigar con logs y responder con un runbook.

## Estado

**BASELINE DESPLEGADO Y VALIDADO.** El Proyecto 5 administra un dashboard
CloudWatch, tres alarmas sin acciones y dos consultas guardadas. Una prueba de
incidente controlada verificó la respuesta operacional sin generar tráfico ni
modificar las fuentes P2/P4.

Los Proyectos 1–4 permanecen sin cambios. El Proyecto 4 tiene un laboratorio temporal activo que puede servir como fuente de métricas y logs de solo lectura; este proyecto no lo modifica ni lo mantiene activo.

## Alcance

```text
Fuentes existentes (solo lectura)
  ├─ Proyecto 4: ECS/Fargate, ALB y CloudWatch Logs, si siguen activos
  └─ Proyecto 2: API Gateway, Lambda y DynamoDB, solo si el inventario confirma recursos

Proyecto 5 (recursos propios desplegados)
  ├─ Dashboard CloudWatch transversal
  ├─ Consultas reutilizables de Logs Insights
  ├─ Alarmas de salud y error
  ├─ Runbooks operacionales
  └─ Prueba de incidente controlada
```

## Principios

- No modificar ni redeplegar Proyectos 1–4 para observarlos.
- Inventariar primero; no asumir que un recurso de un proyecto cerrado existe.
- Evitar métricas personalizadas, Container Insights, SNS y synthetics salvo aprobación explícita y justificación de costo.
- Cada alarma debe tener una señal, umbral, respuesta y estrategia de limpieza.
- Un dashboard no reemplaza la investigación: Logs Insights y runbooks serán parte del entregable.

## Fases

1. Base local e inventario AWS de solo lectura.
2. Diseño de señales, dashboard y consultas.
3. Creación aprobada de recursos CloudWatch propios.
4. Incidente controlado y evidencia operacional.
5. Cost Check, guía de limpieza y cierre.

## Documentación

- [Blueprint de observabilidad](docs/architecture/observability-blueprint.md)
- [ADR-001: límites entre proyectos](docs/decisions/ADR-001-cross-project-observability-boundaries.md)
- [Cost Check inicial](docs/cost-checks/phase-00-local-foundation.md)
- [Inventario AWS de fuentes](docs/inventory/aws-source-inventory-2026-09-14.md)
- [Catálogo de señales](docs/architecture/observability-signal-catalog.md)
- [ADR-002: baseline de alarmas](docs/decisions/ADR-002-minimal-alerting-and-safe-incident-test.md)
- [Runbooks y Logs Insights](docs/operations/logs-insights-runbooks.md)
- [Validación de despliegue baseline](docs/validation/baseline-deployment-validation.md)
- [Registro del rollback corregido](docs/validation/baseline-deployment-rollback.md)
- [Validación de incidente controlado](docs/validation/controlled-incident-validation.md)

## Próximo checkpoint

Completar el Cost Check final, documentar la limpieza segura de los recursos
propios de P5 y decidir el momento de cierre. No se hará teardown sin una
aprobación explícita.
