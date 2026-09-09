# Cost Check — Phase 02: fundación de datos aplicada

## Recursos creados

- Tabla DynamoDB `portfolio-p02-links`: On-Demand, Standard, TTL habilitado, sin GSI, streams, PITR ni backups adicionales.
- CloudWatch Log Group `/aws/lambda/portfolio-p02-link-shortener`: retención de siete días.

## Costo estimado

Crear una tabla On-Demand vacía y un Log Group vacío no activa capacidad provisionada ni cómputo permanente. El costo dependerá de solicitudes, datos almacenados y logs ingresados una vez exista Lambda. Esta es una estimación de comportamiento de cobro, no un costo real ni una promesa de gasto cero.

## Costo real

No se declara costo real en esta fase: los datos de facturación tienen retraso y todavía no hay función, API ni datos de prueba que generen uso previsto. Se revisará Budget y Cost Explorer en la siguiente validación operativa.

## Recursos que pueden generar costo

- DynamoDB: solicitudes On-Demand y almacenamiento si se crean enlaces.
- CloudWatch Logs: ingesta y almacenamiento si Lambda empieza a escribir logs.

## Recursos que se pueden apagar o eliminar

No hay instancia o servicio que se pueda detener. Para detener el riesgo de uso se evita crear Lambda/API; para eliminar los recursos se borran Log Group y tabla, lo que destruye datos y requerirá aprobación explícita.

## Riesgo de costo inesperado

Actualmente no existe endpoint público ni proceso que invoque DynamoDB o produzca logs. El riesgo es bajo, pero no nulo: el presupuesto alerta con retraso y no es un apagado automático. Antes de exponer Lambda o API Gateway se aplicarán concurrencia reservada, throttling y una nueva revisión de costo.
