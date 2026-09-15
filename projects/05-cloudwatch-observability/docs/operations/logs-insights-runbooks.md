# Runbooks y Logs Insights — Proyecto 5

## Alarma: error Lambda P2

1. Confirmar si `Errors` aumentó junto a `Invocations`.
2. Ejecutar la consulta en el log group Lambda de P2:

```text
fields @timestamp, @message, @requestId
| filter @message like /ERROR|Error|error/
| sort @timestamp desc
| limit 50
```

3. Correlacionar el request ID con la hora de la alarma.
4. Revisar si el error es de validación, dependencia DynamoDB o runtime.
5. Registrar conclusión y no modificar P2 durante la investigación.

## Alarma: API Gateway 5XX P2

1. Confirmar conteo 5XX y latencia de integración en el dashboard.
2. Revisar la alarma Lambda Error y la consulta de logs anterior.
3. Si Lambda no muestra error, documentar que la hipótesis pasa a API Gateway
   o integración, sin suponer la causa.

## Alarma: DynamoDB throttling P2

1. Confirmar la métrica exacta de throttles en la tabla.
2. Comparar con invocaciones Lambda y errores de la función.
3. Verificar configuración on-demand mediante el inventario; no cambiar
   capacidad o tabla desde P5.

## Alarma P4 existente: target no saludable o CPU alta

1. Revisar el panel ALB/ECS del dashboard P5.
2. Confirmar el estado del servicio ECS y target group solo mediante consultas
   de lectura.
3. El log group P4 no tenía datos durante el inventario; no generar tráfico ni
   modificar la aplicación para forzar logs.

## Prueba de incidente P5

Validada el 2026-09-14. La alarma propia P5 de errores Lambda se forzó a
`ALARM` mediante CloudWatch, sin acciones automáticas configuradas. Se ejecutó
la consulta guardada de Logs Insights sobre el grupo de logs existente de P2;
completó con dos filas. Finalmente, la alarma se devolvió a `OK` y el baseline
volvió a validarse. No se generó tráfico ni se modificaron P2/P4.
