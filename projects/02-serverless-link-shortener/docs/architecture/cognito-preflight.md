# Preflight de Cognito — Project 02

## Objetivo

Proteger solo las operaciones administrativas (`POST /urls` y `DELETE /urls/{code}`) con JWT. El redirect público no consultará Cognito. Este documento define una configuración de laboratorio de un único administrador; no crea recursos.

## Recursos propuestos

| Recurso | Nombre propuesto | Configuración |
| --- | --- | --- |
| User Pool | `portfolio-p02-admins` | Tier `LITE`, login por username no sensible a mayúsculas, auto-registro deshabilitado, sin atributos email/teléfono obligatorios, sin MFA/SMS/email y sin funcionalidades avanzadas. |
| App client | `portfolio-p02-api-client` | Sin client secret; `ALLOW_USER_PASSWORD_AUTH` y refresh token; prevención de errores de existencia de usuario habilitada. |

No se crearán Identity Pool, Hosted UI, dominio Cognito, proveedores sociales/SAML/OIDC, MFA por SMS, recuperación por email/SMS, custom auth triggers, grupos, add-ons ni replicación multi-Región.

## Credenciales del administrador

El User Pool y app client se pueden crear sin usuario. En una aprobación posterior se creará un único username de laboratorio con `AdminCreateUser` usando supresión de mensajes y se asignará una contraseña permanente mediante una entrada local segura.

La contraseña nunca se escribirá en un script, variable versionada, comando visible, README ni chat. Si el entorno automatizado no permite una entrada segura, el usuario ejecutará exclusivamente ese paso de contraseña en su propia terminal PowerShell.

## Contrato de token

API Gateway recibirá después un JWT de Cognito para las rutas mutables. El authorizer se configurará con el issuer del User Pool y el identificador del app client como audience. Lambda recibirá el claim `sub`; no recibirá ni persistirá la contraseña.

## Cost Check previo

El tier Lite tiene un free tier vigente de 10.000 MAU directos por mes. Este laboratorio tendrá un usuario y no usa SMS ni email, que pueden implicar cargos adicionales. Es una condición de precio vigente, no una garantía del costo real de la cuenta.

Fuentes: [Cognito pricing](https://aws.amazon.com/cognito/pricing/) y [app clients](https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-client-apps.html).

## Limpieza

Eliminar el User Pool elimina su app client y usuarios. Es una acción destructiva de identidad y requerirá confirmación explícita. No se creará un usuario ni se almacenará contraseña en esta fase de diseño.
