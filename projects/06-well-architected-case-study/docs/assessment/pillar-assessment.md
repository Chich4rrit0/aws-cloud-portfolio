# Assessment de pilares — Proyecto 6

## Resultado ejecutivo

El Task Manager de P1 es una arquitectura de demostración bien documentada y
validada para un entorno de desarrollo controlado. No se presenta como
producción lista: hay riesgos intencionales en identidad, disponibilidad de
base de datos, cifrado hacia el origen y automatización. Las capacidades de
P2–P5 muestran cómo podría evolucionar el portafolio, pero no cambian el estado
actual de P1.

Este assessment usa evidencia histórica E-01 a E-05. No afirma el estado AWS
del 2026-09-16; esa confirmación permanece pendiente de una consulta de solo
lectura. No se asigna un puntaje numérico: los gaps sin evidencia no deben
convertirse en una métrica artificial de madurez.

| Pilar | Evaluación | Conclusión |
| --- | --- | --- |
| Excelencia operacional | Parcialmente sólido | Buenas prácticas documentadas; entrega P1 sigue manual. |
| Seguridad | Baseline de laboratorio | Capas y secretos correctos; faltan identidad de usuarios y TLS de origen. |
| Confiabilidad | Adecuado para desarrollo | Health checks y ASG; base de datos Single-AZ y una instancia base. |
| Eficiencia de rendimiento | Adecuado y acotado | Edge para estáticos; faltan métricas de latencia y prueba de carga. |
| Optimización de costos | Consciente | Controles explícitos, pero el budget no actúa como corte automático. |
| Sostenibilidad | Básico | Capacidad mínima y reutilización; falta medición y apagado programado. |

## Excelencia operacional

### Fortalezas verificadas

- Scripts PowerShell/AWS CLI con preflight, dry-run y acciones explícitas.
- ADRs, Cost Checks, runbooks y validaciones versionadas ([E-01](../evidence/evidence-register.md), [E-02](../evidence/evidence-register.md)).
- Operación sin SSH mediante Session Manager; logs de bootstrap y aplicación en
  CloudWatch.
- Health check `/health`, validación de CRUD y rollback documentado.

### Gaps y trade-offs

- La entrega de P1 requiere pasos guiados manualmente; no hay CI/CD conectado
  al workload.
- La alarma de salud no tiene canal de notificación o escalamiento aprobado.
- No existe evidencia de una revisión periódica ni de postmortems reales para
  P1.

### Mejora prioritaria

Adoptar la cadena de pruebas y OIDC demostrada en P4 para una futura evolución
de P1, con una aprobación de despliegue separada. Antes, definir qué alarma,
propietario y canal de notificación justifican una acción operativa.

## Seguridad

### Fortalezas verificadas

- Sin SSH, key pairs ni puertos administrativos públicos; acceso operativo por
  Session Manager.
- Security Groups por capa: aplicación desde ALB y PostgreSQL solo desde
  aplicación.
- S3 de frontend privado con OAC; artefactos privados y role EC2 limitado.
- Secretos fuera de Git en Parameter Store, IMDSv2, EBS cifrado y TLS entre
  aplicación y RDS.

### Gaps y trade-offs

- El perfil administrativo temporal usa root, aun con MFA; no es una práctica
  adecuada para operación recurrente.
- La API no tiene autenticación ni autorización de usuarios.
- CloudFront llega al ALB por HTTP y el control de acceso directo al ALB se
  basa en reglas L7 y cabecera de origen.
- WAF no está incluido; fue una exclusión deliberada de costo para laboratorio.

### Mejora prioritaria

Antes de usar datos reales o exponer administración a terceros: operar con una
identidad administrativa de mínimo privilegio, implementar JWT/ownership y
cifrar CloudFront → ALB con dominio y ACM. WAF debe evaluarse solo si la
exposición y el presupuesto justifican su costo.

## Confiabilidad

### Fortalezas verificadas

- Subnets de edge y aplicación repartidas en dos AZ.
- ASG con health checks de ELB, Target Group con `/health` y recuperación de
  instancia documentada.
- RDS no público, con backup automático, y pruebas CRUD contra PostgreSQL.

### Gaps y trade-offs

