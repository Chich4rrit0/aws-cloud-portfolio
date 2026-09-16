# Auditoría de estado actual — Proyecto 6

## Propósito

El assessment inicial usa evidencia histórica. Este script complementa ese
material con una fotografía puntual de recursos P1, sin crear, cambiar ni
eliminar nada en AWS.

## Ejecución

Desde la carpeta de P6:

```powershell
.\scripts\Get-Project06CurrentState.ps1
```

Si la sesión temporal expiró, renovar primero la autenticación local:

```powershell
aws login --profile portfolio-root-temp
```

El script comprueba VPC, ASG, RDS, ALB, distribución CloudFront, alarma y log
group de P1. Su salida deliberadamente omite endpoints, IDs, dominios, cuentas,
secretos y cabeceras privadas.

## Límites

- Es una lectura puntual, no confirma costos acumulados ni disponibilidad
  histórica.
- No ejecuta tráfico de aplicación, Logs Insights ni pruebas de recuperación.
- Un recurso ausente se reporta como tal; el script no intenta recrearlo.
- La salida debe usarse como evidencia con fecha, no como sustituto de los
  runbooks y validaciones de P1.
