# Cost Check — Phase 02: fundación de cómputo aplicada

## Recursos creados

- IAM role `portfolio-p02-lambda-role` con política inline mínima.
- Lambda `portfolio-p02-link-shortener` con runtime Node.js 22, ARM64, 128 MiB y timeout de 3 segundos.

## Costo estimado

No se configuró Provisioned Concurrency. La función tiene concurrencia reservada `0`, por lo que no puede ejecutarse hasta una aprobación posterior. Crear el rol y la función no mantiene cómputo activo; el cobro futuro dependerá de invocaciones y duración cuando se habilite.

## Costo real

No hay invocaciones de aplicación ni datos de prueba en esta fase. Los datos de facturación tienen retraso, por lo que no se declara un costo real todavía.

## Recursos que se pueden apagar o eliminar

La Lambda ya está pausada con concurrencia `0`. Para eliminarla se requerirá confirmación destructiva y se borrarán después su política y rol. No se deben borrar todavía porque serán necesarios para la integración controlada con API Gateway.

## Riesgo de costo inesperado

Sin permisos públicos de invocación, API Gateway ni concurrencia disponible, el riesgo de invocación accidental es bajo. El riesgo aumenta solo cuando se autorice quitar la pausa y crear el endpoint; ese cambio tendrá un Cost Check y aprobación propios.
