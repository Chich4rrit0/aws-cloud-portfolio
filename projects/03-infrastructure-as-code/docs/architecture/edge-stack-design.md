# Diseño CloudFormation — Edge stack

## Contenido

El template `cloudformation/stacks/06-edge.yaml` completa la entrega de la reconstrucción aislada con:

- Una distribución CloudFront con el dominio predeterminado y `PriceClass_100`.
- Un Origin Access Control (OAC) y una bucket policy limitada a esa distribución para el frontend S3 privado.
- Comportamientos sin caché para `/api/*` y `/health`, apuntando al ALB por HTTP.
- Una regla del listener que reenvía al Target Group solo cuando recibe el header origin-only de CloudFront; la acción por defecto `403` se conserva en el Compute stack.
- Un `SecureString` estándar que conserva el valor del header, sin exportarlo ni escribirlo en Git.

## Trade-off de seguridad

El header no sustituye controles de red: es una protección de capa 7 frente a accesos directos al ALB. Se conserva porque la lista administrada de prefijos origin-facing de CloudFront no estaba disponible en la cuenta del Proyecto 1. El tráfico CloudFront → ALB permanece HTTP de forma temporal; HTTPS de extremo a extremo requiere un dominio, ACM y listener HTTPS, fuera del alcance aprobado.

`NoEcho` evita mostrar el valor en parámetros y outputs de CloudFormation, pero los administradores de la cuenta con permisos de lectura de configuración de CloudFront/ALB podrían inspeccionar el header. El acceso administrativo debe mantenerse bajo mínimo privilegio.

## Dependencias y despliegue futuro

El stack requiere los outputs de Storage y Compute, más un valor de header generado localmente y nunca almacenado en archivos. La regla usa prioridad `10`, por lo que un despliegue real debe comprobar que no existe una prioridad igual en ese listener aislado.

## Costo y limpieza

CloudFront, S3 y las invalidaciones generan consumo según uso; la distribución no utiliza un plan de precio fijo. Para desmontar de forma segura: primero se elimina la regla del ALB o se desmantela el Compute stack, luego se deshabilita y elimina la distribución, se retiran OAC/policy, se vacía el bucket y finalmente se elimina el parámetro. Son acciones destructivas que exigirán aprobación explícita.
