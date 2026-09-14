# Diseño de laboratorio temporal ECS/Fargate — Proyecto 4

## Estado y objetivo

Diseño listo para revisión. No hay VPC, ECS, ALB, logs ni tareas creadas por
este documento. Su objetivo es demostrar una entrega completa de una imagen
inmutable de ECR a un runtime administrado durante una ventana corta y con
teardown explícito.

## Topología propuesta

```text
Internet
  -> ALB público (dos AZ, listener HTTP :80)
     -> target group HTTP :3000, health check /health
        -> una tarea ECS/Fargate
           -> imagen privada ECR sha-<commit>
           -> CloudWatch Logs (retención: 7 días)

GitHub Actions -- OIDC temporal --> rol de despliegue limitado --> ECS
```

La aplicación nunca acepta administración remota. El único ingreso de la
tarea es el puerto 3000 desde el security group del ALB.

## Red aislada propuesta

| Componente | Valor | Razón |
|---|---|---|
| VPC | `10.40.0.0/16` | No se superpone con los CIDR actuales auditados. |
| Subred pública A | `10.40.0.0/24` en `us-east-1a` | ALB exige al menos dos AZ. |
| Subred pública B | `10.40.1.0/24` en `us-east-1b` | Alta disponibilidad de la capa de entrada. |
| Internet Gateway y ruta `0.0.0.0/0` | Únicos componentes de egress | Acceso temporal a ECR y CloudWatch sin NAT Gateway. |
| NAT Gateway | No se crea | Evita un cargo recurrente significativo para un laboratorio corto. |
| IP pública de tarea | Sí, temporal | Concesión de laboratorio; no sustituye subredes privadas de producción. |

## Seguridad y roles

| Elemento | Regla o permiso mínimo |
|---|---|
| Security group ALB | Entrada TCP 80 desde Internet; salida TCP 3000 solo al CIDR de la VPC aislada. |
| Security group de tarea | Entrada TCP 3000 solo desde el security group ALB; salida HTTPS para ECR y CloudWatch. |
| Execution role ECS | Leer la imagen de este ECR y escribir en un único log group. |
| Task role | Se omite inicialmente: la API no necesita permisos AWS de negocio. |
| GitHub deploy role | Pendiente; solo podrá registrar la task definition aprobada, actualizar el servicio objetivo y pasar los roles ECS concretos. |
| GitHub publisher role | Ya existe y sigue limitado a ECR; no recibirá permisos ECS. |

Al crear por primera vez un servicio ECS, AWS puede crear su service-linked role
administrado `AWSServiceRoleForECS` si no existe. No tiene cargo directo, pero
se tratará como un cambio IAM explícito dentro de la aprobación de despliegue.

## Runtime y observabilidad

- Plataforma Fargate Linux/x86, una tarea `0.25 vCPU` y `0.5 GB` de memoria.
- Servicio con `desiredCount = 1`; no auto scaling durante esta demostración.
- Contenedor en puerto 3000, health check de ECS y target group contra
  `/health`.
- Log group dedicado `/ecs/portfolio-p04-task-manager`, con retención de siete
  días y sin Container Insights ni access logs del ALB en esta fase.
- ALB público HTTP solamente. TLS, dominio, ACM y WAF están fuera de alcance
  para reducir complejidad y costo; no es un diseño de producción.

## Alternativas evaluadas

### Opción A — ALB + Fargate temporal (recomendada)

Demuestra contenedor, balanceador, health checks, security groups, logs y
teardown. Tiene costos horarios de ALB y Fargate, mitigados con una ventana
máxima definida y eliminación el mismo día.

### Opción B — Fargate público directo, sin ALB

Menor costo y menos recursos, pero no demuestra el patrón de entrega con ALB
esperado en el Proyecto 4. Se descarta para la demostración principal.

### Opción C — Subred privada con NAT Gateway

Más cercano a producción, pero el NAT Gateway agrega costo recurrente. Se
descarta para este laboratorio de aprendizaje; se documentará como mejora
Well-Architected futura.

## Secuencia de despliegue propuesta

1. Crear red aislada, security groups, log group y roles ECS.
2. Crear cluster, task definition, target group, ALB, listener y servicio con
   una sola tarea.
3. Esperar estabilidad y validar target healthy, endpoint `/health` y logs.
4. Registrar evidencia de arquitectura y Cost Check.
5. Ejecutar teardown aprobado el mismo día: servicio, ALB/listener/target
   group, cluster, log group, red y roles ECS. La imagen ECR y OIDC se
   revisarán como decisiones independientes.

## Fuera de alcance deliberado

- Modificar Proyectos 1, 2 o 3.
- NAT Gateway, Route 53, ACM, WAF, base de datos, secretos o dominio.
- Escalado, despliegue blue/green y pipeline automático a ECS antes de validar
  el runtime manualmente.
- Cualquier eliminación sin autorización explícita.
