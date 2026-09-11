# Terraform foundation — Validación pendiente

## Estado

La estructura Terraform fue escrita localmente, pero Terraform no está instalado en la estación de trabajo. Por ello no se declara una validación ejecutada.

## Alcance que se validará tras aprobación

Desde `terraform/environments/lab`:

```powershell
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

`init -backend=false` descarga únicamente los providers requeridos y evita inicializar o crear un backend remoto. `validate` revisa sintaxis y referencias estáticas; ninguno crea infraestructura. `terraform plan` y `terraform apply` quedan fuera de esta etapa.
