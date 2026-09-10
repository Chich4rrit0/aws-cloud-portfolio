# Cost Check — Phase 03: Cognito foundation aplicada

## Recursos creados

- User Pool Cognito Lite `portfolio-p02-admins`.
- App client sin secret `portfolio-p02-api-client`.

## Costo estimado

La configuración no usa SMS, email, MFA avanzado, Identity Pools, federación, add-ons ni replicación. Cognito Lite tiene un free tier vigente de 10.000 MAU directos por mes; el pool tiene un único administrador de laboratorio.

## Costo real

El usuario fue configurado, pero no se han emitido ni persistido tokens en el proyecto. No se declara costo real porque la facturación es diferida y no se ha verificado actividad de autenticación.

## Recursos que se pueden apagar o eliminar

No existe un proceso que apagar. Eliminar el User Pool borra el app client y, en el futuro, el usuario de laboratorio. Será una acción destructiva que requerirá aprobación.

## Riesgo de costo inesperado

El riesgo actual es bajo porque no hay usuarios ni mecanismos de mensajería. Se mantendrá el pool sin servicios adicionales y se evitará activar SMS/email, Plus, advanced security, cuotas adicionales, M2M o replicación sin un Cost Check nuevo.
