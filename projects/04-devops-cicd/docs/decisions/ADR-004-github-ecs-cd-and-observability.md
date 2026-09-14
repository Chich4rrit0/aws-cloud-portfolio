# ADR-004 — CD GitHub → ECS y observabilidad temporal

## Estado

Aceptada para una extensión temporal del Proyecto 4.

## Decisión

Se reabre el laboratorio ECS/Fargate existente para validar una entrega
controlada desde GitHub Actions hacia ECS y una capa de observabilidad más
visible. El flujo se dispara manualmente en GitHub Actions y requiere una
etiqueta inmutable de ECR; no se despliega desde una etiqueta mutable.

Se crea un segundo rol OIDC, independiente del rol que publica imágenes. Solo
puede leer la imagen del repositorio Project 4, describir/registrar task
definitions de la familia del laboratorio, actualizar el único servicio ECS y
pasar el único execution role a ECS Tasks. No puede crear ni eliminar
infraestructura, publicar imágenes, modificar IAM ni operar otros proyectos.

El stack CloudFormation incorpora un dashboard CloudWatch y dos alarmas sin
acciones automáticas: target no saludable del ALB y CPU alta del servicio ECS.

## Razón

La separación de roles reduce el radio de impacto entre CI y CD. El deploy
manual preserva control de costo y evita que cada commit mantenga Fargate/ALB
encendidos por más tiempo. Las señales elegidas usan métricas AWS nativas y no
requieren Container Insights, métricas personalizadas, SNS o secretos.

## Consecuencias

- El laboratorio vuelve a generar costos temporales de Fargate, ALB, logs,
  almacenamiento ECR y dos alarmas CloudWatch mientras esté activo.
- La eliminación del stack retira ECS, ALB, red, dashboard y alarmas. La imagen
  ECR y ambos roles OIDC no se eliminan automáticamente.
- Esta extensión no altera los Proyectos 1, 2 o 3.
