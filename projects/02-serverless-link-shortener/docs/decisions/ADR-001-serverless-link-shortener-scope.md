# ADR-001 — Alcance del Serverless Link Shortener

- Estado: Aceptado
- Fecha: 2026-09-09

## Contexto

El segundo proyecto debe demostrar un patrón serverless coherente con el portfolio, reutilizando los principios de seguridad, costo y documentación sin modificar el Proyecto 1 cerrado.

## Decisión

Se construirá un acortador de enlaces personales. La redirección `GET /r/{code}` será pública. Crear y eliminar enlaces requerirá autenticación JWT con Cognito. La primera entrega será API-first y no creará una UI AWS.

## Consecuencias

- El proyecto demuestra API Gateway, Lambda, DynamoDB y Cognito sin duplicar de inmediato la capa S3/CloudFront del Proyecto 1.
- La API pública se reduce a la operación que necesita ser pública.
- La UI se puede agregar después como una decisión independiente, sin bloquear el backend serverless.
