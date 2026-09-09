# ADR-008 — Cognito Lite para un administrador de laboratorio

- Estado: Propuesto para aprobación
- Fecha: 2026-09-09

## Contexto

Las mutaciones de enlaces necesitan identidad de usuario y ownership sin añadir secretos de aplicación. La demostración tiene una sola persona administradora y no necesita una experiencia de registro público.

## Decisión propuesta

Crear un Cognito User Pool de tier Lite, sin auto-registro y con un app client sin secret para obtener JWT durante pruebas API. No habilitar MFA, SMS, email, proveedores externos ni add-ons. Crear el usuario administrador posteriormente con una contraseña introducida de forma local y segura.

## Consecuencias

Se obtiene un issuer JWT administrado y el claim `sub` necesario para ownership con una superficie y costo mínimos. No es una configuración final de producción para una aplicación pública: requeriría evaluar MFA, recuperación de cuenta, UX de registro, monitoreo de riesgo y protección contra abuso.
