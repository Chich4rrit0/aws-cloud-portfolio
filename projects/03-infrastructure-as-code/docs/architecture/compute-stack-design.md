# Diseño CloudFormation — Compute stack

## Contenido

El template `cloudformation/stacks/05-compute.yaml` modela el Target Group, ALB, listener HTTP, Launch Template, ASG, Log Group y políticas runtime adicionales de la arquitectura final del Proyecto 1.

## Controles reproducidos

- ALB internet-facing en las dos edge subnets; Target Group HTTP 3000 con health check `/health` y respuesta `200`.
- Listener HTTP con respuesta `403` por defecto; el Edge stack posterior añadirá la regla origin-only de CloudFront.
- ASG de desarrollo `min=1`, `desired=1`, `max=2`, con health check `ELB` y grace period de 300 segundos.
- Amazon Linux 2023 resuelto dinámicamente desde el parámetro público SSM, sin AMI ID escrito en Git.
- IMDSv2 obligatorio, root volume gp3 cifrado de 8 GiB y eliminación al terminar.
- Bootstrap sin SSH: descarga un release ZIP privado, instala dependencias, recupera la CA RDS, usa TLS y arranca `systemd` como usuario no-login.
- Log Group de siete días y permisos limitados a `s3:GetObject` en `releases/*` y publicación de logs solo al grupo del proyecto.

## Dependencias

Compute consume outputs de Network, Security, Data y Storage. Su listener queda bloqueado hasta que el Edge stack cree la distribución CloudFront y la regla del header origin-only. La contraseña de aplicación es un path SSM, no un valor incluido en el template.

## Costo y despliegue futuro

Este stack contiene ALB, ASG/EC2 y ejecución de bootstrap, por lo que es un cambio de costo relevante. El modo plan actual solo valida sintaxis. Antes de un deploy se debe aportar un ZIP aprobado, endpoint RDS, contraseña de aplicación ya creada, prefix list CloudFront y un Cost Check actualizado; después se requiere una estrategia explícita de teardown.
