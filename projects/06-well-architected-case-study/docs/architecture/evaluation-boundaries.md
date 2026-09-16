# Límites y método de evaluación — Proyecto 6

## Workload y fecha de corte

La evaluación cubre el Task Manager de Proyecto 1, según su arquitectura final
y evidencia documental disponible. La fecha de corte inicial es 2026-09-16.
Cada conclusión indicará si procede de una validación desplegada, de una
decisión documentada o de una ausencia de evidencia.

No se asumirá que un recurso sigue activo solo porque fue desplegado en una
fase anterior. El estado AWS actual solo se afirmará tras una consulta de
lectura con fecha registrada.

## Fuera de alcance

- Modificar, redeplegar, pausar o eliminar P1–P5.
- Crear un workload en la herramienta Well-Architected de AWS.
- Usar la infraestructura temporal de P3 o P4 como sustituto de P1.
- Incluir secretos, endpoints, IDs de cuenta, credenciales o cabeceras de
  origen en documentos de P6.

## Fuentes de evidencia

| Fuente | Uso permitido | Limitación |
| --- | --- | --- |
| Arquitectura y ADRs raíz de P1 | Diseño y trade-offs documentados | No prueban por sí solos el estado actual. |
| Runbooks y validaciones P1 | Capacidades comprobadas y límites | Reflejan la fecha de su ejecución. |
| P2–P5 | Patrones posteriores y recomendaciones | No cambian el assessment del workload P1. |
| Consulta AWS de solo lectura, si se realiza | Estado actual puntual | No evalúa carga, resiliencia o costo histórico. |
| Guía oficial AWS | Criterio de revisión | No reemplaza evidencia del workload. |

## Método de clasificación

Cada hallazgo se clasificará como:

- **Fortaleza verificada:** evidencia de una capacidad implementada y validada.
- **Trade-off aceptado:** decisión deliberada de laboratorio documentada.
- **Riesgo o gap:** limitación con posible impacto y sin mitigación suficiente
  para producción.
- **Pendiente de verificar:** no hay evidencia suficiente; no se convierte en
  afirmación.

Las mejoras usarán prioridad `P0` a `P3`: P0 bloquea una exposición productiva,
P1 reduce riesgo alto, P2 aumenta madurez y P3 es optimización opcional.

## Contradicciones conocidas

La documentación inicial de cierre de P4 describe un teardown del runtime,
pero el README más reciente de P4 declara una extensión temporal activa. La
fuente más reciente prevalece para P4. Esto no altera P1 porque P4 está fuera
del alcance del workload evaluado.
