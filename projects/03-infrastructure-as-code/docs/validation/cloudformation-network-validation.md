# Validación CloudFormation — Network stack

## Alcance validado

Template: `cloudformation/stacks/01-network.yaml`.

El template modela la red de referencia del Proyecto 1 con un prefijo aislado para un futuro laboratorio del Proyecto 3. Incluye VPC, Internet Gateway, dos route tables, seis subnets y asociaciones de route table. No incluye NAT Gateway, cómputo, RDS, S3, CloudFront ni secretos.

## Comando ejecutado

```powershell
aws cloudformation validate-template `
  --template-body file://cloudformation/stacks/01-network.yaml `
  --profile portfolio-root-temp `
  --region us-east-1 `
  --no-cli-pager
```

## Resultado

La validación fue exitosa. `validate-template` comprueba la estructura del template contra CloudFormation; no crea un stack ni recursos AWS.

## Próxima validación

Los stacks posteriores consumirán los outputs de red mediante parámetros. El futuro `deploy`, Change Set ejecutable o `apply` está fuera de este alcance y requerirá un Cost Check y aprobación explícita.
