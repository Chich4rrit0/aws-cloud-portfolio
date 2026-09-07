# ADR-011 — Bootstrap temporal para credenciales de aplicación

- Estado: Aceptado
- Fecha: 2026-09-07

## Contexto

La instancia RDS se creó con una cuenta maestra necesaria para la administración inicial. Usar esa cuenta desde EC2 convertiría una credencial de alto privilegio en una credencial de aplicación de larga duración.

## Decisión

Se creará, con aprobación separada, una EC2 temporal de bootstrap. No tendrá puertos de entrada ni acceso SSH y se administrará exclusivamente con Session Manager. Tendrá un rol distinto del rol de la aplicación, con permisos mínimos para:

- Leer solo el parámetro SecureString de contraseña maestra existente.
- Crear o sobrescribir solo el parámetro SecureString de contraseña de aplicación.
- Usar Session Manager mediante la política administrada requerida.

La instancia creará el login PostgreSQL `taskmanager_app` y le otorgará solamente acceso al esquema y base `taskmanager`. La contraseña de aplicación se almacenará en `/portfolio/project-01/database/app-password`.

Después de validar el bootstrap, el rol de EC2 de la aplicación se actualizará para leer únicamente el parámetro de aplicación. El acceso de ese rol al parámetro maestro se eliminará.

## Consecuencias

- Se introduce una EC2 efímera adicional, con un costo pequeño y controlado.
- La instancia requiere salida a Internet para Session Manager, paquetes y el bundle CA de RDS; usa una subnet pública pero conserva cero reglas inbound.
- Terminar y eliminar el bootstrap es una acción destructiva que requerirá confirmación explícita tras verificar el usuario de aplicación.
