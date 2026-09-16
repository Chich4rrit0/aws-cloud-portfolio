# Cost Check — Fase 01: auditoría de estado actual

**Fecha de lectura:** 2026-09-16

## Recursos creados por P6

Ninguno. La auditoría consultó APIs AWS de solo lectura.

## Recursos con posible costo observados en P1

La auditoría confirma que siguen activos componentes con costo potencial o
recurrente: ASG con una instancia, RDS, ALB, CloudFront y CloudWatch Logs. No
se atribuyen sus costos a P6; pertenecen al workload P1 que se mantiene como
demostración.

## Estado de presupuesto

El presupuesto mensual `portfolio-zero-spend` mantiene límite de USD 1.00, una
notificación y reportó USD 0.00 de gasto real al momento de la lectura. No hubo
forecast disponible.

Billing puede tener retraso. El valor reportado no confirma costo final cero ni
detiene automáticamente el gasto al superar el límite.

## Riesgo y decisión

P6 no ejecuta teardown. El [runbook de limpieza de P1](../../../../docs/operations/project-01-cleanup.md)
es el procedimiento aplicable si se decide retirar el workload; es destructivo
y requiere aprobación explícita separada.
