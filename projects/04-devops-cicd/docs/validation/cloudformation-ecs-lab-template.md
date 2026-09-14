# Validación CloudFormation — Laboratorio ECS/Fargate

## Alcance

Validación estática del template
`infrastructure/cloudformation/ecs-fargate-lab.yaml` mediante
`aws cloudformation validate-template`. Esta operación no creó un stack ni
recursos AWS.

## Resultado

| Control | Resultado |
|---|---|
| Sintaxis y estructura CloudFormation | Válidas. |
| Parámetros | `ProjectPrefix` con valor predeterminado e `ImageUri` obligatorio. |
| Capacidad requerida | `CAPABILITY_NAMED_IAM`, debido al execution role ECS nombrado. |
| Dependencias circulares | Detectadas inicialmente entre security groups; corregidas antes de la validación final. |
| Recursos creados | Ninguno. |

## Corrección aplicada

El primer diseño definía la salida del security group del ALB hacia el security
group de tarea y la entrada de la tarea desde el ALB. CloudFormation identificó
esa referencia bidireccional como una dependencia circular. La salida del ALB
se restringió al puerto 3000 del CIDR `10.40.0.0/16`; la entrada de la tarea
mantiene la referencia estricta al security group del ALB. Así el ALB no tiene
salida general a Internet y el template puede resolverse.

## Límites

La validación no comprueba capacidad regional, cuotas, arranque de Fargate,
salud del target ni costo real. Esas verificaciones ocurrirán únicamente en
una ejecución temporal aprobada.
