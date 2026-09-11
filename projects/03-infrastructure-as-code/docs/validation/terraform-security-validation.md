# Validación Terraform — Security module

## Alcance validado

El módulo `terraform/modules/security` y su invocación desde `terraform/environments/lab` definen Security Groups sin egress implícito, reglas de mínimo privilegio, rol EC2 e instance profile.

## Comandos ejecutados

```powershell
terraform fmt -recursive
terraform init -backend=false -input=false
terraform validate
```

## Resultado

Terraform formateó el código, cargó el módulo local y confirmó que la configuración es válida. No se ejecutó `terraform plan` ni `terraform apply`.

No se consultó ni creó VPC, Security Group, rol IAM, instance profile, parámetro SSM o recurso AWS alguno.

## Guardrail de despliegue futuro

Antes de un plan se debe obtener el ID regional real de la prefix list CloudFront, confirmar el perfil AWS y revisar el Cost Check. Un apply de IAM o Security Groups requiere aprobación explícita, aunque no tenga un precio por hora directo.
