# Validación CloudFormation — Security stack

## Alcance validado

Template: `cloudformation/stacks/02-security.yaml`.

El template modela tres Security Groups separados, referencias ALB → App → DB, el role de runtime EC2 y el Instance Profile. No contiene Access Keys, contraseñas, SSH ni valores específicos de cuenta.

## Comando ejecutado

```powershell
aws cloudformation validate-template `
  --template-body file://cloudformation/stacks/02-security.yaml `
  --profile portfolio-root-temp `
  --region us-east-1 `
  --no-cli-pager
```

## Resultado

La validación fue exitosa. La llamada validó la estructura del template sin crear roles, Instance Profiles, Security Groups, parámetros SSM ni stacks.

## Controles pendientes de capas posteriores

El ID de la prefix list CloudFront se proporcionará solamente en un futuro despliegue. Los permisos S3 de artefactos y CloudWatch Logs se añadirán cuando sus recursos aislados estén definidos, evitando una dependencia circular entre stacks.
