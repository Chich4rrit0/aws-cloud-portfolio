# Cost Check — Project 04 / Phase 00 bootstrap

## Recursos creados

Ninguno. Esta fase solo crea documentación local.

## Recursos con posible costo futuro

- ECR: almacenamiento de imágenes y solicitudes.
- ECS/Fargate: vCPU y memoria mientras una tarea está activa.
- Application Load Balancer: cargo por tiempo y capacidad.
- CloudWatch Logs: ingestión y almacenamiento.
- Transferencia de datos: depende de uso y región.

Los valores son categorías de riesgo, no precios ni costos reales. Se deben
consultar precios vigentes en `us-east-1` antes de autorizar una prueba E2E.

## Controles previstos

- Ejecutar una única tarea mínima durante una ventana corta.
- Eliminar servicio, cluster, ALB, target group, ECR e identidades temporales
  tras tomar evidencia.
- Mantener solo imágenes imprescindibles y vaciar/eliminar ECR durante el
  teardown aprobado.
- No crear NAT Gateway, Elastic IP, dominio, ACM o WAF.

## Riesgo de costo inesperado

ALB y Fargate siguen generando cargos mientras estén activos. Un presupuesto
alerta, pero no apaga recursos automáticamente; el teardown validado es el
control principal.
