# Project 02 — Serverless blueprint

## Problema

Crear y resolver enlaces cortos de bajo volumen sin mantener infraestructura de cómputo permanentemente encendida. El sistema debe separar un redirect público de operaciones de administración autenticadas.

## Arquitectura

```mermaid
flowchart TB
    Public((Public viewer)) -->|GET /r/{code}| HttpApi[API Gateway HTTP API]
    User((Authenticated owner)) -->|JWT| Authorizer[Cognito JWT authorizer]
    Authorizer -->|POST /urls\nDELETE /urls/{code}| HttpApi
    HttpApi --> Handler[Lambda handler]
    Handler -->|GetItem / PutItem / DeleteItem| Table[(DynamoDB\nOn-demand)]
    Handler --> LambdaLogs[CloudWatch Logs\n7-day retention planned]
```

## Responsabilidades

| Servicio | Responsabilidad | No se usa para |
| --- | --- | --- |
| API Gateway HTTP API | Rutas HTTPS, integración Lambda y authorizer JWT. | Cache, VPC Link o API REST avanzado. |
| Lambda | Validar solicitudes, generar códigos, verificar ownership y devolver redirect HTTP. | Procesos de larga duración o secretos hardcodeados. |
| DynamoDB On-Demand | Persistir enlaces y TTL opcional sin capacidad provisionada. | Relaciones complejas, joins o búsquedas no diseñadas. |
| Cognito | Emitir JWT para operaciones administrativas. | Autorizar el redirect público. |
| CloudWatch Logs | Diagnóstico de Lambda con retención corta. | Guardar URLs completas, JWTs o datos personales innecesarios. |

## Modelo de datos propuesto

La implementación final debe validar este modelo con tests antes de crear la tabla.

| Campo | Tipo conceptual | Uso |
| --- | --- | --- |
| `shortCode` | String, partition key | Identificador aleatorio del enlace. |
| `originalUrl` | String | URL HTTPS validada para el redirect. |
| `ownerSub` | String | `sub` de Cognito para validar eliminación. |
| `createdAt` | ISO-8601 string | Auditoría básica. |
| `expiresAt` | Epoch seconds, opcional | TTL de DynamoDB; su eliminación es eventual. |

`PutItem` deberá usar una condición de inexistencia sobre `shortCode`; ante una colisión se genera un nuevo código. `DELETE` deberá condicionar la operación al `ownerSub` del JWT.

## Límites de seguridad iniciales

- Solo se aceptarán URLs `https://`; no se permitirá `javascript:`, `data:` ni protocolos arbitrarios.
- El redirect público devuelve una redirección temporal y no expone datos del propietario.
- La administración requiere JWT válido; una API Key no reemplaza autorización de usuarios.
- Lambda no se ubicará dentro de una VPC: DynamoDB y Cognito son integraciones administradas y no se necesita NAT Gateway.
- Logs estructurados excluirán `Authorization`, JWT y URL completa cuando no sea necesaria para diagnóstico.

## Decisiones diferidas

- Duración exacta de TTL y si cada enlace debe expirar.
- UI estática y hosting; no forma parte de la primera versión.
- Rate limiting, WAF y dominios personalizados; se evaluarán solo si el endpoint queda expuesto más allá de la demostración.
- PITR de DynamoDB y alertas SNS; requieren un Cost Check específico.
