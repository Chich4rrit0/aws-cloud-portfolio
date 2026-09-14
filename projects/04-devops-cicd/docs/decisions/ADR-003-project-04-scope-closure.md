# ADR-003 — Cierre de alcance de CI/CD y observabilidad del Proyecto 4

## Estado

Aceptada para el cierre del Proyecto 4.

## Decisión

No se abrirá una segunda ventana temporal para automatizar GitHub Actions →
ECS ni para crear dashboards, alarmas o Container Insights avanzados.

El Proyecto 4 queda delimitado a CI, build de contenedor, publicación ECR
mediante OIDC, despliegue temporal CloudFormation y validación end-to-end con
ALB, health check y CloudWatch Logs.

## Razón

La ruta ya demuestra los controles esenciales sin Access Keys y con recursos
reales. Añadir un rol de despliegue GitHub, workflow ECS y una nueva ventana
ALB/Fargate incrementaría identidad, complejidad y costo para un beneficio
marginal en esta fase. Observabilidad avanzada se tratará de forma coherente
en el Proyecto 5, donde tendrá contexto y profundidad propios.

## Consecuencias

El README final debe declarar con transparencia que la publicación ECR es
automatizada y que el despliegue runtime fue una validación controlada mediante
CloudFormation, no CD automático a ECS. La extensión futura queda como mejora
explícita y no como funcionalidad implícita.
