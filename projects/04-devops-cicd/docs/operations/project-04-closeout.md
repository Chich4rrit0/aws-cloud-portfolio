# Cierre profesional — Proyecto 4 DevOps / CI-CD

## Resultado demostrado

1. Dockerfile reproducible para el backend de referencia sin modificar el
   Proyecto 1.
2. Pruebas Node.js y build de contenedor en GitHub Actions.
3. Publicación manual controlada de una imagen privada ECR con tag SHA
   inmutable mediante GitHub OIDC, sin Access Keys.
4. Template CloudFormation validado para runtime temporal aislado.
5. Ejecución end-to-end ECS/Fargate detrás de ALB con `/health`, target healthy
   y CloudWatch Logs.
6. Teardown CloudFormation verificado, sin infraestructura runtime activa.

## Decisiones y trade-offs

- El runtime público sin NAT es una concesión temporal de laboratorio; no se
  presenta como arquitectura de producción.
- La publicación a ECR está automatizada; el despliegue ECS fue controlado por
  CloudFormation y no se declara como CD automático.
- Dashboards, alarmas y observabilidad profunda se reservan para Proyecto 5.
- La imagen ECR se conserva como evidencia técnica y tiene lifecycle policy.

## Qué explicar en una entrevista

> Diseñé una ruta de entrega con pruebas, build de contenedor y publicación a
> ECR mediante OIDC de mínimo privilegio. Después desplegué la misma imagen en
> una ventana temporal ECS/Fargate con ALB, health checks y logs, validé el
> comportamiento end-to-end y eliminé el runtime para controlar costos.

## Extensiones futuras

- Rol GitHub de despliegue y workflow GitHub → ECS con una nueva revisión de
  permisos y ventana de costo.
- TLS, dominio, WAF y subredes privadas con egress controlado para un patrón
  más cercano a producción.
- Dashboards, alarmas y análisis de logs en el Proyecto 5.
