# Diseño CloudFormation — Storage stack

## Contenido

El template `cloudformation/stacks/04-storage.yaml` define dos buckets privados y separados:

- **Artifact bucket:** releases ZIP inmutables para las instancias EC2.
- **Frontend bucket:** origen privado de una distribución CloudFront posterior.

## Controles

Ambos buckets usan bloqueo total de acceso público, `BucketOwnerEnforced` y SSE-S3 (`AES256`). No activan website hosting, ACLs públicas, políticas públicas ni logging adicional.

Los nombres físicos se forman en tiempo de despliegue con prefijo, cuenta y región. Ningún ID de cuenta o nombre concreto queda escrito en Git.

## Dependencias

El Compute stack consumirá el nombre/ARN del artifact bucket para limitar el role EC2 a `releases/*`. El Edge stack creará posteriormente OAC y la bucket policy del frontend; separar esa policy evita conceder acceso CloudFront antes de que exista una distribución específica.

## Costo y limpieza

S3 cobra por almacenamiento, solicitudes y transferencia según uso. El modo plan no crea buckets ni objetos. Un teardown futuro debe vaciar los buckets antes de borrarlos; eliminar un bucket puede destruir releases y frontend si no se conservan copias aprobadas.
