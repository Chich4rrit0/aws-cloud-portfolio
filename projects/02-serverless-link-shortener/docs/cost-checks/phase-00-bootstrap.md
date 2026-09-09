# Cost Check — Project 02, Phase 0 bootstrap

## Recursos creados

- Solo directorios y documentación local dentro del repositorio Git.

## Recursos AWS creados

- Ninguno.

## Costos generados

- Ninguno por este bootstrap local.

## Riesgo de costo futuro identificado

- API Gateway HTTP API: requests y transferencia según uso.
- Lambda: invocaciones y duración.
- DynamoDB On-Demand: requests y almacenamiento.
- Cognito: dependerá de usuarios activos y configuración elegida.
- CloudWatch Logs: ingestión y almacenamiento.

## Controles antes de implementar

- Mantener el budget existente como alerta temprana; no confundirlo con una pausa automática.
- No crear VPC, NAT Gateway, EC2, ALB, RDS, CloudFront, dominio o frontend en la primera versión.
- Definir retención de logs, TTL, límites de request y estrategia de cleanup antes del primer recurso AWS.
