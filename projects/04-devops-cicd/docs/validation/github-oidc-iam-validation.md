# Validación IAM OIDC — Proyecto 4

## Fecha y alcance

Validación posterior a la creación aprobada del proveedor IAM OIDC de GitHub y
del rol de publicación ECR. Las consultas fueron de solo lectura y no
publicaron imágenes.

## Resultado

| Control | Resultado |
|---|---|
| URL del proveedor OIDC | `token.actions.githubusercontent.com` verificada. |
| Audiencia | Incluye únicamente `sts.amazonaws.com` para este uso. |
| Rol | Existe `portfolio-p04-github-actions-ecr-publisher`. |
| Sujeto de confianza | Usa el formato inmutable de GitHub para el propietario, repositorio y rama `main`. |
| Restricción adicional | Exige `repository_owner_id`, `repository_id` y `refs/heads/main`. |
| Permisos ECR | Token de registro más seis acciones mínimas de carga/lectura de manifiesto. |
| Alcance ECR | Un único repositorio del Proyecto 4. |
| Permisos excluidos | Sin eliminación, creación de recursos, cambios de política ECR ni acciones ECS. |
| Estado de imágenes | Cero imágenes en ECR. |

## Hallazgo y corrección local

El primer script leía la respuesta de `get-role-policy` mediante una ruta JSON
que no correspondía a la respuesta actual del AWS CLI. La política AWS estaba
correctamente creada, pero el verificador local no podía demostrarlo. Se
corrigió la ruta a `PolicyDocument` y se añadió una comparación de las siete
acciones exactas esperadas. No fue necesario modificar el rol ni su política.

## Límites de esta validación

No se solicitó aún un token OIDC desde GitHub, no se construyó ni publicó una
imagen remota, y no se creó ningún componente de ECS/Fargate o ALB. La prueba
del workflow manual y el primer push se realizarán solo con una revisión de
costo y autorización separada.
