# CI con GitHub Actions

## Propósito

`.github/workflows/project-04-ci.yml` valida los cambios relevantes al
Proyecto 4 y al backend de referencia de Proyecto 1. El workflow se ejecuta
en pull requests, en `main` y manualmente con `workflow_dispatch`, con filtros
de rutas para evitar ejecuciones innecesarias en documentación o proyectos no
relacionados.

## Controles

1. El `GITHUB_TOKEN` tiene únicamente `contents: read`.
2. Se usa Node.js 20.19.2, `npm ci` y la caché de npm basada en el lockfile.
3. Se ejecuta la suite completa del backend.
4. Se construye la imagen con el Dockerfile del Proyecto 4 y una etiqueta
   ligada al SHA del commit.

El workflow no publica la imagen, no autentica contra AWS, no usa secretos y
no modifica infraestructura. ECR, OIDC y ECS pertenecerán a fases posteriores
con permisos y aprobaciones independientes.

## Validación esperada

Tras publicar el workflow, la ejecución `Project 04 CI` debe mostrar una sola
tarea `test-and-build` aprobada en GitHub Actions. Un fallo de pruebas o build
debe impedir las etapas futuras de publicación y despliegue.
