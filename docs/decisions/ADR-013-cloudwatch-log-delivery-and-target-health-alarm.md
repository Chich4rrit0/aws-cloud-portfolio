# ADR-013 — Entrega de logs y alarma de salud del target

- Estado: Aceptado
- Fecha: 2026-09-08

## Contexto

La API se ejecuta en instancias EC2 administradas por un Auto Scaling Group. Los logs locales desaparecen al reemplazar una instancia y la métrica de salud debe distinguir entre una VM encendida y una aplicación disponible detrás del ALB.

## Decisión

La primera implementación operativa de observabilidad tendrá:

- Un CloudWatch Log Group estándar: `/aws/aws-cloud-portfolio/project-01/application`.
- Retención de siete días para reducir almacenamiento persistente.
- El CloudWatch Agent recogerá solamente el log de la aplicación y el bootstrap de Project 01. No recogerá logs del sistema, VPC Flow Logs ni ALB access logs.
- Una política inline de IAM de mínimo privilegio para crear streams y publicar eventos solo en ese grupo.
- Una alarma estándar sin acciones automáticas cuando `HealthyHostCount` mínimo del par ALB/Target Group sea menor que uno durante dos períodos consecutivos de un minuto.
- El ASG usará health checks `ELB` y el refresh mantendrá 100% de capacidad saludable mínima. Puede existir temporalmente una segunda instancia, respetando el máximo de dos.

No se configura SNS ni correo de incidentes en esta etapa, porque no se debe asumir una dirección de notificación. La alarma queda visible en CloudWatch y podrá conectarse a SNS en una fase posterior aprobada.

## Consecuencias

- Se conservan logs útiles ante reemplazos de instancias sin exponer secretos.
- CloudWatch Logs agrega costo variable de ingestión y almacenamiento; la retención corta controla el segundo componente.
- La actualización de la instancia no debe dejar el ASG sin una instancia saludable, pero puede incrementar transitoriamente el costo de EC2 durante el solapamiento.
- La alarma usa una métrica nativa de ALB; no se publica una métrica personalizada.
