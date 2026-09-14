# Inventario AWS — Fuentes de observabilidad

Fecha de comprobación: 2026-09-14. Todas las consultas fueron de solo lectura.
No se generó tráfico de aplicación, no se cambió configuración y no se creó
ningún recurso AWS.

## Fuentes confirmadas

| Proyecto | Componente | Estado | Aptitud para P5 |
|---|---|---|---|
| P2 | Lambda Link Shortener | Active, Node.js 22 | métricas de invocaciones, errores, throttles y duración |
| P2 | DynamoDB Link Shortener | ACTIVE, on-demand | throttles y errores del sistema |
| P2 | HTTP API | presente | métricas de conteo, 4XX, 5XX e integración; dimensiones a confirmar antes de crear alarmas |
| P2 | Log group Lambda | retención de 7 días, con datos | fuente primaria para consultas Logs Insights |
| P4 | Stack temporal ECS | UPDATE_COMPLETE | fuente de métricas ECS, ALB y eventos de despliegue |
| P4 | Servicio ECS | rollout COMPLETED, 1/1 | métricas de CPU y memoria |
| P4 | Log group ECS | retención de 7 días, sin bytes almacenados | disponible, pero no se incorporará como fuente de diagnóstico inicial hasta tener eventos |

## Consecuencias de diseño

1. El baseline puede cubrir señales nativas P2 y P4 sin recrear servicios.
2. Logs Insights partirá del log group Lambda de P2; el log group de P4 se
   mantiene documentado pero no se fuerza generación de logs.
3. Los nombres, ARNs, IDs de API y endpoints no se almacenan en esta evidencia.
   Los scripts los resolverán dinámicamente desde AWS cuando sea necesario.
4. Cualquier dashboard, alarma o consulta guardada sigue pendiente de costo,
   plan de despliegue y autorización.
