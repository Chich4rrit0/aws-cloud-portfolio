# Cost Check — Phase 02: preflight de despliegue

## Recursos creados

Ninguno. Este documento no ejecuta AWS CLI ni crea recursos.

## Recursos que pueden generar costo

| Recurso propuesto | Patrón de cobro que se debe vigilar |
| --- | --- |
| API Gateway HTTP API | Solicitudes y transferencia aplicable. |
| Lambda | Invocaciones y duración. |
| DynamoDB On-Demand | Solicitudes, almacenamiento y funciones opcionales habilitadas. |
| Cognito | Usuarios activos mensuales y funciones opcionales, según uso/precio vigente. |
| CloudWatch Logs | Ingesta y almacenamiento durante la retención de siete días. |

IAM role y Lambda permission no se esperan como cargos directos. Esto no convierte los demás recursos en gratuitos: el uso, región, plan y créditos determinan el costo real.

## Límites y exclusiones de costo

- Lambda: 128 MiB, timeout 3 s, concurrencia reservada 0 antes de aprobar pruebas; la cuota actual no permite reservar 2.
- HTTP API: 5 rps, burst 10.
- DynamoDB: On-Demand, sin GSI, PITR ni streams.
- Logs: siete días.
- No se incorporan servicios con costo fijo recurrente típico, como NAT Gateway, ALB, RDS o WAF, en esta fase.

## Riesgo de costo inesperado

El redirect público puede originar solicitudes inesperadas. Throttling y concurrencia reducen el impacto pero no funcionan como un tope de facturación. El presupuesto existente alerta con retraso y no detiene servicios automáticamente. Ante consumo anómalo se pausará el avance, se revisarán métricas disponibles y se propondrá una acción explícita de contención o limpieza.

## Estrategia de eliminación

Al terminar la demostración, eliminar primero API Gateway y Lambda, después Cognito, DynamoDB, logs y finalmente IAM. Borrar la tabla, pool y Log Group destruye sus datos; se solicitará confirmación específica antes de ese paso.
