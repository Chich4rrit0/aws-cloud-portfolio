# Validación local del contenedor

## Propósito

La imagen de Proyecto 4 encapsula el backend cerrado de Proyecto 1 sin
modificarlo. Usa `npm ci --omit=dev`, ejecuta como el usuario no privilegiado
`node` y ofrece un health check contra `/health`.

## Comando de validación

Desde la raíz del repositorio:

```powershell
.\projects\04-devops-cicd\scripts\Test-Project04Container.ps1
```

El script construye una imagen local, arranca un contenedor efímero con un
puerto de loopback aleatorio, comprueba `/health` y elimina el contenedor al
finalizar. Conserva la imagen local para reutilizarla en validaciones
posteriores; no publica nada en ECR ni realiza llamadas a AWS.

## Límites de seguridad

- La construcción usa como contexto solo `projects/01-web-task-manager/app`.
- No copia `.env`, secretos ni `node_modules` al contenedor.
- La prueba se publica solo en `127.0.0.1`, no en todas las interfaces.
- La prueba usa el store en memoria por defecto; no requiere base de datos.
