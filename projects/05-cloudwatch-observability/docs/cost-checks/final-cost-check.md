# Cost Check final — Proyecto 5

**Fecha de lectura:** 2026-09-14

**Región:** `us-east-1`
**Método:** consultas de solo lectura a AWS Billing, CloudFormation y
CloudWatch.

## Recursos de P5 presentes

El stack `portfolio-p05-observability` está en `CREATE_COMPLETE` y contiene
solamente seis recursos propios:

- un dashboard CloudWatch;
- tres alarmas CloudWatch sin acciones configuradas;
- dos consultas guardadas de Logs Insights.

La comprobación posterior confirmó cero alarmas P5 con acciones de alarma,
recuperación o estado insuficiente. P5 no posee SNS, Synthetics, X-Ray,
Container Insights, métricas personalizadas ni recursos de aplicación.

## Estado de presupuesto

El presupuesto mensual `portfolio-zero-spend` mantiene un límite de USD 1.00,
una notificación y reportó gasto real de USD 0.00 al momento de la consulta.
No hubo forecast disponible.

Esto es un dato de Billing con retraso potencial. No garantiza costo cero ni
detiene automáticamente los recursos si se supera el límite.

## Riesgo de costo restante

CloudWatch se factura por uso y varía por región. Al momento de esta revisión,
la [página oficial de precios de CloudWatch](https://aws.amazon.com/cloudwatch/pricing/)
indica un Free Tier de tres dashboards personalizados, diez métricas de alarma
estándar y 5 GB mensuales compartidos para ingesta, archivado y datos
escaneados por Logs Insights. P5 usa un dashboard y cuatro métricas de alarma
estándar; durante esta fase ejecutó una consulta de Logs Insights que terminó
con dos filas.

Los límites pueden estar compartidos con otros usos de la cuenta, las reglas y
los precios pueden cambiar, y la consulta se cobra por datos escaneados. Por
ello, los límites no sustituyen el seguimiento de Billing. Los costos de P2 y
del laboratorio temporal de P4 están fuera de P5 y no se atribuyen a este
proyecto.

## Plan de limpieza

Cuando ya no se necesite la demostración, eliminar el stack P5 mediante la
[guía de limpieza](../operations/teardown-guide.md). Esa operación elimina
únicamente el dashboard, las tres alarmas y las dos consultas que pertenecen a
P5. Requiere una aprobación explícita antes de ejecutarse.
