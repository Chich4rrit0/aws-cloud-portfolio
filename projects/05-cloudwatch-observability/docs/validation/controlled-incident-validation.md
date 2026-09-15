# Validación — incidente controlado P5

**Fecha:** 2026-09-14  
**Resultado:** aprobado

## Objetivo

Verificar el ciclo operativo de una alarma de P5 y el runbook de Logs Insights
sin degradar, invocar o modificar recursos de los proyectos cerrados.

## Ejecución

1. Se verificó que la alarma P5 de errores Lambda no tenía acciones de alarma,
   recuperación ni estado insuficiente configuradas.
2. Se forzó temporalmente su estado a `ALARM` mediante CloudWatch.
3. Se ejecutó la consulta guardada de errores Lambda sobre el grupo de logs
   existente de P2, con ventana de siete días.
4. La consulta terminó con estado `Complete` y dos filas.
5. La alarma se restauró explícitamente a `OK`.
6. Se ejecutó de nuevo la validación del baseline: dashboard, tres alarmas sin
   acciones y dos consultas guardadas presentes.

## Límites respetados

- No se generó tráfico de aplicación ni errores Lambda reales.
- No se cambió ningún recurso, configuración o dato de P2/P4.
- No se crearon recursos nuevos ni se eliminaron recursos.
- No se registraron mensajes de logs, URLs, identificadores de cuenta ni
  secretos en esta evidencia.

## Consideración de costo

La consulta de Logs Insights puede generar cargo por datos escaneados. El grupo
consultado era existente y pequeño, pero Billing puede reflejar el uso con
retraso. La evidencia de la prueba no equivale a una confirmación de costo
cero.
