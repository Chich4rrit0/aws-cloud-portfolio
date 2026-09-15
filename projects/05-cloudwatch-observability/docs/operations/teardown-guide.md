# Guía de limpieza — Proyecto 5

## Alcance y advertencia

⚠️ **ACCIÓN DESTRUCTIVA.** El teardown elimina el stack
`portfolio-p05-observability` y sus seis recursos propios:

- un dashboard CloudWatch;
- tres alarmas CloudWatch de P5;
- dos consultas guardadas de Logs Insights de P5.

No elimina ni modifica P2, P4, sus aplicaciones, datos, logs, red, IAM ni el
presupuesto de la cuenta. El stack P5 no contiene datos persistentes; aun así,
el dashboard, alarmas y consultas dejarán de estar disponibles después del
teardown.

## Preflight sin cambios

Desde la carpeta de Proyecto 5, ejecutar:

```powershell
.\scripts\Remove-Project05Baseline.ps1
```

El modo predeterminado solo muestra el stack y los recursos que serían
eliminados. No envía una eliminación a AWS.

## Ejecución aprobada

Solo después de una autorización explícita, ejecutar:

```powershell
.\scripts\Remove-Project05Baseline.ps1 -Destroy
```

PowerShell pedirá una confirmación adicional. El script espera a que
CloudFormation complete la eliminación y comprueba que no queden recursos con
el prefijo `portfolio-p05-`.

## Después del teardown

1. Confirmar que el stack ya no exista y que los contadores P5 sean cero.
2. Revisar Billing más tarde: los cargos de CloudWatch y Logs Insights pueden
   aparecer con retraso.
3. Mantener la documentación y el historial Git como evidencia del proyecto;
   no recrear recursos salvo una nueva decisión y aprobación.
