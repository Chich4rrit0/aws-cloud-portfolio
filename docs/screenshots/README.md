# Screenshot guide

Las capturas son evidencia del portfolio, no una fuente de secretos. Guardar solamente imágenes saneadas en este directorio y usar nombres descriptivos, por ejemplo `01-cloudfront-https.png`.

## Capturas recomendadas

| Archivo sugerido | Evidencia | Sanitización necesaria |
| --- | --- | --- |
| `01-cloudfront-https.png` | Frontend cargado por HTTPS y CRUD visible. | Ocultar dominio de distribución si se prefiere; no mostrar datos de cuenta. |
| `02-alb-target-health.png` | Target Group con un target sano. | Ocultar IDs de instancia, ARN y account ID. |
| `03-rds-private-status.png` | RDS disponible y no público. | Ocultar endpoint y account ID. |
| `04-cloudwatch-log-streams.png` | Streams `application` y `bootstrap`. | No mostrar contenido con datos de tareas reales. |
| `05-cloudwatch-alarm-ok.png` | Alarma de salud en estado `OK`. | Ocultar account ID. |
| `06-autoscaling-activity.png` | Actividades de launch y terminate de la demostración. | Ocultar instance IDs y timestamps sensibles si corresponde. |
| `07-cost-budget.png` | Budget y threshold configurados. | Ocultar correo, account ID y cualquier dato de facturación personal. |

## Reglas

- Nunca capturar Access Keys, secretos, valores de SecureString, correos, endpoints privados, account IDs ni IPs públicas.
- Preferir una tarea ficticia y eliminarla al terminar la captura.
- No guardar screenshots de consola con información de facturación personal.
- Añadir una breve leyenda en el README o pull request que explique qué prueba cada captura.

## Estado

La guía se versiona antes de almacenar imágenes. Las capturas se deben tomar manualmente desde AWS Console o el navegador cuando se prepare la presentación pública del proyecto.
