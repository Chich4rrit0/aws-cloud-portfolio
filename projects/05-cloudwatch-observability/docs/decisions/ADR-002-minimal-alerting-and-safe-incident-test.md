# ADR-002 — Baseline mínimo de alarmas y prueba segura de incidente

## Estado

Aceptada para diseño; pendiente de aprobación para crear recursos AWS.

## Decisión

P5 creará como máximo tres alarmas propias sobre P2: error Lambda, API 5XX y
throttling DynamoDB. No tendrán SNS ni acciones automáticas. Las alarmas P4 ya
existentes se visualizarán en el dashboard transversal, sin reemplazarlas ni
duplicarlas.

La prueba de incidente utilizará una alarma propia de P5 y el cambio controlado
de estado de CloudWatch. No se provocarán errores de aplicación, cambios de
seguridad, despliegues ni tráfico artificial en proyectos cerrados.

## Razón

El baseline demuestra detección y respuesta con la menor cantidad de recursos
recurrentes. Evita ruido por 4XX normales, costos/operación de notificaciones y
el riesgo de alterar evidencia de P2/P4.

## Consecuencias

- Las alarmas necesitan una revisión de costo antes de crearlas.
- La prueba de estado valida un runbook, no resiliencia de código.
- SNS, PagerDuty, synthetics, X-Ray y Container Insights quedan fuera de esta
  fase y pueden evaluarse como extensiones posteriores.
