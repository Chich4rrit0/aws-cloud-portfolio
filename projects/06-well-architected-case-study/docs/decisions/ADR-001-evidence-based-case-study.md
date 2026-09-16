# ADR-001 — Caso de estudio P6 basado en evidencia y sin cambios de workload

## Estado

Aceptada — 2026-09-16.

## Contexto

El portafolio ya contiene workloads y laboratorios cerrados, además de
documentación de arquitectura, validaciones, ADRs y Cost Checks. Una revisión
Well-Architected útil debe distinguir el diseño probado de una recomendación y
no reabrir proyectos cerrados solo para completar una lista de controles.

## Decisión

P6 evaluará principalmente el Task Manager de P1 mediante evidencia local
versionada y, solo si resulta necesario, consultas AWS de solo lectura. No
creará recursos, no usará la Well-Architected Tool para almacenar información
del workload y no aplicará recomendaciones sobre P1–P5.

## Consecuencias

- La revisión es reproducible desde Git y segura para una cuenta de bajo costo.
- Un hallazgo puede quedar `PENDIENTE DE VERIFICAR` en lugar de resolverse por
  suposición.
- Las mejoras serán propuestas de arquitectura, no afirmaciones de que fueron
  implementadas.
- La evidencia de P2–P5 podrá demostrar evolución del portafolio, pero no
  ocultará los gaps de P1.

## Alternativas consideradas

1. **Redeplegar P1 y aplicar todas las mejoras.** Se descarta: modifica un
   proyecto cerrado y puede aumentar costos.
2. **Completar una checklist sin fuentes.** Se descarta: produciría un
   documento poco defendible en entrevistas.
3. **Crear un workload en AWS Well-Architected Tool.** Se posterga: no aporta
   evidencia adicional a la fase inicial y requiere revisar qué datos se
   almacenarían fuera del repositorio.
