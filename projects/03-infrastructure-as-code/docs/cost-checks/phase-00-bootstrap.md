# Cost Check — Project 03 Phase 00: bootstrap IaC

## Recursos creados

Solo carpetas y documentación locales versionables. No se creó infraestructura AWS, backend Terraform, bucket S3, tabla DynamoDB, secret ni state file.

## Costo estimado

Sin costo AWS de infraestructura en esta fase. La validación de sintaxis local no crea recursos. Una futura validación CloudFormation puede realizar una llamada de control plane, pero no debe crear un stack; Terraform `validate` no requiere aplicar infraestructura.

## Costo real

No corresponde declarar costo real de AWS: no se creó ni ejecutó infraestructura del Proyecto 3.

## Recursos que se pueden apagar o eliminar

No existen recursos AWS nuevos que apagar o eliminar.

## Riesgo de costo inesperado

El riesgo aparece solo si se usa accidentalmente `aws cloudformation deploy`, `create-stack`, `terraform apply`, un backend remoto o un script sin guardrails. Los scripts de este proyecto deberán separar explícitamente `validate`, `plan` y cualquier futura acción de apply.
