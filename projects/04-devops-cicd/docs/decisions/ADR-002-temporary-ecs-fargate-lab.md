# ADR-002 — Laboratorio temporal ECS/Fargate público sin NAT

## Estado

Propuesto; pendiente de Cost Check y autorización de creación AWS.

## Contexto

Proyecto 4 ya validó CI, build local, publicación ECR privada y federación
OIDC. Falta comprobar que la imagen puede operar en un runtime administrado
con health checks y logs, sin tocar los proyectos cerrados ni mantener cargos
permanentes.

## Decisión propuesta

Crear una VPC aislada `10.40.0.0/16`, dos subredes públicas en distintas AZ,
un ALB público y una sola tarea Fargate mínima. La tarea tendrá IP pública
temporal para descargar la imagen de ECR y enviar logs; su security group no
aceptará tráfico desde Internet, solo desde el ALB.

La ventana de ejecución objetivo será de 60 minutos o menos, seguida por un
teardown explícitamente autorizado.

## Consecuencias

Se demostrará una ruta completa de entrega y operación, pero se incurrirá en
cargos variables de ALB, Fargate, direcciones IPv4 públicas, ECR y logs. Este
patrón no es producción: para ello se preferirían tareas privadas con egress
controlado, TLS y mayor resiliencia.

## Razón

La alternativa directa sin ALB abarata el laboratorio pero reduce el valor de
portafolio. Usar NAT Gateway elevaría el riesgo de costo para una cuenta de
aprendizaje. El compromiso propuesto maximiza evidencia técnica dentro de una
ventana corta y controlada.
