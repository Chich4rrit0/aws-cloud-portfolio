# ADR-003 — Redirect público y administración Cognito

- Estado: Aceptado
- Fecha: 2026-09-09

## Contexto

Un URL shortener requiere que cualquier visitante pueda seguir un enlace, pero no debe permitir que cualquier visitante cree o elimine destinos.

## Decisión

`GET /r/{code}` no usará authorizer para permitir redirecciones. `POST /urls` y `DELETE /urls/{code}` usarán un JWT authorizer de Cognito. Lambda validará ownership mediante el claim `sub` antes de eliminar datos.

## Consecuencias

- Se evita tratar una API Key como autenticación de usuario.
- La primera versión incorpora identidad serverless sin añadir servidores propios.
- La configuración de Cognito, verificación de usuarios y costo potencial se revisarán antes de crear recursos.
