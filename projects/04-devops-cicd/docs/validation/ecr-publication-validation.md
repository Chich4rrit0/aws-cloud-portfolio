# Validación de primera publicación ECR — Proyecto 4

## Alcance

Validación funcional controlada de la ruta GitHub Actions → OIDC → ECR privado.
Se ejecutó una sola publicación manual desde `main`. No se desplegó ningún
servicio ni infraestructura de cómputo.

## Resultado del workflow

El workflow **Project 04 Publish ECR** completó correctamente estos pasos:

1. Checkout del commit de `main`.
2. Intercambio del token OIDC por credenciales AWS temporales.
3. Login en el registro ECR privado.
4. Build de la imagen a partir del backend de referencia del Proyecto 1 y el
   Dockerfile del Proyecto 4.
5. Push de una imagen con etiqueta inmutable `sha-<commit>`.
6. Consulta `ecr:BatchGetImage` para recuperar el tag y digest publicados.

El run terminó exitosamente en 33 segundos. El enlace se mantiene en la
historia de GitHub Actions del repositorio privado; no contiene secretos AWS.

## Verificación AWS posterior

| Control | Resultado |
|---|---|
| Cantidad de imágenes en ECR | 1 |
| Tag | `sha-f0e12d4587b74973f84669b1a3d87847511a19f1` |
| Digest | `sha256:df4c434124c7d55ac654b1873cfcc4967382936e0b20f002032c2c9270bd6c24` |
| Tamaño registrado | 49,596,533 bytes |
| Mutabilidad de tags | `IMMUTABLE` |
| Reglas de lifecycle | 2 |
| Escaneo al publicar | No configurado, conforme al alcance inicial |
| Presupuesto al consultar | USD 0.00 de USD 1.00 |

El valor de gasto es el costo reportado en ese momento y puede tener retraso.
La imagen sí representa almacenamiento ECR y se incluye como riesgo de costo
recurrente hasta eliminarla mediante un teardown aprobado.

## Controles demostrados

- No se almacenaron Access Keys en GitHub ni en el repositorio.
- El rol solo pudo ser asumido por el repositorio identificado de forma
  inmutable y la rama `main`.
- El tag corresponde al SHA exacto del commit y no puede sobrescribirse.
- El rol no permitió eliminar imágenes, crear repositorios ni operar ECS.

## Límites y siguiente etapa

Esta validación prueba la entrega de una imagen a ECR, no una aplicación
ejecutándose. ECS/Fargate, ALB, CloudWatch Logs y su teardown requieren un
diseño, Cost Check y autorización separados.
