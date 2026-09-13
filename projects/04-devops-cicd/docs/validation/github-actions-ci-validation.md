# Validación — GitHub Actions CI

## Resultado observado

El 2026-09-13 se publicó y registró correctamente el workflow `Project 04
CI`. GitHub Actions está habilitado en el repositorio y permite acciones. Se
inició una ejecución manual de control, pero terminó inmediatamente con
`startup_failure`.

La plataforma no creó jobs, no asignó un runner y no generó logs. Por tanto,
el fallo ocurrió antes de `checkout`, Node.js, `npm ci`, pruebas o el Docker
build.

## Controles descartados

- El workflow está activo y registrado por GitHub.
- El permiso declarado es solamente `contents: read`.
- La configuración del repositorio permite acciones.
- La validación equivalente local sí pasó: 6 pruebas y build de Docker.

## Conclusión

El workflow queda implementado, pero su ejecución remota está bloqueada por
una condición de GitHub Actions externa al repositorio. No se debe interpretar
como una falla del código, imagen o AWS.

## Próxima verificación requerida

El bloqueo de facturación se resolvió y se repitió la ejecución manual. El run
completó correctamente el job `test-and-build`: checkout, Node.js, `npm ci`,
las seis pruebas del backend y Docker build. La evidencia está disponible en
el historial de GitHub Actions del repositorio.

La puerta de CI queda aprobada para preparar la publicación futura a ECR. La
publicación y cualquier despliegue a ECS continúan pendientes de un Cost Check
y una autorización AWS específica.

## Deliberadamente no realizado

No se creó OIDC, IAM, ECR, ECS, ALB, CloudWatch Logs, secretos ni ningún
recurso AWS.
