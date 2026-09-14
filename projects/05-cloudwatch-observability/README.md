# Project 05 — CloudWatch / Observability

Proyecto transversal de observabilidad del AWS Cloud Portfolio. Su objetivo es demostrar que una arquitectura se puede operar: observar señales, detectar degradación, investigar con logs y responder con un runbook.

## Estado

**DISEÑO LOCAL.** No se ha creado ningún recurso AWS para este proyecto.

Los Proyectos 1–4 permanecen sin cambios. El Proyecto 4 tiene un laboratorio temporal activo que puede servir como fuente de métricas y logs de solo lectura; este proyecto no lo modifica ni lo mantiene activo.

## Alcance

```text
Fuentes existentes (solo lectura)
  ├─ Proyecto 4: ECS/Fargate, ALB y CloudWatch Logs, si siguen activos
  └─ Proyecto 2: API Gateway, Lambda y DynamoDB, solo si el inventario confirma recursos

Proyecto 5 (recursos propios, pendientes de aprobación)
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

## Próximo checkpoint

Diseñar las señales, consultas y mínimo de alarmas a partir del inventario confirmado. No se crearán dashboards, alarmas, SNS, métricas personalizadas ni otros recursos hasta documentar su impacto de costo y obtener autorización.
