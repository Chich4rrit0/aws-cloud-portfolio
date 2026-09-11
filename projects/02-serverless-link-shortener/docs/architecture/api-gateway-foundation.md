# Fundación de API Gateway aplicada — Project 02

## Estado verificado

Se creó una HTTP API para el Link Shortener y se verificó su configuración sin incluir el endpoint en el repositorio.

| Elemento | Configuración aplicada |
| --- | --- |
| Integración | Lambda proxy (`AWS_PROXY`), payload v2.0, timeout 3 s. |
| Ruta pública | `GET /r/{code}` sin autorización. |
| Rutas administrativas | `POST /urls` y `DELETE /urls/{code}` protegidas por JWT. |
| Authorizer | Cognito JWT con `Authorization` como fuente de identidad. |
| Stage | `$default`, auto-deploy, 5 rps y burst 10. |
| Permiso Lambda | Únicamente API Gateway, limitado a esta API y al stage `$default`. |
| Concurrencia Lambda | Se eliminó la pausa de concurrencia `0` para permitir pruebas controladas. |

## Corrección aplicada

La primera declaración de permiso Lambda interpretó `$default` como una variable PowerShell vacía. Se reemplazó por una declaración que conserva el nombre literal del stage y mantiene el principio de mínimo privilegio. El script `scripts/create-api-gateway.ps1` usa una comilla invertida para evitar la misma expansión.

## Qué no se habilitó

No hay CORS, custom domain, Route 53, CloudFront, WAF, API keys, usage plans, access logs, dashboards, tracing, VPC Link ni ruta catch-all `$default`.

## Próxima validación

La validación funcional debe ser intencional y mínima: comprobar que una ruta administrativa sin JWT sea rechazada, crear un enlace con un JWT local no persistido, resolverlo por la ruta pública y borrarlo. Tras la prueba se eliminará el dato de DynamoDB y cualquier variable local que contenga tokens.

## Limpieza

Eliminar primero la HTTP API y luego su permiso Lambda. Si se necesita volver a pausar el cómputo, establecer concurrencia reservada `0` en Lambda. Estas acciones no eliminan DynamoDB, Cognito ni CloudWatch Logs.
