# AWS Well-Architected Case Study — Task Manager

## Contexto y alcance

El Task Manager de P1 fue diseñado como una carga de trabajo pequeña para
demostrar arquitectura AWS, no como una aplicación de negocio extensa. El caso
de estudio evalúa su arquitectura de demostración y propone un camino hacia
producción sin modificar el workload desplegado.

La revisión sigue la práctica de **Prepare → Review → Improve** descrita por
AWS y cubre los seis pilares: excelencia operacional, seguridad, confiabilidad,
eficiencia de rendimiento, optimización de costos y sostenibilidad.

## Arquitectura actual

```text
Usuario → CloudFront → S3 privado (frontend)
                   └→ ALB → ASG / EC2 → RDS PostgreSQL
                                ├→ Parameter Store
                                ├→ S3 de artefactos
                                └→ CloudWatch y Session Manager
```

La auditoría de 2026-09-16 confirmó una VPC disponible, una instancia en el
ASG, RDS disponible Single-AZ, ALB activo, CloudFront desplegado, alarma sin
acciones en `OK` y retención de logs de siete días. La evidencia es puntual: no
equivale a una prueba de carga, una validación de restore ni una auditoría de
costo histórico.

## Hallazgos principales

| Área | Capacidad demostrada | Principal limitación | Prioridad |
| --- | --- | --- | --- |
| Operación | Runbooks, scripts con preflight, Session Manager y CloudWatch. | Releases manuales y sin canal de incidente. | P1/P2 |
| Seguridad | Secretos fuera de Git, OAC, roles acotados, SG por capa y sin SSH. | Root temporal, sin identidad de usuario y origen HTTP. | P0 |
| Confiabilidad | ASG, health checks y RDS no público. | Una instancia base, RDS Single-AZ y restore no practicado. | P1 |
| Rendimiento | CloudFront para estáticos y escala temporal a dos instancias. | Sin SLO, prueba de carga o dimensionamiento medido. | P1/P2 |
| Costos | Sin NAT, logs de siete días, Cost Checks y presupuesto. | Recursos activos y budget sin corte automático. | P1 |
| Sostenibilidad | Capacidad mínima y recursos reutilizados entre proyectos. | Sin criterio de apagado ni uso medido. | P1 |

## Decisión arquitectónica clave

El entorno actual mantiene conscientemente un perfil de laboratorio: una sola
instancia y RDS Single-AZ reducen gasto, pero no ofrecen una disponibilidad
adecuada para datos reales o una carga con SLA. Este es un trade-off explícito,
no una omisión inadvertida.

La evolución recomendada no consiste en activar todos los servicios de AWS. El
orden correcto es primero eliminar riesgos de identidad, autorización y cifrado
de origen; después definir recuperación, señales operativas y presupuesto; y
solo entonces aumentar disponibilidad, automatización o protección perimetral.

## Arquitectura mejorada propuesta

La [arquitectura objetivo](../architecture/target-architecture.md) añade:

1. Operador de mínimo privilegio y JWT/ownership para usuarios.
2. Dominio, ACM y HTTPS de CloudFront al ALB.
3. Objetivos RTO/RPO, restore probado y decisión informada sobre RDS Multi-AZ.
4. SLO, dashboard, alarmas con propietario y notificación aprobada.
5. CI/CD mediante OIDC, reutilizando patrones de P4 sin Access Keys.

Cada paso añade costo, complejidad o superficie operativa. Por eso el
[backlog](../recommendations/improvement-backlog.md) fija prioridades y exige
un ADR, Cost Check, rollback y aprobación antes de tocar P1.

## Resultado para portafolio

Este caso demuestra más que una lista de servicios: demuestra que se puede
explicar qué se desplegó, qué se validó, qué límites se aceptaron por costo,
qué riesgos permanecen y cómo evolucionar la solución sin ocultar trade-offs.

## Límites del resultado

- No se crearon recursos, no se modificó P1 y no se ejecutó teardown.
- P2–P5 sirven como evidencia de patrones posteriores, no como sustitución de
  controles ausentes en P1.
- No se declara que la arquitectura mejorada haya sido implementada.
- La revisión deberá actualizarse si cambia el workload, sus objetivos o su
  perfil de costo.
