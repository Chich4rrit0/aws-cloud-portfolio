# Validación — construcción local del contenedor

## Resultado

El 2026-09-13 se validó localmente la imagen
`portfolio-p04-task-manager:local` con Docker Desktop Linux.

| Control | Resultado |
|---|---|
| Docker client / server | 29.7.2 / 29.7.2 |
| Base image | `node:20.19.2-alpine`, resuelta a digest durante el build |
| Dependencias | `npm ci --omit=dev` completado sin vulnerabilidades reportadas |
| Ejecución | Usuario no privilegiado `node` |
| Health endpoint | `/health` respondió `status: ok` por loopback |
| Contenedores residuales | Ninguno |
| Suite del backend | 6 pruebas aprobadas, 0 fallidas |

La imagen local resultante mide aproximadamente 49.6 MB. Permanece solo en
Docker Desktop local; no se ha publicado a Docker Hub, ECR ni otro registro.

## Límites de la prueba

El contenedor se ejecutó con el store en memoria por defecto. No se conectó a
RDS, Parameter Store, AWS ni recursos de los proyectos cerrados.