- El ASG mantiene una instancia como decisión de costo; la pérdida de una AZ no
  queda cubierta hasta escalar.
- RDS es Single-AZ, con un día de retención y sin deletion protection.
- No hay evidencia de un restore de RDS practicado ni de objetivos RTO/RPO.
- La demostración mostró que el scale-in target tracking no coincidió con la
  ventana corta y requirió reducción manual aprobada.

### Mejora prioritaria

Para un entorno de producción, definir RTO/RPO y validar restore con datos no
productivos. Después evaluar RDS Multi-AZ, mayor retención, deletion protection
y capacidad base en más de una AZ según el objetivo de disponibilidad.

## Eficiencia de rendimiento

### Fortalezas verificadas

- CloudFront entrega el frontend y descarga contenido estático del ALB.
- `/api/*` y `/health` se mantienen sin cache; el frontend usa rutas relativas
  y evita una capa CORS adicional.
- ASG puede crecer de una a dos instancias para una demostración controlada.

### Gaps y trade-offs

- EC2 y RDS son tamaños de desarrollo; no hay benchmark de aplicación.
- No hay evidencia de SLO de latencia, panel de 5XX ni prueba HTTP sostenida.
- Cambiar tamaño o capacidad sin medición contradiría el objetivo de costo
  bajo.

### Mejora prioritaria

Instrumentar latencia, errores y CPU con umbrales explícitos. Ejecutar una
prueba acotada y aprobada antes de modificar tamaños, concurrencia o capacidad
base.

## Optimización de costos

### Fortalezas verificadas

- Se evitó NAT Gateway, RDS Multi-AZ, WAF y telemetría avanzada no justificada
  en el entorno de aprendizaje.
- ASG vuelve a una instancia después de demostraciones y CloudWatch Logs tiene
  retención de siete días.
- Hay Cost Checks por fase, etiquetas y un presupuesto con alerta.
- Existe un runbook para pausar o desmontar el stack en orden de dependencias.

### Gaps y trade-offs

- ALB, RDS, EC2/EBS, S3, CloudFront y CloudWatch pueden generar cargos mientras
  existan; P6 no confirma si siguen activos hoy.
- El budget alerta con retraso y no detiene el gasto automáticamente.
- T3 Unlimited puede implicar cargos de CPU credits en carga sostenida.

### Mejora prioritaria

Usar una ventana de demostración explícita, revisar Billing después de cada una
y ejecutar el runbook de limpieza cuando ya no se necesite el workload. Cualquier
automatización de apagado requiere diseño separado para evitar pérdida de datos.

## Sostenibilidad

### Fortalezas verificadas

- La capacidad base mínima, el delivery de estáticos por edge y la retención
  corta reducen capacidad ociosa frente a un entorno sobredimensionado.
- Bootstrap temporal y capacidad adicional de las demostraciones se limpiaron.
- P2–P5 reutilizan aplicaciones y aprendizajes del portafolio en vez de crear
  seis workloads independientes.

### Gaps y trade-offs

- Mantener el entorno sin una demostración planificada consume recursos sin
  aportar valor.
- No hay KPI de utilización ni criterio documentado para mantener o apagar
  capacidad.

### Mejora prioritaria

Vincular cada ventana de ejecución a una validación o demo y revisar uso antes
de escalar. La primera decisión de sostenibilidad es eliminar capacidad ociosa,
no añadir un servicio de monitoreo adicional.

## Hallazgos transversales prioritarios

| ID | Hallazgo | Prioridad | Pilar principal |
| --- | --- | --- | --- |
| WA-01 | Operación administrativa diaria basada en root temporal. | P0 | Seguridad |
| WA-02 | Sin identidad/autorización para tareas de usuario. | P0 | Seguridad |
| WA-03 | CloudFront → ALB sin TLS de origen. | P0 | Seguridad |
| WA-04 | RDS Single-AZ sin restore practicado. | P1 | Confiabilidad |
| WA-05 | Notificación, SLO y métricas de rendimiento insuficientes. | P1 | Operación / rendimiento |
| WA-06 | Recursos recurrentes y budget sin interruptor automático. | P1 | Costo / sostenibilidad |
| WA-07 | P1 no consume aún la automatización CI/CD posterior. | P2 | Excelencia operacional |
