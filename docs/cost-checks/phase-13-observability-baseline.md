# Cost Check — Fase 13: baseline de observabilidad

## Recursos creados o modificados

- CloudWatch Log Group de aplicación con retención de siete días.
- Política inline de escritura de logs para el rol de EC2.
- Alarma CloudWatch de ausencia de targets saludables, sin acciones.
- Nueva versión de Launch Template y refresh protegido del ASG.

## Recursos que pueden generar costo

- CloudWatch Logs: ingestión y almacenamiento, dependientes del volumen real de logs.
- Alarma CloudWatch: puede estar cubierta por el Free Tier aplicable; debe verificarse en Billing y con la tarifa vigente.
- Durante el refresh puede coexistir una segunda `t3.micro` por minutos, dentro del máximo de dos instancias ya definido.

## Controles aplicados

- No se habilitan VPC Flow Logs, ALB access logs, custom metrics, dashboards ni Database Insights avanzado.
- La retención se limita a siete días.
- La alarma no envía notificaciones ni crea SNS hasta que exista una dirección explícitamente aprobada.
- Se mantiene el presupuesto `portfolio-zero-spend`; es una alerta, no un mecanismo de detención automática.

## Verificación

Ejecutar desde la raíz del repositorio:

```powershell
.\scripts\aws-cli\Test-Project01Observability.ps1 `
  -ProfileName portfolio-root-temp `
  -Region us-east-1 `
  -Execute
```

La prueba verifica la capacidad y health check del ASG, un target saludable, el agente a través de Session Manager, los dos streams de logs esperados y que la alarma no tenga acciones configuradas.

## Riesgo de costo inesperado

- Un bucle de errores de la aplicación puede aumentar la ingestión de logs. Se revisará el tamaño almacenado del grupo y los eventos antes de ampliar retención o agregar nuevas fuentes.
