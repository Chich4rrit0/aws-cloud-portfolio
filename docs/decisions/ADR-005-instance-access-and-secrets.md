\# ADR-005 — Acceso a instancias y gestión de secretos



\- Estado: Aceptado

\- Fecha: 2026-09-06



\## Contexto



El proyecto requiere administrar instancias EC2 y entregar credenciales PostgreSQL a la aplicación sin exponer llaves SSH, access keys ni contraseñas en Git, scripts o user data.



\## Decisión



\- Las instancias EC2 usarán un IAM role con acceso a AWS Systems Manager Session Manager.

\- No se abrirá el puerto SSH 22 ni se crearán llaves `.pem`.

\- La contraseña de PostgreSQL se almacenará como `SecureString` estándar en AWS Systems Manager Parameter Store.

\- La aplicación leerá únicamente el parámetro que necesita mediante permisos IAM de mínimo privilegio.



Ruta planificada del parámetro:



```text

/portfolio/project-01/database/password

