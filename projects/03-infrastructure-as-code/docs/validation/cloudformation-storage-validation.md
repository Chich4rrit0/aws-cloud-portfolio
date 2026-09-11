# Validación CloudFormation — Storage stack

## Alcance validado

Template: `cloudformation/stacks/04-storage.yaml`.

El template define un bucket privado para artefactos de despliegue y otro bucket privado para el frontend. Ambos aplican bloqueo total de acceso público, propiedad de objetos impuesta por el bucket y cifrado SSE-S3.

## Comando ejecutado

```powershell
aws cloudformation validate-template `
  --template-body file://cloudformation/stacks/04-storage.yaml `
  --profile portfolio-root-temp `
  --region us-east-1 `
  --no-cli-pager
```

## Resultado

La validación fue exitosa. No se creó ningún bucket, objeto, política de bucket, distribución CloudFront ni stack.

## Guardrail de despliegue futuro

Antes de desplegar se debe revisar el costo vigente de S3 y decidir la retención de releases. Un teardown debe vaciar explícitamente ambos buckets antes de eliminarlos; esa operación puede destruir artefactos y frontend si no existen copias conservadas.
