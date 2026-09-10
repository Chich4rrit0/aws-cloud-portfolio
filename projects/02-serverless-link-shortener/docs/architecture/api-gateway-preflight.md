# Preflight de API Gateway — Project 02

## Decisión de secuencia

No se creará un endpoint público mientras Lambda tenga concurrencia reservada `0`: las rutas llegarían a una función pausada y responderían con error. La creación de API Gateway y la retirada de esa pausa se ejecutarán como un único cambio aprobado y verificado.

## Recursos y configuración propuestos

| Recurso | Nombre/configuración | Propósito |
| --- | --- | --- |
| HTTP API | `portfolio-p02-link-shortener-api`, protocolo HTTP, endpoint `execute-api` predeterminado. | Exponer HTTPS sin ALB ni servidores. |
| Lambda integration | `AWS_PROXY`, payload v2.0, timeout integración 3 s. | Enviar eventos HTTP API a la función existente. |
| JWT authorizer | `portfolio-p02-cognito-jwt`; identity source `$request.header.Authorization`; issuer del User Pool y audience del app client. | Validar JWT antes de mutaciones. |
| Routes | Público: `GET /r/{code}`. JWT: `POST /urls`, `DELETE /urls/{code}`. | Separar redirect público de administración autenticada. |
| Stage | `$default`, auto-deploy, throttle 5 rps y burst 10, sin access logs. | Mantener exposición mínima y despliegue simple de laboratorio. |
| Lambda permission | Principal `apigateway.amazonaws.com`, acotado al stage `$default` de esta API. | Permitir únicamente a la API creada invocar Lambda. |
| Lambda concurrency | Eliminar reserva `0` justo antes de pruebas. | Habilitar la función bajo el throttling de la API. |

No se habilitarán CORS, custom domain, Route 53, CloudFront, WAF, API keys, usage plans, access logs, dashboards, tracing, VPC Link ni otra ruta `$default` catch-all.

## Autorización JWT

Las rutas administrativas requerirán `Authorization: Bearer <JWT>`. API Gateway validará firma, `iss`, `aud` o `client_id`, vigencia temporal y demás claims del JWT antes de invocar Lambda. En esta primera versión no se exigirán OAuth scopes: el app client de laboratorio usa autenticación directa y no define un resource server. El authorizer y Lambda usarán el claim `sub` para ownership.

No se guardarán tokens en archivos, scripts, Git ni documentación. Se usarán una sola vez desde la sesión local para pruebas y se eliminarán de la variable de entorno al terminar.

## Límites y costo

El throttling de HTTP API es una meta de protección, no un límite de facturación garantizado. API Gateway puede responder `429` cuando se supera. Lambda, DynamoDB y CloudWatch seguirán siendo recursos de pago por uso; no hay NAT, ALB, RDS, WAF ni capacidad provisionada en esta fase.

La retirada de concurrencia `0` incrementa el riesgo de invocación respecto de la función pausada. Se limitará por stage y se validará con pocas solicitudes manuales; el Budget existente es una alerta con retraso, no un apagado automático.

Fuentes: [JWT authorizers HTTP API](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-jwt-authorizer.html), [routes HTTP API](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-routes.html) y [throttling HTTP API](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-throttling.html).

## Limpieza

Eliminar primero HTTP API, después la permission de Lambda y finalmente volver a establecer concurrencia `0` si la función continúa para otra fase. Eliminar la API corta el endpoint público; no borra Lambda, Cognito, DynamoDB ni logs.
