# Blueprint — Project 04 DevOps / CI-CD

## Problema

Los Proyectos 1 y 2 demuestran aplicaciones desplegadas y el Proyecto 3 su
reconstrucción declarativa. Este proyecto debe demostrar cómo una modificación
validada se transforma en una imagen de contenedor trazable y se entrega a un
runtime administrado, sin convertir la cuenta de aprendizaje en un entorno
permanente.

## Alcance inicial

La fuente de referencia será el backend Node.js ya cerrado en
`projects/01-web-task-manager/app`. Proyecto 4 no cambiará esa fuente. Su
Dockerfile, pruebas de integración de contenedor, automatización y documentos
se mantendrán bajo `projects/04-devops-cicd`.

La prueba AWS futura, si se aprueba, tendrá este flujo:

```text
GitHub Actions (OIDC)
  -> ECR privado
  -> ECS/Fargate, tareas en subredes públicas con IP pública temporal
  -> Application Load Balancer
  -> CloudWatch Logs
```

ECS tendrá una tarea mínima saludable. No se usará NAT Gateway: para un
laboratorio corto la tarea pública tiene salida necesaria para obtener la
imagen y enviar logs. Esta es una decisión deliberadamente de laboratorio,
no un patrón de producción.

## Controles de entrega

1. Pull request: instalar dependencias bloqueadas, ejecutar pruebas y validar
   el Docker build; no publica ni despliega.
2. Push a `main`: repetir pruebas, publicar una imagen privada etiquetada con
   el SHA del commit y, solo después, actualizar el servicio ECS.
3. El rol GitHub OIDC tendrá permisos mínimos, restringidos al repositorio y
   rama aprobados.
4. El despliegue se verifica por estabilidad del servicio, estado de targets,
   `/health` y CloudWatch Logs.
5. La ventana E2E termina con teardown explícitamente autorizado.

## Deliberadamente fuera de alcance

- Access Keys en secretos de GitHub.
- Registro público de imágenes.
- NAT Gateway, Route 53, ACM, WAF y una base de datos para esta demostración.
- Reutilizar o cambiar recursos de Proyectos 1, 2 o 3.
- Despliegue AWS durante el blueprint.

## Pendientes antes de desplegar

- Validar Docker y GitHub CLI locales.
- Definir la infraestructura aislada del laboratorio, las políticas OIDC y el
  Cost Check con precios vigentes en `us-east-1`.
- Aprobar explícitamente la creación de ECR, ECS/Fargate, ALB, roles y logs.
