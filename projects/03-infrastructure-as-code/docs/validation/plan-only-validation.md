# Estrategia de validación sin apply

## CloudFormation

1. Validar sintaxis y estructura local.
2. Ejecutar `aws cloudformation validate-template` por template cuando AWS CLI esté configurado.
3. Revisar parámetros, outputs y dependencias.
4. No ejecutar `create-stack`, `deploy`, Change Set ejecutable ni importación de recursos sin aprobación nueva.

## Terraform

1. Instalar Terraform solo después de comprobar que realmente falta y obtener aprobación explícita.
2. Ejecutar `terraform fmt -check` y `terraform validate`.
3. Usar `terraform init -backend=false` durante el bootstrap para no crear backend remoto ni state compartido.
4. Un futuro `terraform plan` debe usar variables de laboratorio sin secretos y se revisará antes de autorizar un `apply`.

## Criterio de salida de la fase de validación

- Todos los templates y módulos pasan validación.
- No hay secretos, estado Terraform, IDs de cuenta, endpoints o valores de producción en Git.
- La equivalencia de recursos y dependencias entre CloudFormation y Terraform está documentada.
- `git diff --check` y las pruebas locales aplicables pasan antes de cada commit.
