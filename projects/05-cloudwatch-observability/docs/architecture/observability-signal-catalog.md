# Catálogo de señales — Proyecto 5

## Criterio

Una señal debe responder una pregunta operacional concreta. Se privilegian
métricas nativas ya disponibles y se evita alertar por actividad esperable,
como errores HTTP 4XX de autenticación o enlaces inexistentes.

## Dashboard transversal propuesto

| Panel | Métricas | Fuente confirmada | Finalidad |
|---|---|---|---|
| Salud serverless | invocaciones, errores, throttles y duración Lambda | P2 | distinguir uso, errores de función y límite de concurrencia |
| API serverless | conteo, 4XX, 5XX y latencia de integración | P2 HTTP API | detectar errores de gateway sin tratar 4XX esperados como incidente |
| Datos serverless | throttles y errores de sistema DynamoDB | P2 | detectar límites/errores sin alarmar por lecturas normales |
| Salud contenedores | CPU y memoria ECS | P4 | detectar presión de capacidad |
| Disponibilidad HTTP | requests, latencia, 5XX y targets no saludables ALB | P4 | correlacionar degradación externa y salud del servicio |
| Estado de alertas | alarmas P4 existentes y alarmas propias P5 | P4/P5 | consolidar estado sin modificar P4 |

Los identificadores de API, target group y ALB se resolverán dinámicamente al
desplegar. No se guardarán en documentación ni scripts como valores fijos.

## Alarmas propias mínimas propuestas

| Alarma | Señal | Umbral inicial | Acción automática |
|---|---|---|---|
| P2 Lambda errors | `AWS/Lambda:Errors` | >= 1 en 5 min | ninguna |
| P2 API 5XX | `AWS/ApiGateway:5xx` | >= 1 en 5 min | ninguna |
| P2 DynamoDB throttles | read/write throttles | >= 1 en 5 min | ninguna |

No se duplica la alarma P4 de target no saludable ni la alarma P4 de CPU alta;
el dashboard de P5 las mostrará como señales existentes. Los umbrales son
baseline para un laboratorio, no una configuración de producción.

## Incidente controlado propuesto

La validación de respuesta a incidente no generará tráfico, errores ni cambios
en P2/P4. Se creará, si se aprueba, una alarma P5 sin acciones y se utilizará
`SetAlarmState` para simular `ALARM`, ejecutar el runbook, capturar evidencia y
devolverla a `OK`. Esto valida la operación humana y el dashboard, pero no se
presentará como una falla real de la aplicación.
