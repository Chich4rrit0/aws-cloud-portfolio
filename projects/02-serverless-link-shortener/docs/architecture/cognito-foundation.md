# Fundación de Cognito aplicada — Project 02

## Estado verificado

| Recurso | Estado | Configuración confirmada |
| --- | --- | --- |
| User Pool `portfolio-p02-admins` | Disponible | Tier Lite, username sin distinción de mayúsculas, MFA `OFF`, auto-registro deshabilitado, protección de borrado `INACTIVE`, contraseña mínima de 14 caracteres. |
| App client `portfolio-p02-api-client` | Disponible | Sin client secret, `ALLOW_USER_PASSWORD_AUTH`, `ALLOW_REFRESH_TOKEN_AUTH` y prevención de enumeración habilitada. |

El User Pool tiene cero usuarios. No hay contraseña, token, client secret, dominio, Hosted UI, Identity Pool, email, SMS, proveedores externos, add-ons ni MFA configurados.

Los tags confirmados son `Project=aws-cloud-portfolio`, `ProjectNumber=02`, `Environment=lab` y `ManagedBy=aws-cli`.

## Próximo control de seguridad

El usuario administrador se creará en un paso separado. La contraseña se introducirá de forma local y segura; no se registrará en scripts, historial de comandos, Git, archivos de configuración ni documentación.

## Limpieza futura

Eliminar el User Pool destruye el app client y cualquier usuario que exista. Es una operación destructiva de identidad y requerirá confirmación explícita.
