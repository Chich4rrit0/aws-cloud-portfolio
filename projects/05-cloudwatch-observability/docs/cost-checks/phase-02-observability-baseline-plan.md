# Cost Check — Fase 02: baseline de observabilidad propuesto

## Recursos propuestos, aún no creados

- Un dashboard CloudWatch P5.
- Hasta tres alarmas CloudWatch P5 sin acciones.
- Opcionalmente, consultas guardadas de Logs Insights.

## Recursos excluidos

No se propone crear SNS, Synthetics, Container Insights, X-Ray ni métricas
personalizadas. Tampoco se modifica la configuración de logs de P2/P4.

## Riesgo de costo

Las alarmas son recursos recurrentes mientras existan. Logs Insights puede
facturar por datos escaneados cuando se ejecuten consultas. Dashboard y lecturas
de métricas deben confirmarse con la información de precios vigente antes de
crear recursos. El presupuesto alerta con retraso y no bloquea automáticamente.

## Eliminación prevista

Al cierre se eliminarán dashboard, alarmas y consultas guardadas que pertenezcan
a P5. Las fuentes P2/P4 no se eliminan ni modifican desde este proyecto.
