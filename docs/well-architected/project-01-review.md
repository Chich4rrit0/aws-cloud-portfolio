# AWS Well-Architected review — Project 01

## Alcance

Revisión de la arquitectura desplegada para el Task Manager. Evalúa el entorno de demostración actual, no una arquitectura productiva final.

## Resumen ejecutivo

La solución demuestra separación de capas, delivery por edge, secretos fuera de código, operación sin SSH y recuperación de instancias mediante ASG. Sus principales gaps productivos son: uso de un perfil root temporal, RDS Single-AZ, ausencia de identidad de usuarios, falta de notificaciones de alarmas y HTTP entre CloudFront y ALB.

| Pilar | Estado | Prioridad de mejora |
| --- | --- | --- |
| Operational Excellence | Parcialmente sólido | Alta |
| Security | Baseline sólido para laboratorio | Alta |
| Reliability | Adecuado para desarrollo | Alta |
| Performance Efficiency | Adecuado y acotado | Media |
| Cost Optimization | Consciente, pero recursos activos | Alta |
| Sustainability | Básico | Media |

## 1. Operational Excellence

### Fortalezas

- Scripts PowerShell/AWS CLI con dry-run y `-Execute` explícito.
- ADRs, Cost Checks, validaciones internas/externas y runbooks versionados.
- Session Manager para diagnóstico remoto y CloudWatch Logs para bootstrap/aplicación.
- Demostración de Auto Scaling y recuperación inmutable documentadas.

### Riesgos

- El despliegue sigue siendo guiado manualmente.
- No existe pipeline CI/CD ni control de cambios mediante pull request.
- No hay dashboard operativo ni notificación de incidentes.

### Recomendaciones

1. Crear CI que ejecute `npm ci` y `npm test` en cada pull request.
2. Crear CD con GitHub OIDC, sin Access Keys, después de definir aprobación de despliegue.
3. Agregar un dashboard mínimo y un destino SNS explícitamente aprobado para alarmas.

## 2. Security

### Fortalezas

- Sin SSH, key pairs ni puertos de administración públicos.
- Security Groups por capa y acceso de base de datos solo desde la aplicación.
- Password de aplicación en SecureString; EC2 role limitado a un parámetro y releases privados.
- S3 frontend privado con OAC y ALB protegido por header origin-only.
- IMDSv2, EBS cifrado y conexión TLS hacia RDS.

### Riesgos

- El acceso de administración temporal basado en root no es una práctica productiva.
- El ALB recibe TCP 80 en su SG; el bloqueo de acceso directo ocurre en listener L7, no en red.
- No hay autenticación ni autorización de usuarios en la API.
- CloudFront llega al ALB por HTTP.

### Recomendaciones

1. Sustituir el uso diario de root por una identidad administrativa con MFA y mínimo privilegio, sin habilitar servicios no deseados.
2. Implementar Cognito/JWT y autorización por usuario antes de exponer datos reales.
3. Agregar dominio, ACM y listener HTTPS para cifrado de extremo a extremo.
4. Evaluar WAF cuando exista exposición pública sostenida y presupuesto para ello.

## 3. Reliability

### Fortalezas

- Dos AZ para subnets Edge/App y ASG con capacidad máxima de dos.
- Target Group usa `/health`; ASG usa health checks ELB.
- Refresh protegido conserva capacidad saludable durante reemplazos.
- RDS está aislado de Internet y usa backups automáticos.

### Riesgos

- Una sola EC2 es un compromiso de costo y no tolera pérdida de AZ sin escalar.
- RDS Single-AZ, un día de retención y deletion protection desactivada.
- El scale-in target tracking resultó más lento que la ventana de demostración; fue necesaria reducción manual aprobada.

### Recomendaciones

1. Para producción, usar RDS Multi-AZ, mayor retención y deletion protection.
2. Revisar métricas/cooldowns de políticas antes de convertir una demo de Auto Scaling en comportamiento permanente.
3. Diseñar y practicar restore de backup o snapshot con datos no productivos.

## 4. Performance Efficiency

### Fortalezas

- CloudFront descarga contenido estático del ALB.
- El frontend usa rutas relativas y evita CORS adicional.
- ASG permite aumentar de una a dos instancias frente a carga.
- PostgreSQL se usa para el patrón de persistencia relacional simple del dominio.

### Riesgos

- La API y RDS usan tamaños pequeños adecuados solo para desarrollo.
- No hay prueba de carga HTTP sostenida ni métricas de latencia de aplicación.

### Recomendaciones

1. Medir latencia, 5xx y CPU bajo una prueba HTTP acotada antes de cambiar tamaños.
2. Usar caching de CloudFront solo para assets estáticos; mantener `/api/*` sin cache.
3. Escalar a dos instancias solo para demos o cuando métricas justificadas lo requieran.

## 5. Cost Optimization

### Fortalezas

- No se usa NAT Gateway, Multi-AZ RDS, WAF, VPC Flow Logs, ALB access logs ni dashboards avanzados en esta fase.
- ASG vuelve a una instancia después de pruebas controladas.
- Retención de CloudWatch Logs limitada a siete días.
- Budget temprano y Cost Checks por fase.

### Riesgos

- RDS, ALB, una EC2, EBS, S3, CloudFront y CloudWatch siguen activos y pueden generar cargos.
- El budget alerta; no detiene recursos.
- T3 Unlimited puede generar cargos de CPU credits bajo carga sostenida.

### Recomendaciones

1. Revisar Billing/Cost Explorer tras cada demostración, aceptando el retraso de datos.
2. Usar el [runbook de cleanup](../operations/project-01-cleanup.md) cuando no se necesite el entorno.
3. Etiquetar y revisar todos los recursos de Project 01 antes de crear una variante o entorno adicional.

## 6. Sustainability

### Fortalezas

- Una sola instancia de base y retención corta evitan capacidad permanentemente ociosa.
- Los assets estáticos se entregan desde edge, reduciendo trabajo repetitivo en el origen.
- Recursos temporales de bootstrap y Auto Scaling se limpiaron tras las demostraciones.

### Riesgos

- Mantener la arquitectura encendida sin uso consume recursos innecesarios.
- Invalidaciones CloudFront y refreshes frecuentes tienen impacto operativo y de consumo.

### Recomendaciones

1. Pausar o eliminar el entorno cuando no haya una demostración planificada.
2. Reutilizar el frontend, scripts y documentación en los proyectos posteriores en vez de duplicar stacks.
3. Medir antes de escalar; no mantener capacidad por anticipación sin evidencia.

## Evolución propuesta

```text
Project 01 baseline
  -> documentación y presentación cerradas
  -> CI/CD con GitHub OIDC
  -> Terraform/CloudFormation reproducible
  -> Cognito + HTTPS end-to-end
  -> análisis Well-Architected revisado contra una versión mejorada
```

La mejora debe hacerse de forma incremental y con un nuevo Cost Check antes de crear cada recurso que implique cargo recurrente.
