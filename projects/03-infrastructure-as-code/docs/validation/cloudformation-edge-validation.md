# Validación CloudFormation — Edge stack

## Alcance validado

Template: `cloudformation/stacks/06-edge.yaml`.

El template expresa la distribución CloudFront, Origin Access Control, bucket policy privada, rutas dinámicas hacia el ALB, regla del header origin-only y el parámetro `SecureString` que conservaría ese valor en un despliegue aprobado.

## Comando ejecutado

```powershell
aws cloudformation validate-template `
  --template-body file://cloudformation/stacks/06-edge.yaml `
  --profile portfolio-root-temp `
  --region us-east-1 `
  --no-cli-pager
```

## Resultado

La validación fue exitosa. No se introdujo un valor de header, ni se creó una distribución CloudFront, OAC, bucket policy, regla ALB, parámetro SSM, invalidación u objeto S3.

## Guardrail de despliegue futuro

El despliegue exige outputs de Storage y Compute, además de un header generado localmente y pasado como parámetro `NoEcho`. Antes de aprobarlo se debe revisar la prioridad disponible del listener, los precios vigentes de CloudFront/S3 y el Cost Check. La distribución pública usa el dominio predeterminado, sin WAF ni dominio propio; ese riesgo debe aceptarse explícitamente para un laboratorio.
