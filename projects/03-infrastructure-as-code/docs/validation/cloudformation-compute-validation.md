# Validación CloudFormation — Compute stack

## Alcance validado

Template: `cloudformation/stacks/05-compute.yaml`.

El template expresa el ALB, Target Group, Launch Template, Auto Scaling Group, Log Group de aplicación y permisos runtime adicionales para la reconstrucción aislada del Proyecto 1.

## Comando ejecutado

```powershell
aws cloudformation validate-template `
  --template-body file://cloudformation/stacks/05-compute.yaml `
  --profile portfolio-root-temp `
  --region us-east-1 `
  --no-cli-pager
```

## Resultado

La validación fue exitosa. No se creó un stack, ALB, Target Group, Launch Template, Auto Scaling Group, instancia EC2, Log Group, objeto S3 ni política IAM.

## Guardrail de despliegue futuro

Un despliegue de esta capa genera costos por ALB, EC2/ASG, almacenamiento y logs. Requiere primero las capas Network, Security, Data y Storage; además de un release ZIP aprobado, endpoint RDS, parámetro SSM de contraseña de aplicación y un Cost Check actualizado. El listener se mantiene en `403` hasta que el Edge stack agregue el control de origen CloudFront.
