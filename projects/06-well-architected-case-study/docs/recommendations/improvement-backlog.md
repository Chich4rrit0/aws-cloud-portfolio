# Backlog de mejoras — Proyecto 6

## Criterio de priorización

Las prioridades reflejan una futura exposición productiva, no una obligación de
modificar el laboratorio actual. `P0` se resuelve antes de usar datos reales o
administración de terceros; `P1` reduce riesgo alto; `P2` mejora madurez;
`P3` queda condicionada a demanda y presupuesto.

| ID | Prioridad | Mejora | Beneficio | Costo o dependencia | Evidencia |
| --- | --- | --- | --- | --- | --- |
| WA-01 | P0 | Sustituir la operación recurrente con root por identidad administrativa MFA y mínimo privilegio. | Reduce blast radius y mejora trazabilidad. | Diseño IAM compatible con el plan de cuenta. | E-03 |
| WA-02 | P0 | Implementar Cognito/JWT y autorización por ownership. | Protege tareas y datos de usuario. | Cambia contrato y pruebas de aplicación. | E-01, E-06 |
| WA-03 | P0 | Agregar dominio, ACM y HTTPS de CloudFront a ALB. | Cifrado de extremo a extremo. | DNS, certificados y listener HTTPS. | E-01 |
| WA-04 | P1 | Definir RTO/RPO y practicar restore; luego decidir Multi-AZ, retención y deletion protection. | Recuperación verificable. | Puede aumentar costo de RDS y backups. | E-01, E-04 |
| WA-05 | P1 | Establecer SLO de disponibilidad/latencia y notificación con propietario. | Operación accionable en vez de solo métricas. | Diseño de alertas y posible costo de canal. | E-02, E-09 |
| WA-06 | P1 | Formalizar ventanas de demo y revisión de Billing; ejecutar limpieza al finalizar. | Menos capacidad ociosa y costos sorpresa. | Requiere disciplina operativa; el budget no es corte. | E-04 |
| WA-07 | P2 | Llevar a P1 CI, pruebas y CD OIDC con aprobación. | Releases repetibles sin Access Keys. | Revisión de permisos y estrategia de rollback. | E-08 |
| WA-08 | P2 | Medir latencia, 5XX y CPU bajo carga controlada. | Dimensionamiento basado en evidencia. | Ventana temporal y monitoreo de costo. | E-01, E-02 |
| WA-09 | P3 | Evaluar WAF y controles de abuso si aumenta la exposición. | Defensa adicional frente a tráfico público. | Costo continuo y operación de reglas. | E-03 |

## Secuencia recomendada

1. Resolver WA-01 a WA-03 antes de cualquier uso con usuarios o datos reales.
2. Definir objetivos de disponibilidad y recuperación; ejecutar WA-04.
3. Acordar señales operativas y costo de mantener el workload; ejecutar WA-05 y
   WA-06.
4. Reutilizar el patrón validado de P4 para WA-07 y medir antes de escalar con
   WA-08.
5. Considerar WA-09 solo cuando exista exposición sostenida y presupuesto.

Cada ítem necesita su propio ADR, Cost Check, plan de rollback y aprobación
antes de convertirse en una modificación de P1.
