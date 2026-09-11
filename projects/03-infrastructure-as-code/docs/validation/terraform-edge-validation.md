# Validación Terraform — Edge module

`terraform fmt`, `init -backend=false` y `validate` finalizaron correctamente.

El módulo representa OAC, CloudFront, acceso S3 privado limitado a la distribución, rutas `/api/*` y `/health` sin caché y la regla ALB origin-only. El header es una variable sensible sin valor en Git.

No se ejecutó `plan` o `apply`; no se creó infraestructura AWS.
