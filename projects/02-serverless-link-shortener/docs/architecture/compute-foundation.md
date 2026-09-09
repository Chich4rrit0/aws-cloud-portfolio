# Fundación de cómputo aplicada — Project 02

## Estado verificado

| Recurso | Estado | Configuración confirmada |
| --- | --- | --- |
| IAM role `portfolio-p02-lambda-role` | Disponible | Trust exclusivo para Lambda y una política inline mínima. |
| Lambda `portfolio-p02-link-shortener` | `Active`, pausada | `nodejs22.x`, `arm64`, 128 MiB, timeout 3 s, handler `src/lambda-handler.handler`, variable `LINKS_TABLE_NAME`. |

La política permite únicamente `logs:CreateLogStream` y `logs:PutLogEvents` sobre el Log Group del Proyecto 2, y `dynamodb:GetItem`, `dynamodb:PutItem` y `dynamodb:DeleteItem` sobre `portfolio-p02-links`.

## Corrección de concurrencia

La cuota de concurrencia de la cuenta no permitió reservar dos ejecuciones positivas: AWS exige conservar concurrencia sin reservar y la cuota disponible es demasiado baja. Por ello la función tiene concurrencia reservada `0`.

Este valor bloquea cualquier invocación y no deja cómputo encendido. Antes de pruebas controladas se requerirá una aprobación explícita para quitar el límite mediante `delete-function-concurrency`; API Gateway aplicará además throttling cuando se cree.

## Qué no se creó

No hay API Gateway, Cognito, permiso público de invocación, VPC, NAT Gateway, EC2, ALB, RDS, S3, CloudFront ni Route 53. La Lambda no se invocó durante la creación, por lo que no existen enlaces de prueba ni logs de aplicación.

## Limpieza futura

Eliminar la función primero, y luego su política inline y rol. Son acciones destructivas de infraestructura y requerirán confirmación explícita; no afectan la tabla o Log Group si se ejecutan por separado.
