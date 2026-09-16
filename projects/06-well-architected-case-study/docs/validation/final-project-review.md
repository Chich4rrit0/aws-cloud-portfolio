# Revisión final — Proyecto 6

**Fecha:** 2026-09-16

## Resultado

Proyecto 6 queda cerrado como un case study Well-Architected basado en
evidencia. El entregable conecta arquitectura actual, fortalezas, trade-offs,
gaps, backlog priorizado y una arquitectura objetivo no desplegada.

## Validaciones realizadas

1. Auditoría AWS de solo lectura de P1 con sesión válida.
2. Lectura del presupuesto existente: límite USD 1.00, una notificación y gasto
   reportado USD 0.00 al momento de la consulta, sujeto al retraso de Billing.
3. Validación sintáctica del script de auditoría PowerShell.
4. Validación de todos los enlaces Markdown internos de P6.
5. Escaneo de patrones de credenciales en P6.

Todas las validaciones terminaron correctamente después de corregir un enlace
relativo al runbook de limpieza de P1.

## Evidencia y conclusión

La auditoría confirma que P1 permanece desplegado, con su ASG de capacidad
uno, RDS Single-AZ, ALB, CloudFront, alarma sin acciones y log retention de
siete días. Esto refuerza la conclusión central: el workload es apropiado para
demostración y aprendizaje, pero no debe describirse como producción lista sin
resolver identidad, autorización, TLS de origen, recuperación y controles
operativos priorizados.

## Exclusiones respetadas

- No se crearon, actualizaron, pausaron ni eliminaron recursos AWS.
- No se modificaron P1, P2, P3, P4 o P5.
- No se ejecutaron pruebas de carga, restore, tráfico de aplicación ni Logs
  Insights.
- No se almacenaron cuentas, endpoints, IDs, secretos o credenciales.

## Estado posterior al cierre

P6 no administra infraestructura y no requiere teardown. P1 conserva recursos
activos que pueden generar costos; cualquier pausa o eliminación debe usar su
runbook propio y una aprobación explícita. Las recomendaciones de P6 son
propuestas y no cambios aplicados.
