# Validación Terraform — Data module

## Alcance validado

El módulo `terraform/modules/data` y su invocación desde `terraform/environments/lab` definen el DB subnet group y la instancia PostgreSQL aislada de desarrollo.

## Comandos ejecutados

```powershell
terraform fmt -recursive
terraform init -backend=false -input=false
terraform validate
```

## Resultado

Terraform cargó el módulo local y confirmó que la configuración es válida. No se pasó un valor de contraseña, no se ejecutó `terraform plan` ni `terraform apply`.

No se creó, consultó, importó, actualizó o eliminó DB subnet group, RDS, snapshot, parámetro SSM ni recurso AWS.

## Guardrail de despliegue futuro

Antes de un plan hay que verificar disponibilidad de engine, precio vigente y la estrategia de teardown. Un apply de RDS requiere aprobación explícita y la contraseña debe proporcionarse solo mediante un canal local seguro.
