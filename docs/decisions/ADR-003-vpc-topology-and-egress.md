\# ADR-003 — Topología de VPC y estrategia de salida



\- Estado: Aceptado

\- Fecha: 2026-09-06



\## Contexto



El Proyecto 1 requiere una arquitectura web con ALB, EC2 y RDS PostgreSQL en dos Availability Zones. La cuenta utiliza AWS Free Plan con créditos limitados.



Una arquitectura de producción habitual ubicaría EC2 en subredes privadas y utilizaría NAT Gateway para salida a Internet. NAT Gateway genera cargos por hora y por datos procesados.



\## Decisión



Se utilizará una VPC `10.20.0.0/16` en `us-east-1`, distribuida en dos AZ:



| Capa | us-east-1a | us-east-1b |

|---|---|---|

| Public edge | 10.20.0.0/24 | 10.20.1.0/24 |

| Public app | 10.20.10.0/24 | 10.20.11.0/24 |

| Private database | 10.20.20.0/24 | 10.20.21.0/24 |



No se creará NAT Gateway en la primera versión.



El ALB se ubicará en las subredes public edge. Las instancias EC2 estarán en las subredes public app, pero sus Security Groups permitirán tráfico entrante únicamente desde el ALB. RDS estará en las subredes private database y no tendrá acceso público.



\## Consecuencias



\- Se evita el costo recurrente de NAT Gateway.

\- EC2 no tendrá aislamiento de routing equivalente a una subred privada.

\- No se abrirá SSH desde Internet; la administración se diseñará mediante mecanismos controlados.

\- La evolución productiva trasladaría EC2 a subredes privadas y agregaría NAT Gateway o VPC endpoints según el patrón de tráfico.

