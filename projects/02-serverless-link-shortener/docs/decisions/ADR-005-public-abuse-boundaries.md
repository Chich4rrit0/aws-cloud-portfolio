# ADR-005 — Límites de abuso y autenticación administrativa

- Estado: Propuesto para aprobación
- Fecha: 2026-09-09

## Contexto

El redirect público puede recibir tráfico no previsto y el presupuesto no funciona como fusible inmediato. Crear y eliminar enlaces debe quedar restringido a la persona administradora.

## Decisión propuesta

Configurar throttling de HTTP API en 5 rps con burst 10; Lambda con 128 MiB, timeout 3 segundos y concurrencia reservada 2; Cognito JWT para rutas mutables y sin auto-registro público. No incorporar WAF, API keys, dashboards ni alertas adicionales en la primera versión.

## Consecuencias

Se reduce la exposición de costo y abuso con límites transparentes, a costa de una baja tolerancia a picos. Es adecuado para una demostración personal; una aplicación pública real debería revaluar rate limiting distribuido, WAF, alertas y capacidad.
