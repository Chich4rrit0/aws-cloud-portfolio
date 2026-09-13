# Cost Check — Project 04 / Phase 01 laboratorio ECS

## Estado

Plan previo al despliegue. Ninguno de los recursos de esta sección ha sido
creado todavía.

## Recursos propuestos y costo

| Recurso | Situación de costo | Control |
|---|---|---|
| VPC, subredes, route tables, IGW y security groups | Sin cargo directo previsto | Crear aislados y eliminar en teardown. |
| ALB | Cargo horario base y LCU variable | Una sola ventana; eliminar ALB y dependencias el mismo día. |
| Fargate 0.25 vCPU / 0.5 GB | Facturación por segundo mientras la tarea está activa | `desiredCount=1`, máximo 60 minutos, sin auto scaling. |
| IPv4 pública | Cargo por dirección en uso | Solo mientras exista la tarea; evitar Elastic IP. |
| CloudWatch Logs | Ingestión y almacenamiento | Logs mínimos, retención siete días, eliminar log group en teardown. |
| ECR | Una imagen ya almacenada | Lifecycle vigente; decidir retención/eliminación después de la evidencia. |

## Referencias de precios vigentes consultadas

- ALB en `us-east-1`: cargo base publicado de USD 0.0225/hora más LCU según
  uso; la LCU es variable y no se trata como costo fijo.
- Fargate Linux/x86 en `us-east-1`: USD 0.000011244 por vCPU-segundo y
  USD 0.000001235 por GB-segundo. Una tarea de 0.25 vCPU y 0.5 GB durante una
  hora equivale aproximadamente a USD 0.01234, antes de otros componentes.
- IPv4 pública: USD 0.005 por dirección y hora, cobrada por segundo con
  mínimo de 60 segundos. El número final de direcciones depende de los
  recursos asignados por AWS.
- CloudWatch Logs y transferencia de datos dependen del volumen. No se fija
  una estimación ficticia para ellos.

Las tarifas son estimaciones basadas en precios públicos de AWS y no incluyen
impuestos, transferencias ni posibles cambios de precio. El presupuesto
`portfolio-zero-spend` alerta, pero no detiene recursos.

## Guardrails operativos

1. Revisar presupuesto y recursos ECR antes de crear el stack.
2. Crear una sola tarea mínima y no activar auto scaling.
3. Definir una alarma o recordatorio operativo de 45 minutos y ejecutar
   teardown antes de 60 minutos.
4. No crear NAT Gateway, Elastic IP, dominio, ACM, WAF, RDS ni base de datos.
5. Después de la validación, listar recursos del prefijo `portfolio-p04` antes
   de cualquier borrado y pedir autorización destructiva explícita.

## Riesgo de costo inesperado

El ALB continúa cobrando hasta eliminarse, incluso sin tráfico. Billing puede
tardar en reflejar gasto. Un timeout operativo y el teardown aprobado son los
controles principales, no el presupuesto por sí solo.

## Fuentes

- [Elastic Load Balancing pricing](https://aws.amazon.com/elasticloadbalancing/pricing/)
- [AWS Fargate pricing](https://aws.amazon.com/fargate/pricing/)
- [Amazon VPC public IPv4 pricing](https://aws.amazon.com/vpc/pricing/)
- [Amazon CloudWatch pricing](https://aws.amazon.com/cloudwatch/pricing/)
