# Diseño Terraform — Foundation local

## Decisión aplicada

Terraform reproduce la misma arquitectura aislada de CloudFormation mediante módulos por capa: `network`, `security`, `data`, `storage`, `compute`, `edge` y `operations`.

El entorno inicial `terraform/environments/lab` fija `us-east-1`, el prefijo `p03`, etiquetas comunes y rangos de compatibilidad para Terraform y el provider AWS. Todavía no invoca módulos ni define recursos: es una base revisable sin efecto en AWS.

## Estado y credenciales

No hay bloque `backend`; Terraform usará su backend local predeterminado cuando se inicialice. Los archivos de estado están ignorados por Git. No se creará un bucket S3, tabla DynamoDB, rol de CI ni backend remoto durante esta fase.

Las credenciales no son variables Terraform y no se escriben en `.tf`, `.tfvars` o documentación. En una validación futura se usará el perfil local ya configurado solo en la sesión de PowerShell, sin exponer sus valores.

## Próximos controles

Antes de ejecutar Terraform se debe aprobar su instalación local. Después se ejecutarán `terraform fmt -check`, `terraform init -backend=false` y `terraform validate`; no se ejecutará `plan` contra AWS ni `apply` sin un Cost Check y aprobación explícita.
