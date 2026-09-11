# Validación CloudFormation — Data stack

## Alcance validado

Template: `cloudformation/stacks/03-data.yaml`.

El template define un DB subnet group y una instancia RDS PostgreSQL de desarrollo con red privada, cifrado, Single-AZ, backup de un día y una contraseña maestra parametrizada como `NoEcho`.

## Comando ejecutado

```powershell
aws cloudformation validate-template `
  --template-body file://cloudformation/stacks/03-data.yaml `
  --profile portfolio-root-temp `
  --region us-east-1 `
  --no-cli-pager
```

## Resultado

La validación fue exitosa. No se proporcionó contraseña, no se creó DB subnet group, instancia RDS, snapshot, parámetro SSM ni stack.

## Guardrail de despliegue futuro

Antes de cualquier despliegue se debe verificar la versión PostgreSQL disponible en la región, evaluar precio actualizado, suministrar la contraseña solo desde un canal local seguro y decidir explícitamente la estrategia de snapshot/teardown.
