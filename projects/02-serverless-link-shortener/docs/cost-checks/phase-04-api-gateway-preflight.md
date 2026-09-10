# Cost Check — Phase 04: API Gateway preflight

## Recursos creados

Ninguno. Esta fase solo define la exposición propuesta.

## Recursos que pueden generar costo al aplicar

- HTTP API: solicitudes recibidas y transferencia de datos aplicable.
- Lambda: solicitudes y duración una vez eliminada la pausa de concurrencia `0`.
- DynamoDB: lecturas/escrituras de las rutas de aplicación.
- CloudWatch Logs: logs de Lambda durante pruebas.

## Controles previstos

- Stage `$default`: 5 rps, burst 10.
- Lambda: 128 MiB, timeout 3 s, sin Provisioned Concurrency.
- Solo tres rutas explícitas; sin `$default` catch-all.
- Cognito JWT bloquea mutaciones no autenticadas antes de Lambda.
- Sin CORS, WAF, API keys, usage plans, access logs ni infraestructura de red.

## Riesgo de costo inesperado

`GET /r/{code}` será público. El throttling es best-effort, y el presupuesto tiene retraso. Si se detecta actividad anómala, se restablecerá la concurrencia `0` o se eliminará la API después de aprobación explícita.

## Limpieza

Eliminar HTTP API y su permiso Lambda revoca el endpoint. Restablecer concurrencia `0` bloquea la función sin borrarla. Ambas acciones deberán confirmarse cuando se ejecuten.
