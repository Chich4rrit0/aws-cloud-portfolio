# Diseño Terraform — Storage module

## Equivalencia

`terraform/modules/storage` define buckets privados separados para artefactos y frontend. Sus nombres se construyen con prefijo, cuenta y región en tiempo de plan, sin account IDs escritos en Git.

Ambos aplican bloqueo completo de acceso público, `BucketOwnerEnforced` y cifrado SSE-S3. El módulo no crea objetos, hosting web, ACLs, políticas de bucket ni permisos CloudFront.

## Límites

Compute consumirá el bucket de artefactos; Edge agregará OAC y la policy del frontend solo cuando exista una distribución específica. `force_destroy = false` protege contra la eliminación accidental de objetos durante un futuro teardown.
