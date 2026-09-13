# Cost Check — Proyecto 03 E2E temporal

## Fecha y alcance

Consulta de precios: 2026-09-12. Región: `us-east-1`. Esta estimación cubre
solo el baseline de una prueba temporal aislada y no es un coste real, una
cotización contractual ni un límite de facturación.

## Tarifas on-demand verificadas

Consultadas desde el catálogo público de precios AWS:

| Componente | Tarifa de referencia |
| --- | ---: |
| EC2 Linux `t3.micro` | USD 0.0104/hora |
| RDS PostgreSQL Single-AZ `db.t3.micro` | USD 0.0180/hora |
| RDS gp3 | USD 0.115/GB-mes |
| Application Load Balancer | USD 0.0225/hora |
| ALB LCU | USD 0.0080/LCU-hora |

Los precios anteriores son los datos observados al consultar el catálogo. Se
deben volver a comprobar inmediatamente antes de un apply real.

## Escenario operativo recomendado: ocho horas

Supuestos explícitos: una instancia de aplicación durante ocho horas, una
instancia temporal de bootstrap durante una hora, RDS durante ocho horas, 20
GiB gp3, un ALB durante ocho horas y una LCU mínima durante ocho horas.

| Componente | Estimación para 8 h |
| --- | ---: |
| EC2 runtime | USD 0.0832 |
| EC2 bootstrap temporal | USD 0.0104 |
| RDS compute | USD 0.1440 |
| RDS gp3 prorrateado | ~USD 0.0252 |
| ALB | USD 0.1800 |
| LCU mínima de ALB | USD 0.0640 |
| **Baseline estimado** | **~USD 0.51** |

Una ventana de 24 horas bajo los mismos supuestos tendría un baseline cercano
a USD 1.50. No es la ventana aprobada: el objetivo es desplegar, comprobar y
desmontar el mismo día, con checkpoint operativo a las cuatro horas.

## Exclusiones y riesgo residual

No se incluyen transferencia de datos, solicitudes y entrega de CloudFront,
almacenamiento/solicitudes S3, ingestión/almacenamiento de CloudWatch Logs,
EBS del bootstrap, impuestos, variación de precios, ni los recursos ya activos
del Proyecto 1. El gasto de cuenta y el presupuesto se agregan; el presupuesto
de USD 1.00 es una alerta con posible retraso, no un interruptor automático.

Por ello, la regla operacional es más estricta que el presupuesto: no superar
la ventana de ocho horas, revisar Billing/Cost Explorer antes de Edge y antes
de teardown, y desmontar ante cualquier resultado inesperado. La meta de
aproximadamente CLP 15.000 / USD 17 no debe interpretarse como permiso para
dejar recursos ejecutándose hasta alcanzar esa cifra.

## Recursos que podrán generar coste

- RDS, ALB, instancia del ASG y EBS: coste principalmente por tiempo.
- Bootstrap EC2: coste corto; el script lo elimina al terminar.
- S3, CloudFront y CloudWatch: coste dependiente de uso.

No se usará NAT Gateway, Elastic IP, Route 53, WAF, Flow Logs, backend remoto
Terraform ni recursos de Proyecto 1/2.

## Gate de aprobación

Este Cost Check permite solicitar, pero no implica, una aprobación explícita
para revisar el plan de Foundation. `terraform apply`, publicación de
artefactos y teardown destructivo seguirán requiriendo autorizaciones propias.

## Actualización post-Foundation

Foundation se aplicó el 2026-09-12. RDS está disponible y ya genera coste por
tiempo; los buckets permanecen vacíos y los demás componentes de mayor coste
(ALB, Runtime y CloudFront) aún no existen. La ventana de teardown del mismo
día está activa.
