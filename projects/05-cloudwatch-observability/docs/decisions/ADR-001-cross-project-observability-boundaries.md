# ADR-001 — Límites de observabilidad entre proyectos

## Estado

Aceptada para el diseño inicial.

## Decisión

El Proyecto 5 observará recursos existentes mediante métricas y logs de solo lectura. Dashboards, alarmas, consultas guardadas, scripts, documentación y evidencia pertenecen al Proyecto 5. No se editarán stacks, aplicaciones, workflows ni políticas de los Proyectos 1–4 para implementar observabilidad.

## Razón

Los proyectos cerrados son evidencia histórica del portafolio. Mezclar cambios de observabilidad en sus directorios deformaría su alcance y dificultaría explicar qué entregó cada proyecto. Separar propiedad también permite retirar la capa de observabilidad sin afectar las aplicaciones fuente.

## Consecuencias

- El inventario debe confirmar cada fuente antes de declararla parte del dashboard o de una alarma.
- Si una fuente no existe, se documenta como no disponible; no se recrea por conveniencia.
- Las acciones que creen recursos CloudWatch propios requerirán una revisión de costo y autorización previa.
