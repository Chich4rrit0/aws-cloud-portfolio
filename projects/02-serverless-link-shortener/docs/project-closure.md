# Cierre de Proyecto 02 — Serverless Link Shortener

## Estado de entrega

**Cerrado como proyecto de portafolio.** El alcance aprobado está implementado, verificado y documentado. No se planifican cambios adicionales en este proyecto; las mejoras futuras pertenecen a proyectos posteriores o a una nueva fase aprobada explícitamente.

## Capacidades entregadas

| Capacidad | Implementación | Verificación |
| --- | --- | --- |
| Crear un enlace | `POST /urls` con JWT Cognito. | `201 Created` en la validación autenticada. |
| Resolver un enlace | `GET /r/{code}` público. | `302 Found` en la validación autenticada. |
| Eliminar por ownership | `DELETE /urls/{code}` con JWT Cognito. | `204 No Content` y ausencia del ítem en DynamoDB. |
| Rechazar mutaciones anónimas | JWT authorizer de API Gateway. | `401 Unauthorized` sin JWT. |
| Resolver códigos inexistentes | Lambda + DynamoDB. | `404 Not Found`. |
| Evitar residuos de prueba | Borrado y lectura de confirmación. | DynamoDB quedó con 0 elementos. |

## Evidencia técnica

- Suite local: **19 tests aprobados, 0 fallos**.
- Validación autenticada: creación `201`, redirect `302`, eliminación `204` y limpieza DynamoDB confirmada.
- Validaciones negativas: `404` para código inexistente y `401` para mutación sin JWT.
- CloudWatch: seis invocaciones Lambda durante la ventana de validación y cero errores reportados.
- Retención del Log Group: siete días.

No se tomaron capturas por decisión del responsable del proyecto. La evidencia se conserva como resultados reproducibles de pruebas y consultas AWS de solo lectura.

## Arquitectura entregada

```mermaid
flowchart LR
    Viewer((Viewer)) -->|GET /r/{code}| API[API Gateway HTTP API]
    Admin((Admin)) -->|JWT| API
    API --> Lambda[Lambda]
    Lambda --> DDB[(DynamoDB On-Demand)]
    Lambda --> Logs[CloudWatch Logs]
    Cognito[Cognito User Pool] -->|JWT validation| API
```

La superficie pública se limita al redirect. Las rutas de administración requieren un JWT Cognito. Lambda no está en una VPC y no existen servidores, NAT Gateway, ALB, RDS, CloudFront, Route 53, WAF ni frontend AWS en este alcance.

## Estado operativo y costos

El proyecto está cerrado funcionalmente, pero su infraestructura aún existe. API Gateway, Lambda, DynamoDB On-Demand y CloudWatch Logs son servicios de pago por uso; Cognito Lite y los créditos o beneficios de la cuenta no sustituyen la revisión de Billing.

El Budget es una alerta diferida, no un interruptor automático. La ruta pública puede recibir solicitudes; el throttling del stage reduce abuso, pero no garantiza un tope de facturación.

## Limpieza futura

No se ejecutó limpieza al cerrar el alcance, porque eliminar o pausar recursos alteraría la demostración desplegada. Si se decide detener la exposición, requerirá aprobación explícita y esta secuencia:

1. Establecer concurrencia reservada `0` en Lambda si se quiere bloquear invocaciones sin retirar la API.
2. Eliminar la HTTP API y luego el permiso de invocación de Lambda si se quiere retirar el endpoint público.
3. Eliminar Lambda, su rol y política, Cognito, DynamoDB y el Log Group solo si se decide destruir totalmente el proyecto.

Los pasos 2 y 3 son destructivos. Eliminar DynamoDB borra enlaces y no es reversible sin backups, que no están habilitados en esta configuración de laboratorio.

## Aprendizajes demostrados

- Selección de arquitectura serverless para carga pequeña o irregular.
- IAM de mínimo privilegio y autorización JWT gestionada por API Gateway.
- Persistencia DynamoDB On-Demand con escritura condicional y TTL.
- Automatización PowerShell/AWS CLI reproducible y empaquetado Lambda.
- Validación de rutas positivas y negativas, observabilidad básica y disciplina de limpieza.
