# Diseño Terraform — Foundation local

## Decisión aplicada

Terraform reproduce la misma arquitectura aislada de CloudFormation mediante módulos por capa: `network`, `security`, `data`, `storage`, `compute`, `edge` y `operations`.

El entorno inicial `terraform/environments/lab` fija `us-east-1`, el prefijo aislado `portfolio-p03`, etiquetas comunes y rangos de compatibilidad para Terraform y el provider AWS. Todavía no invoca módulos fuera de las capas aprobadas ni aplica recursos: es una base revisable sin efecto en AWS.

## Estado y credenciales

No hay bloque `backend`; Terraform usará su backend local predeterminado cuando se inicialice. Los archivos de estado están ignorados por Git. No se creará un bucket S3, tabla DynamoDB, rol de CI ni backend remoto durante esta fase.

Las credenciales no son variables Terraform y no se escriben en `.tf`, `.tfvars` o documentación. En una validación futura se usará el perfil local ya configurado solo en la sesión de PowerShell, sin exponer sus valores.

## Controles aplicados

Terraform se instaló de forma portable y se validó con `terraform fmt -check`, `terraform init -backend=false` y `terraform validate`. El archivo de lock se conserva en Git para fijar la versión y checksums del provider usado durante la validación.

`terraform plan` contra AWS y `terraform apply` siguen fuera de alcance. Ambos requerirán un Cost Check y aprobación explícita.
