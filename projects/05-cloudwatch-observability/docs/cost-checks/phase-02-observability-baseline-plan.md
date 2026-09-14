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

## Resultado aplicado

El baseline se creó el 2026-09-14 mediante el stack
`portfolio-p05-observability`: un dashboard, tres recursos de alarma que
evalúan cuatro métricas estándar y dos queries guardadas. Antes del despliegue
había un dashboard y cuatro alarm metrics estándar; el baseline deja dos
dashboards y ocho alarm metrics estándar, dentro de los límites Free Tier
verificados para esta cuenta en ese momento.

El budget reportó USD 0.00 al validar. Es una lectura de Billing con posible
retraso, no una garantía de costo final cero.
