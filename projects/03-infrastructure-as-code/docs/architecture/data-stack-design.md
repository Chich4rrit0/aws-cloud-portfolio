# Diseño CloudFormation — Data stack

## Contenido

El template `cloudformation/stacks/03-data.yaml` define el DB subnet group y una instancia RDS PostgreSQL de desarrollo. Recibe subnets privadas y el Security Group de DB como parámetros de stacks anteriores; no importa recursos existentes.

## Configuración equivalente al Proyecto 1

| Control | Configuración |
| --- | --- |
| Motor | PostgreSQL, versión `18.3` parametrizada. |
| Tamaño | `db.t3.micro`. |
| Almacenamiento | 20 GiB gp3, cifrado con la clave AWS-managed de RDS. |
| Disponibilidad | Single-AZ. |
| Red | DB subnet group de dos subnets privadas, sin acceso público y SG de DB. |
| Backups | Un día de retención. |
| Borrado | Deletion protection desactivada; `DeletionPolicy: Delete` para un laboratorio efímero. |

## Secretos y bootstrap

`MasterUserPassword` es un parámetro `NoEcho` obligatorio sin valor por defecto. El template no crea un secret con valor conocido ni versiona un archivo de parámetros con contraseña.

Tras un despliegue futuro, un bootstrap temporal y aprobado deberá crear el usuario de aplicación, almacenarlo en el path SSM específico de Proyecto 3 y confirmar TLS. La aplicación no debe usar el usuario maestro de RDS como identidad de runtime.

## Costo y riesgo

RDS es uno de los recursos de mayor costo recurrente del baseline. El modo plan no crea el DB subnet group ni la instancia. Cualquier `deploy` futuro exige verificar disponibilidad regional de la versión, estimar costo actual, decidir explícitamente el snapshot final y programar teardown.
