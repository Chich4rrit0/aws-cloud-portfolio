# Fundación de datos aplicada — Project 02

## Estado verificado

| Recurso | Estado | Configuración confirmada |
| --- | --- | --- |
| DynamoDB `portfolio-p02-links` | `ACTIVE` | On-Demand (`PAY_PER_REQUEST`), clase `STANDARD`, PK `shortCode` String, TTL `expiresAt` habilitado, sin protección de borrado. |
| CloudWatch Log Group `/aws/lambda/portfolio-p02-link-shortener` | Disponible | Retención de 7 días. |

Ambos recursos tienen los tags `Project=aws-cloud-portfolio`, `ProjectNumber=02`, `Environment=lab` y `ManagedBy=aws-cli`.

## Qué no se creó

No hay Lambda, API Gateway, Cognito, roles IAM del Proyecto 2, VPC, NAT Gateway, EC2, ALB, RDS, S3, CloudFront ni Route 53.

La tabla está vacía porque aún no existe una Lambda ni ruta que pueda escribir datos. El Log Group también está vacío mientras no exista la función Lambda asociada.

## Verificación aplicada

Se verificó mediante AWS CLI que la tabla está activa, usa `PAY_PER_REQUEST`, tiene clase `STANDARD` y TTL sobre `expiresAt`. También se verificaron la retención de 7 días y los tags del Log Group. No se registran ARNs, IDs de cuenta ni endpoints en este repositorio.

## Limpieza futura

`delete-table` destruirá todos los enlaces de la tabla y `delete-log-group` destruirá los logs. Ninguna de esas operaciones se ejecutará sin una confirmación destructiva explícita. Mientras el laboratorio esté pausado, no existe un servidor que apagar: la medida es no generar solicitudes ni logs y eliminar recursos al cerrar la demostración.
