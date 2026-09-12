# ADR-001 — OIDC de GitHub Actions y entrega temporal a ECS/Fargate

## Estado

Aceptada para el blueprint; pendiente de implementación y autorización AWS.

## Contexto

Proyecto 4 debe demostrar CI/CD hacia ECR y ECS/Fargate conservando el límite
de costo y la regla de no almacenar credenciales AWS estáticas.

## Decisión

GitHub Actions autenticará contra AWS mediante OpenID Connect y un rol IAM
temporal de mínimo privilegio. Las imágenes se publicarán en un repositorio
ECR privado con una etiqueta derivada del commit. ECS/Fargate y su ALB se
crearán únicamente para una demostración temporal y se eliminarán mediante un
teardown aprobado.

## Alternativas evaluadas

### Access Keys en GitHub Secrets

Más rápido al comienzo, pero deja credenciales de larga duración en un sistema
externo y exige rotación. Se descarta.

### Desplegar manualmente desde la estación local

Útil para diagnóstico, pero no demuestra CI/CD completo. Se conserva solo
como apoyo de validación, no como ruta principal de entrega.

### ECS en subredes privadas con NAT Gateway

Es el patrón más cercano a producción, pero NAT Gateway añade costo recurrente
alto para un laboratorio corto. Se posterga; la prueba aislada usará tareas
públicas sin administración entrante.

## Consecuencias

Se requerirán una identidad OIDC, roles IAM separados para GitHub Actions y
ECS, ECR, ECS/Fargate, ALB y CloudWatch Logs. Todos son recursos con potencial
de costo, por lo que permanecen sin crear hasta completar el Cost Check y
recibir autorización específica.
