# Blueprint — Observabilidad del Proyecto 5

## Problema

Los Proyectos 1–4 demuestran construcción y entrega, pero un portafolio Cloud profesional también debe demostrar cómo se detecta una degradación y cómo se investiga sin depender de la consola como única fuente de verdad.

## Diseño inicial

El Proyecto 5 será una capa de observabilidad con recursos propios y fuentes existentes de solo lectura.

| Pilar | Señal | Fuente prevista | Uso operacional |
|---|---|---|---|
| Disponibilidad | targets saludables, 5XX y latencia | ALB del Proyecto 4 | detectar una API no disponible o degradada |
| Capacidad | CPU y memoria del servicio | ECS/Fargate del Proyecto 4 | distinguir saturación de un error funcional |
| Errores serverless | errores Lambda/API 5XX | Proyecto 2, si existe | detectar fallos del flujo serverless |
| Diagnóstico | eventos y mensajes correlacionados | CloudWatch Logs / Logs Insights | investigar una alarma y documentar respuesta |
| Costo | recursos activos y retención | Cost Check | limitar gasto de observabilidad |

## Límites de la primera versión

- Sin modificar despliegues, grupos de seguridad, código o escalado de los proyectos fuente.
- Sin Container Insights, X-Ray, CloudWatch Synthetics, métricas personalizadas ni notificaciones SNS en el baseline.
- Sin crear alarmas hasta que un inventario confirme nombres, dimensiones y disponibilidad de métricas.
- Una prueba de incidente será propiedad del Proyecto 5 y no deberá degradar servicios de los proyectos cerrados.

## Flujo operativo objetivo

```text
Métrica nativa / log existente
  -> dashboard o alarma del Proyecto 5
  -> runbook con consulta Logs Insights
  -> validación de recuperación
  -> evidencia y Cost Check
```

## Decisiones pendientes

1. Qué recursos reales del Proyecto 2 siguen disponibles.
2. Si se requiere una notificación externa o basta el estado de alarma para la primera versión.
3. Qué incidente controlado puede producir una señal sin modificar proyectos cerrados.
