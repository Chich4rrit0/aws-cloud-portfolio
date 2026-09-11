# Diseño CloudFormation — Operations stack

## Contenido

El template `cloudformation/stacks/07-operations.yaml` define la alarma de ausencia de targets saludables de la arquitectura final del Proyecto 1. Usa la métrica nativa `AWS/ApplicationELB` `HealthyHostCount` con las dimensiones del ALB y Target Group creados por Compute.

La alarma entra en estado de alerta si el mínimo de hosts saludables es menor que uno durante dos períodos consecutivos de 60 segundos. Los datos ausentes se tratan como `notBreaching` y `ActionsEnabled` queda explícitamente en `false`.

## Límites intencionales

No se crean SNS, correos, webhooks, dashboards, métricas personalizadas, VPC Flow Logs, ALB access logs ni fuentes extra de logs. El Log Group con retención de siete días y sus permisos runtime pertenecen al Compute stack, evitando propiedad duplicada entre stacks.

## Dependencias y costo

Operations requiere los valores `LoadBalancerFullName` y `TargetGroupFullName` expuestos por Compute. Una alarma puede tener cargo según el uso y Free Tier aplicable; se verificará el precio vigente antes de desplegar. Sin acciones, la alarma no detiene ni escala recursos: es una señal visible que requerirá respuesta operativa manual.
