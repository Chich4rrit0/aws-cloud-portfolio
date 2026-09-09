# ADR-006 — Runtime Lambda y paquete versionado

- Estado: Propuesto para aprobación
- Fecha: 2026-09-09

## Contexto

La aplicación se desarrolla con Node.js 20 localmente, pero el runtime administrado `nodejs20.x` de AWS Lambda figura como deprecado. La función necesita el cliente DynamoDB del SDK y debe ser reproducible sin confiar en la versión incluida en el runtime.

## Decisión propuesta

Desplegar ZIP con runtime `nodejs22.x`, arquitectura `arm64` y dependencias versionadas mediante `package-lock.json`. Mantener pruebas locales en Node 20 mientras sean compatibles y validar el paquete antes de subirlo.

## Consecuencias

Se evita iniciar el proyecto con un runtime deprecado y se controla la versión del SDK. El entorno local y Lambda no usan exactamente la misma versión mayor de Node, por lo que se mantendrá código portable y se añadirá validación en Node 22 antes de un CI futuro.
