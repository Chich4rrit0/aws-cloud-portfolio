\# ADR-008 — Baseline de observabilidad



\- Estado: Aceptado

\- Fecha: 2026-09-06



\## Contexto



El proyecto debe demostrar observabilidad sin crear una cantidad de métricas, logs o alarmas que consuman créditos innecesariamente.



\## Decisión



La primera versión incluirá:



\- CloudWatch Logs para la API con el grupo `/aws-cloud-portfolio/project-01/api`.

\- Retención de logs de siete días.

\- Logs JSON estructurados, sin secretos, JWT ni datos personales.

\- Métricas nativas de ALB, EC2 y RDS.

\- Cuatro alarmas estándar: ALB 5xx, target no saludable, CPU EC2 alta y espacio RDS bajo.

\- Un dashboard operativo llamado `project-01-operations`.



No se habilitarán inicialmente VPC Flow Logs, ALB access logs, custom metrics ni CloudWatch Database Insights avanzado.



\## Consecuencias



\- Se obtiene visibilidad suficiente para demostrar fallos y escalamiento.

\- La retención corta limita almacenamiento de logs.

\- Los logs de acceso y métricas avanzadas quedan como una mejora posterior y una demostración de observabilidad de duración controlada.

