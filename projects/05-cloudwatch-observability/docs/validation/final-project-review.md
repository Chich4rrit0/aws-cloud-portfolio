# Revisión final — Proyecto 5

**Fecha:** 2026-09-14

## Resultado

Proyecto 5 queda cerrado como entrega de portafolio. Demuestra un baseline de
observabilidad transversal, investigación con Logs Insights, alarmas de señal
mínima, un incidente controlado y control de costo documentado.

## Entregables verificados

- Dashboard P5 para señales de Lambda, API Gateway, DynamoDB, ECS, ALB y
  estado de alarmas.
- Tres recursos de alarma P5 que evalúan cuatro métricas estándar, sin acciones
  automáticas.
- Dos consultas guardadas de Logs Insights y runbooks de investigación.
- Incidente simulado en una alarma propia P5: `ALARM`, consulta completada y
  restauración a `OK`.
- Cost Check final, guía de teardown con modo de preflight y documentación de
  arquitectura y decisiones.

## Validaciones finales

El 2026-09-14 se ejecutaron correctamente:

1. Validación estática de la plantilla CloudFormation.
2. Validación de presencia del dashboard, tres alarmas sin acciones y dos
   consultas guardadas.
3. Lectura del stack `portfolio-p05-observability`, en estado
   `CREATE_COMPLETE`.
4. Preflight del teardown, que enumeró solo seis recursos P5 y no envió una
   eliminación a AWS.

## Límites y seguridad

P5 observó P2/P4 en modo de solo lectura y no modificó sus aplicaciones,
recursos, datos, IAM, red ni retención de logs. No se almacenaron credenciales
o secretos en el repositorio. Se excluyeron SNS, Synthetics, X-Ray, Container
Insights y métricas personalizadas para mantener el alcance y el riesgo de
costo bajo control.

## Estado operativo y limpieza futura

El stack P5 sigue activo únicamente para poder demostrar el dashboard, alarmas
y consultas. No hay teardown ejecutado. Cuando ya no sea necesario, la
[guía de limpieza](../operations/teardown-guide.md) elimina solamente los seis
recursos gestionados por P5; esa acción es destructiva y requiere una aprobación
explícita.
