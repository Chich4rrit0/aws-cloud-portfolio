\# ADR-004 — Stack de aplicación Task Manager



\- Estado: Aceptado

\- Fecha: 2026-09-06



\## Contexto



El objetivo principal del portafolio es demostrar arquitectura AWS, seguridad, observabilidad, automatización e infraestructura reproducible. La aplicación debe ser pequeña y no desviar el esfuerzo hacia funcionalidades de negocio.



\## Decisión



La aplicación usará:



\- Frontend: HTML, CSS y JavaScript sin framework.

\- Backend: Node.js con Express.

\- API interna: puerto 3000.

\- Base de datos: PostgreSQL en Amazon RDS.

\- Autenticación planificada: Amazon Cognito.



\## Razones



\- Node.js y npm ya están disponibles en el entorno local.

\- Express permite implementar una API CRUD pequeña con poco código.

\- Un frontend estático simplifica el futuro despliegue en S3 y CloudFront.

\- Cognito evita almacenar contraseñas de usuarios en PostgreSQL.



\## Consecuencias



\- No se incorporará React ni otro framework frontend en la primera versión.

\- La API y el frontend evolucionarán de forma independiente.

\- La integración de Cognito se realizará antes de exponer la aplicación públicamente.

