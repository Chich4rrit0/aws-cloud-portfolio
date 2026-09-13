# Cost Check — Project 04 / Phase 00 bootstrap

## Recursos creados

Ninguno. Esta fase solo crea documentación local.

## Auditoría previa a ECR

El 2026-09-13 se verificó por AWS CLI, de forma exclusiva de lectura, que no
existen repositorios ECR en `us-east-1`. El presupuesto
`portfolio-zero-spend` mostraba gasto real `0.00` sobre su límite mensual de
USD 1.00.

## Recursos con posible costo futuro

- ECR: almacenamiento de imágenes y solicitudes.
- ECS/Fargate: vCPU y memoria mientras una tarea está activa.
- Application Load Balancer: cargo por tiempo y capacidad.
- CloudWatch Logs: ingestión y almacenamiento.
- Transferencia de datos: depende de uso y región.

ECR no tiene una instancia que se mantenga activa, pero el almacenamiento de
imágenes privadas sí puede generar cargos. AWS informa 500 MB mensuales de
Free Tier para nuevos clientes de ECR privado durante un año; la elegibilidad
real se debe verificar en la cuenta y no se asume. El almacenamiento, las
solicitudes y transferencia fuera de región siguen siendo riesgos de costo.

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
