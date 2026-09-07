# ADR-012 — Artefactos de despliegue privados en S3

- Estado: Aceptado
- Fecha: 2026-09-07

## Contexto

El repositorio de portafolio es privado. Una instancia EC2 no debe recibir un token personal de GitHub para clonar código ni una clave estática de AWS para obtener artefactos.

## Decisión

Se usará un bucket S3 privado dedicado a artefactos de Project 01. El nombre se generará con el ID de cuenta y región para evitar colisiones globales. El bucket tendrá bloqueo total de acceso público, Object Ownership `BucketOwnerEnforced` y cifrado SSE-S3.

La instancia EC2 recibirá una política adicional limitada a `s3:GetObject` sobre el prefijo `releases/*`. No tendrá permiso para listar, escribir o borrar objetos.

Los ZIP se construirán localmente desde el contenido versionado y llevarán el hash corto del commit Git en su nombre. `node_modules` y cualquier `.env` local se excluyen del paquete.

## Consecuencias

- La instancia descarga una versión inmutable identificable sin secretos de GitHub.
- S3 agrega costos por almacenamiento y solicitudes, aunque el uso esperado de ZIP pequeños es bajo.
- El bucket de artefactos es distinto del futuro bucket S3 del frontend para no mezclar un origen público de CloudFront con binarios de despliegue.
