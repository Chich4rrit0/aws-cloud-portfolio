# Cost Check — Phase 03: Cognito preflight

## Recursos creados

Ninguno. Este documento no crea User Pool, app client ni usuario.

## Costo estimado

El diseño usa Cognito Lite con un usuario de acceso directo y sin SMS, email, MFA avanzado ni add-ons. La página de precios vigente indica un free tier de 10.000 MAU directos al mes para Lite y Essentials. No se asume que el costo real sea cero: precios, plan, región, uso y cargos de otros servicios deben verificarse al aplicar.

## Riesgos de costo excluidos

- SMS para MFA, verificación o recuperación: no se habilita.
- Email para verificación o recuperación: no se habilita.
- Cognito Plus, advanced security, cuota RPS adicional, M2M y replicación multi-Región: no se habilitan.

## Limpieza

Un User Pool contendrá identidad y app client. Su eliminación destruye esos datos y se solicitará confirmación explícita antes de ejecutarla.
