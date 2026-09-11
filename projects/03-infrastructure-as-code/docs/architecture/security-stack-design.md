# Diseño CloudFormation — Security stack

## Contenido

El template `cloudformation/stacks/02-security.yaml` modela los tres Security Groups, el role EC2 y su Instance Profile. Recibe la VPC como parámetro; por eso no administra ni importa la VPC existente del Proyecto 1.

## Reglas efectivas

| Grupo | Inbound | Outbound |
| --- | --- | --- |
| ALB | TCP 80 desde la prefix list origin-facing de CloudFront. | TCP 3000 solo hacia App. |
| App | TCP 3000 solo desde ALB. | TCP 5432 a DB; TCP 80/443 a Internet para la topología de desarrollo sin NAT. |
| DB | TCP 5432 solo desde App. | Sin tráfico externo. |

No se permite SSH, acceso directo a App ni acceso público a PostgreSQL.

CloudFormation añade una regla de salida por defecto si no se declara ninguna. Cada Security Group declara por ello una regla local `127.0.0.1/32` para retirar ese default; las reglas de negocio se definen por separado con `AWS::EC2::SecurityGroupIngress` y `AWS::EC2::SecurityGroupEgress`. La regla local no permite salida hacia otros hosts.

## IAM

El role solo puede ser asumido por EC2, incluye `AmazonSSMManagedInstanceCore` y obtiene un único parámetro SSM de contraseña por path. No crea el parámetro ni proporciona valor alguno. Los permisos S3 y CloudWatch se añadirán desde las capas que creen el bucket de artefactos y el Log Group, evitando dependencias circulares.

El ID de la prefix list CloudFront no se versiona porque varía por región. Será un parámetro requerido en un despliegue futuro, obtenido mediante una consulta de solo lectura y revisado antes de aplicar.
