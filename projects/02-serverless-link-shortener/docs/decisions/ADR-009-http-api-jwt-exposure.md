# ADR-009 — HTTP API con JWT y exposición controlada

- Estado: Propuesto para aprobación
- Fecha: 2026-09-10

## Contexto

El proyecto necesita un redirect público y operaciones administrativas autenticadas. Lambda está pausada intencionalmente con concurrencia reservada `0`; crear una API sin retirarla dejaría un endpoint que falla.

## Decisión propuesta

Crear HTTP API con tres rutas explícitas, authorizer JWT de Cognito para mutaciones, integración Lambda payload v2.0 y stage `$default` con throttle 5 rps/burst 10. Retirar la pausa de Lambda en el mismo cambio para pruebas controladas. No usar scopes OAuth, CORS, WAF ni acceso por API key en esta versión.

## Consecuencias

La API separa autenticación de lógica de aplicación y evita infraestructura de servidores. El redirect pasa a ser público y puede generar uso; el throttling reduce pero no elimina ese riesgo. La ausencia de scopes es aceptable para un único administrador de laboratorio, pero debe revisarse para una aplicación multiusuario o pública.
