# Runbook — Project 01 deployment

## Propósito

Publicar una nueva versión de la aplicación sin credenciales en código, sin SSH y sin dejar el ASG sin capacidad saludable.

## Antes de comenzar

1. Confirmar que no haya otro despliegue, refresh o demostración de Auto Scaling en curso.
2. Ejecutar el preflight y revisar Billing/Budgets.
3. Obtener aprobación explícita: el procedimiento crea un objeto S3, una versión de Launch Template y reemplaza instancias de forma controlada.
4. Mantener `min=1`, `desired=1`, `max=2`; el refresh puede usar temporalmente una segunda EC2.

```powershell
.\scripts\powershell\Test-AwsPortfolioPreflight.ps1 `
  -ProfileName '<aws-cli-profile>'
```

## 1. Validar localmente

```powershell
Set-Location .\projects\01-web-task-manager\app
npm ci
npm test
```

No publicar `.env`, `node_modules`, credenciales ni artefactos locales.

## 2. Publicar el artefacto privado

Desde la raíz del repositorio:

```powershell
.\scripts\powershell\Publish-Project01Artifact.ps1 `
  -ProfileName '<aws-cli-profile>' `
  -Region us-east-1 `
  -Execute
```

El script empaqueta `app` y `frontend`, excluye `node_modules` y `.env`, y sube el ZIP al prefijo privado `releases/`.

## 3. Preparar el nuevo bootstrap de EC2

```powershell
.\scripts\aws-cli\New-Project01ApplicationCompute.ps1 `
  -ProfileName '<aws-cli-profile>' `
  -Region us-east-1 `
  -CreateNewLaunchTemplateVersion `
  -EnableCloudWatchLogs `
  -Execute
```

Este paso actualiza el ASG para futuros launches; no reemplaza por sí solo la instancia existente. Verificar que la nueva versión conserva CloudWatch Agent, IMDSv2, acceso al artefacto privado, acceso a un solo parámetro y TLS hacia RDS.

## 4. Refresh protegido

Iniciar un instance refresh solo tras revisar el Launch Template. Usar 100% de capacidad saludable mínima para que AWS registre una instancia sana en el Target Group antes de terminar la anterior. Este cambio requiere aprobación explícita y supervisión activa.

No usar `terminate-instances` manualmente: el ASG puede reemplazar la instancia y producir resultados no deseados.

## 5. Publicar frontend e invalidar caché

```powershell
.\scripts\aws-cli\Publish-Project01Frontend.ps1 `
  -ProfileName '<aws-cli-profile>' `
  -Region us-east-1 `
  -Execute
```

El script sincroniza el frontend privado y crea una invalidación `/*`. Evitar invalidaciones innecesarias porque son eventos de uso de CloudFront.

## 6. Validar

```powershell
.\scripts\aws-cli\Test-Project01ApplicationDeployment.ps1 `
  -ProfileName '<aws-cli-profile>' `
  -Region us-east-1 `
  -Execute

.\scripts\aws-cli\Test-Project01Observability.ps1 `
  -ProfileName '<aws-cli-profile>' `
  -Region us-east-1 `
  -Execute

.\scripts\aws-cli\Test-Project01CloudFrontDelivery.ps1 `
  -ProfileName '<aws-cli-profile>' `
  -Execute
```

Las validaciones CRUD limpian sus tareas temporales. Si falla una, detener el despliegue, conservar evidencia de logs y usar el runbook de rollback en vez de aplicar cambios ad hoc.
