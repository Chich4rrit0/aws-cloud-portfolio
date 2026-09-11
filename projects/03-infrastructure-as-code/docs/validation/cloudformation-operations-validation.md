# Validación CloudFormation — Operations stack

## Alcance validado

Template: `cloudformation/stacks/07-operations.yaml`.

El template define una alarma `AWS/ApplicationELB` sobre `HealthyHostCount`: mínimo menor que uno por dos períodos consecutivos de 60 segundos. Sus acciones están explícitamente deshabilitadas y los datos ausentes se tratan como no breaching.

La validación también se repitió para `cloudformation/stacks/05-compute.yaml` después de añadir los outputs de dimensiones consumidos por Operations.

## Comandos ejecutados

```powershell
aws cloudformation validate-template `
  --template-body file://cloudformation/stacks/05-compute.yaml `
  --profile portfolio-root-temp `
  --region us-east-1 `
  --no-cli-pager

aws cloudformation validate-template `
  --template-body file://cloudformation/stacks/07-operations.yaml `
  --profile portfolio-root-temp `
  --region us-east-1 `
  --no-cli-pager
```

## Resultado

Ambas validaciones fueron exitosas. No se creó un stack, alarma, SNS topic, dashboard, Log Group, métrica personalizada ni acción automática.

## Guardrail de despliegue futuro

Un despliegue requiere primero un ALB y Target Group aislados de Compute. La alarma no detiene recursos ni notifica a nadie mientras `ActionsEnabled` sea `false`; un destino SNS solo podrá añadirse tras una decisión explícita y un Cost Check actualizado.
