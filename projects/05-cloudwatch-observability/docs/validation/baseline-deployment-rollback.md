# Validación — rollback del primer despliegue de baseline

Fecha: 2026-09-14.

## Resultado

El primer intento de crear `portfolio-p05-observability` terminó en
`ROLLBACK_COMPLETE`. CloudFormation eliminó correctamente dashboard, alarmas y
queries guardadas; la inspección posterior no encontró recursos P5 residuales.

## Causa

El dashboard recibió valores nulos para las dimensiones de ALB y target group.
La API `describe-load-balancers` y `describe-target-groups` devuelve ARN, pero
no las propiedades `LoadBalancerFullName` y `TargetGroupFullName` que se usan
en métricas `AWS/ApplicationELB`.

## Corrección

El script de despliegue ahora deriva ambos valores desde sus ARN, valida que no
estén vacíos y solo entonces construye los parámetros del template. No cambió
P2, P4, las alarmas existentes ni el diseño aprobado del baseline.

## Próxima acción controlada

Se requiere eliminar el stack vacío en `ROLLBACK_COMPLETE` antes de un nuevo
intento. Esa eliminación no debe tocar recursos P2/P4 ni recursos P5 ya que el
rollback los removió; aun así, requiere aprobación explícita.
