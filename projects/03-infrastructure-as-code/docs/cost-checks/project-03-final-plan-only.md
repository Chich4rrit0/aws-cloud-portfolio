# Cost Check final — Proyecto 3

## Estado real

El Proyecto 3 produjo templates CloudFormation y módulos Terraform validados localmente. **No se desplegó un stack ni se ejecutó `terraform plan` o `terraform apply`**, por lo que este proyecto no creó recursos AWS ni cargos propios.

## Riesgo de costo de un despliegue futuro

Un despliegue aislado podría crear RDS, ALB, una EC2 del ASG, EBS, CloudWatch Logs, S3 y CloudFront. RDS, ALB y EC2 serían los principales componentes recurrentes; S3, CloudFront y Logs variarían según almacenamiento, transferencia, solicitudes e ingestión. Son estimaciones de riesgo, no costos reales: se debe verificar el precio vigente en `us-east-1` antes de autorizar un despliegue.

## Controles aplicados

- Sin NAT Gateway, Elastic IP, Route 53, ACM, WAF, Flow Logs ni backend Terraform remoto.
- ASG limitado a `min=1`, `desired=1`, `max=2`.
- RDS de desarrollo: Single-AZ, 20 GiB gp3 y un día de backup.
- CloudWatch Logs con retención de siete días.
- El presupuesto existente alerta; no detiene recursos automáticamente.

## Cleanup futuro

El teardown requerirá autorización destructiva independiente. El orden previsto es: Edge, Compute, Operations, Data, Storage —vaciando buckets solo con aprobación—, Security y Network. Eliminar RDS, buckets u objetos puede causar pérdida permanente de datos.
