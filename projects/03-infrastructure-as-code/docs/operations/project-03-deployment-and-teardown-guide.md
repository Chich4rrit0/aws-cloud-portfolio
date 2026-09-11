# Guía de despliegue y teardown — Proyecto 3

## Propósito

Esta guía documenta un procedimiento futuro; no autoriza un despliegue. Antes de cualquier acción se deben confirmar región, precios, presupuesto, versión PostgreSQL, artefacto, AZs, prefix list CloudFront y secretos suministrados solo desde un canal local seguro.

## Despliegue controlado

1. Validar CloudFormation y Terraform.
2. Realizar Cost Check específico y obtener aprobación explícita.
3. Desplegar: Network, Security, Data, Storage, Compute, Edge y Operations.
4. Verificar target saludable, logs, alarma sin acciones, CloudFront y CRUD con evidencia saneada.

No importar ni reutilizar recursos de los Proyectos 1 o 2. No versionar estados, endpoints, contraseñas, JWTs ni headers origin-only.

## Teardown controlado

1. Confirmar respaldo o prescindencia de datos.
2. Retirar Edge y esperar deshabilitación CloudFront.
3. Eliminar Compute y Operations; confirmar que no queden instancias o ALB.
4. Eliminar Data según estrategia aprobada de snapshot.
5. Vaciar/eliminar Storage solo con aprobación para destruir objetos.
6. Eliminar Security y Network en orden inverso de dependencias.

Cada fase debe verificarse en AWS y Billing. Ninguna acción destructiva debe ejecutarse sin autorización específica.
