# ADR-004 — Tabla DynamoDB por código y caducidad lógica

- Estado: Propuesto para aprobación
- Fecha: 2026-09-09

## Contexto

La primera versión necesita recuperar y eliminar un enlace con un código corto, sin listar enlaces ni producir analítica.

## Decisión propuesta

Usar una tabla On-Demand con `shortCode` como única partition key. Aplicar escrituras condicionales para colisiones y condición de `ownerSub` al eliminar. Permitir `expiresAt` opcional, validarlo en Lambda y habilitar DynamoDB TTL sobre ese atributo cuando se cree la tabla.

## Consecuencias

El acceso principal queda simple y de bajo costo para volumen irregular. TTL no sirve como garantía temporal exacta, por eso el handler controla el vencimiento. Un listado por propietario demandaría un GSI y una decisión de costo posterior.
