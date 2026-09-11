# Cost Check — Phase 05: validación funcional y cierre

## Recursos creados

No se crearon recursos nuevos durante la validación ni durante el cierre. Se usaron los recursos ya aprobados: HTTP API, Lambda, DynamoDB On-Demand, Cognito Lite y CloudWatch Logs.

## Uso verificado

- Una ruta pública inexistente devolvió `404`.
- Una mutación sin JWT devolvió `401` antes de alcanzar Lambda.
- La prueba autenticada creó, resolvió y eliminó un único enlace de prueba.
- DynamoDB terminó vacía.
- CloudWatch reportó seis invocaciones Lambda y cero errores en la ventana de prueba.

## Costo estimado

La actividad de esta fase fue un número pequeño de solicitudes. No hay capacidad fija ni recursos de red de cobro horario: no se usan EC2, ALB, NAT Gateway, RDS, WAF, CloudFront ni dominio personalizado. HTTP API, Lambda, DynamoDB On-Demand y Logs siguen sujetos a precio por uso.

## Costo real

No se declara un importe real: Billing y Cost Explorer pueden presentar retraso y los créditos o beneficios de la cuenta no deben interpretarse como un costo confirmado de cero. El costo real debe revisarse directamente en AWS Billing antes de reanudar tráfico o dejar la API expuesta durante periodos prolongados.

## Recursos que se pueden apagar o eliminar

- Pausar Lambda con concurrencia reservada `0` bloquea invocaciones, pero la API seguirá expuesta.
- Eliminar la HTTP API retira el endpoint público.
- Eliminar Lambda, Cognito, DynamoDB y Logs destruye el laboratorio completo y, en el caso de DynamoDB, sus datos.

Ninguna de esas acciones se ejecutó como parte del cierre.

## Riesgo de costo inesperado

La ruta pública de redirect y los logs pueden acumular uso ante tráfico externo. El throttling de API Gateway es una protección de servicio, no un límite de facturación. Mantener el proyecto sin frontend, dominio, campañas de tráfico ni automatizaciones reduce este riesgo; el Budget existente sigue siendo una alerta, no una pausa automática.
