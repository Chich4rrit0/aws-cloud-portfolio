# Topología futura de entrega AWS

## Objetivo

Cuando la etapa CI esté funcional y exista aprobación de costo, el pipeline
agregará publicación y despliegue en etapas separadas. La infraestructura será
aislada de los recursos cerrados de los Proyectos 1, 2 y 3.

```text
GitHub Actions (OIDC, rol de publicación)
  -> ECR privado (imagen inmutable por SHA)
  -> ECS control plane (rol de despliegue)
  -> ECS/Fargate service (rol de ejecución)
  -> Application Load Balancer
  -> CloudWatch Logs
```

## Identidades separadas

| Identidad | Propósito | Límite previsto |
|---|---|---|
| GitHub OIDC provider | Federación sin Access Keys | Solo el repositorio y rama autorizados |
| Rol de publicación | Obtener token ECR y publicar una imagen | Un repositorio ECR de Proyecto 4 |
| Rol de despliegue | Registrar task definition y actualizar el servicio | Cluster, service y task definition de Proyecto 4 |
| Execution role ECS | Descargar imagen y escribir logs | ECR y log group específico |
| Task role ECS | Permisos de aplicación | Sin permisos AWS al inicio |

## Runtime de laboratorio

La demostración usará una única tarea Fargate mínima, sin acceso de
administración entrante, con health check del ALB contra `/health`. Para evitar
NAT Gateway durante una ventana corta, las tareas tendrán IP pública temporal
en subredes públicas aisladas. Esto es una concesión de laboratorio; una
arquitectura de producción usaría subredes privadas y egress controlado.

## Teardown previsto

Tras la evidencia: actualizar/eliminar el servicio, eliminar ALB y target
group, cluster, log group, repositorio ECR e identidades específicas del
laboratorio. Cada eliminación requerirá autorización destructiva independiente.
