# Preparación para publicación a ECR

## Recurso propuesto

Un único repositorio privado, aislado, en `us-east-1`:

```text
portfolio-p04-task-manager
```

## Configuración propuesta

| Control | Valor | Razón |
|---|---|---|
| Visibilidad | Privado | La imagen no debe exponerse públicamente. |
| Tag mutability | Inmutable | Cada SHA de Git es una versión trazable y no se sobrescribe. |
| Cifrado | AES-256 administrado por ECR | Evita una clave KMS adicional para este laboratorio. |
| Lifecycle policy | Conservar como máximo 10 imágenes etiquetadas | Limita almacenamiento acumulado. |
| Tags | Project, ProjectNumber, Environment, ManagedBy | Facilita inventario y cleanup. |

El valor local de referencia fue una imagen de aproximadamente 49.6 MB. Eso
no garantiza su tamaño comprimido final en ECR; conservar hasta diez versiones
es un límite preventivo, no una estimación de costo.

## Publicación futura

La ruta de CI actual solo construye la imagen. La publicación requerirá una
segunda etapa, bloqueada hasta que la primera tenga éxito, y una identidad OIDC
de mínimo privilegio para autenticarse sin Access Keys. OIDC no será creado en
el mismo paso que el repositorio sin revisar por separado su trust policy.

## Verificación posterior a una creación aprobada

1. Confirmar que existe únicamente el repositorio esperado y sus tags.
2. Confirmar inmutabilidad y lifecycle policy.
3. Ejecutar un push manual local controlado o la etapa OIDC aprobada.
4. Verificar URI, digest y resultado de escaneo disponible, sin revelar
   credenciales de registro.

## Teardown

Eliminar el repositorio requerirá primero retirar las imágenes o una operación
forzada. Ambas son destructivas y necesitarán autorización explícita en ese
momento.
