# Cost Check — Phase 01: diseño técnico

## Recursos creados

Ninguno. Esta fase solo define contratos, límites y decisiones locales.

## Recursos que podrían generar costo al implementar

- Solicitudes de API Gateway HTTP API.
- Invocaciones y duración de Lambda.
- Solicitudes y almacenamiento DynamoDB On-Demand; TTL elimina datos de forma eventual.
- Usuarios activos mensuales de Cognito, según uso y condiciones vigentes de la cuenta.
- Ingesta y almacenamiento temporal de CloudWatch Logs.

## Controles previstos

- HTTP API: 5 rps, burst 10.
- Lambda: 128 MiB, timeout 3 s, concurrencia reservada 0 antes de aprobar pruebas; la cuota actual no permite reservar 2.
- Logs: siete días de retención.
- Sin VPC, NAT, EC2, ALB, RDS, CloudFront, WAF, GSI ni streams para el primer despliegue.

## Riesgo de costo inesperado

Las alertas de Budget y los datos de facturación tienen retraso. Los límites reducen el riesgo, pero no son una garantía de gasto cero. Antes de crear recursos se presentará un Cost Check de implementación y una estrategia de limpieza concreta.
