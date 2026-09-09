# ADR-002 — HTTP API, Lambda y DynamoDB On-Demand

- Estado: Aceptado
- Fecha: 2026-09-09

## Contexto

La carga esperada es pequeña, irregular y orientada a demostración. Mantener EC2, ALB, RDS o NAT Gateway repetiría costos y capacidades ya mostradas en el Proyecto 1.

## Decisión

Se utilizará API Gateway HTTP API → Lambda → DynamoDB On-Demand en `us-east-1`. Lambda no estará en VPC. La tabla tendrá una partition key `shortCode` y escrituras condicionales para impedir colisiones.

## Alternativas

| Opción | Ventaja | Desventaja |
| --- | --- | --- |
| HTTP API + Lambda + DynamoDB | Pago por uso, sin servidores ni capacidad provisionada. | Requiere modelar acceso y observar límites serverless. |
| REST API + Lambda + DynamoDB | Más capacidades API Gateway. | Mayor complejidad y costo por request para este alcance. |
| EC2/ALB/RDS | Modelo familiar y relacional. | Costo base permanente y duplicación del Proyecto 1. |

## Consecuencias

- No se crean recursos de cómputo por hora en la primera versión.
- DynamoDB, requests API, Lambda, logs y almacenamiento siguen siendo consumo facturable según uso.
- La futura fase IaC podrá reproducir estas decisiones sin depender de servidores manuales.
