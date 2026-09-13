# Preparación para publicación a ECR

## Recurso creado

Se creó un único repositorio privado, aislado, en `us-east-1`:

```text
portfolio-p04-task-manager
```

## Configuración aplicada

| Control | Valor | Razón |
|---|---|---|
| Visibilidad | Privado | La imagen no debe exponerse públicamente. |
| Tag mutability | Inmutable | Cada SHA de Git es una versión trazable y no se sobrescribe. |
| Cifrado | AES-256 administrado por ECR | Evita una clave KMS adicional para este laboratorio. |
| Lifecycle policy | Conservar como máximo 10 imágenes etiquetadas | Limita almacenamiento acumulado. |
| Tags | Project, ProjectNumber, Environment, ManagedBy | Facilita inventario y cleanup. |

La política de ciclo de vida conserva como máximo diez imágenes con etiqueta
`sha-` y elimina imágenes sin etiqueta tras un día. El repositorio se creó
vacío: todavía no hay imágenes, capas ni publicación desde GitHub.

El valor local de referencia fue una imagen de aproximadamente 49.6 MB. Eso
no garantiza su tamaño comprimido final en ECR; conservar hasta diez versiones
es un límite preventivo, no una estimación de costo.

## Publicación futura

La ruta de CI actual solo construye la imagen. La publicación requerirá una
segunda etapa manual y una identidad OIDC de mínimo privilegio para
autenticarse sin Access Keys. El proveedor y el rol OIDC siguen pendientes;
su diseño detallado está en `github-oidc-ecr-publisher.md`.

## Verificación posterior a una creación aprobada

1. Confirmar que existe únicamente el repositorio esperado y sus tags.
2. Confirmar inmutabilidad y lifecycle policy.
3. Ejecutar un push manual local controlado o la etapa OIDC aprobada.
4. Verificar URI, digest y resultado de escaneo disponible, sin revelar
   credenciales de registro.

## Primera publicación controlada

La primera publicación mediante OIDC se ejecutó manualmente desde `main` y
terminó correctamente. El workflow autenticó con credenciales temporales,
construyó la imagen y publicó un único tag `sha-<commit>`. La verificación
posterior por AWS CLI confirmó una sola imagen, su digest y las dos reglas de
lifecycle. La evidencia no incluye credenciales de registro ni el ARN de la
cuenta; está registrada en
`docs/validation/ecr-publication-validation.md`.

## Teardown

Eliminar el repositorio requerirá primero retirar las imágenes o una operación
forzada. Ambas son destructivas y necesitarán autorización explícita en ese
momento.
