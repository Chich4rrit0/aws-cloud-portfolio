# Cost Check — Phase 04: API Gateway foundation aplicada

## Recursos creados

- Una HTTP API API Gateway con una integración Lambda.
- Un authorizer JWT de Cognito y tres rutas: una pública, dos administrativas.
- Un stage `$default` con auto-deploy y throttling de 5 rps / burst 10.
- Un permiso Lambda restringido a esta API y stage.

## Costo estimado

HTTP API, Lambda, DynamoDB On-Demand y CloudWatch Logs son servicios de pago por uso. Esta fase no creó capacidad fija, NAT Gateway, ALB, EC2, RDS, WAF ni dominio propio. El volumen inicial será unas pocas solicitudes manuales; los precios y beneficios del Free Plan o créditos deben comprobarse en Billing, no suponerse como costo real cero.

## Costo real

No se declara costo real: Billing tiene retraso y aún no se ejecutaron pruebas funcionales deliberadas contra el endpoint. El Budget existente es una alerta con retraso, no un freno automático.

## Recursos que se pueden apagar o eliminar

No hay servidor persistente que apagar. Para detener la superficie pública, eliminar la HTTP API; para conservar la API sin permitir ejecuciones, establecer concurrencia reservada `0` en Lambda. Ambos cambios requieren aprobación explícita y la primera opción elimina el endpoint.

## Riesgo de costo inesperado

La ruta `GET /r/{code}` es pública y puede generar solicitudes. El throttling reduce abuso pero no es un límite de facturación garantizado. Se mantendrá sin frontend público, CloudFront, dominio custom, WAF ni tráfico automatizado hasta contar con una necesidad y un nuevo Cost Check.
