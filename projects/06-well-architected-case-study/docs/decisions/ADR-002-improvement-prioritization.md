# ADR-002 — Priorizar mejoras por riesgo antes que por cantidad de servicios

## Estado

Aceptada — 2026-09-16.

## Contexto

El portafolio demuestra numerosos servicios AWS, pero agregar más servicios no
mejora automáticamente la arquitectura. P1 fue deliberadamente optimizado para
aprendizaje y costo bajo; sus gaps requieren una ruta proporcional hacia
producción.

## Decisión

El backlog de P6 prioriza identidad, autorización y cifrado de origen antes de
alta disponibilidad, CI/CD avanzado, WAF o mayor telemetría. Las mejoras se
clasifican por riesgo, dependencias y efecto de costo, no por atractivo
tecnológico.

## Consecuencias

- No se propone activar todos los servicios recomendados por AWS de una vez.
- Multi-AZ, WAF, NAT, endpoints, SNS u observabilidad adicional deben pasar
  por un Cost Check propio.
- La arquitectura objetivo queda explícitamente como propuesta no desplegada.
- El orden permite explicar trade-offs de laboratorio en una entrevista sin
  presentar sus limitaciones como defectos ocultos.
