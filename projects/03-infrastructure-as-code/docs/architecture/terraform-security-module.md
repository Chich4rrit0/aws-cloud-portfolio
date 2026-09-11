# Diseño Terraform — Security module

## Equivalencia

`terraform/modules/security` reproduce los tres Security Groups y la identidad runtime de EC2 del Security stack de CloudFormation.

Los Security Groups se crean con listas vacías de ingress/egress para eliminar la salida allow-all implícita. Las reglas se expresan como recursos independientes: ALB desde la prefix list de CloudFront hacia App, App hacia ALB/DB/HTTP/HTTPS y DB solo desde App.

## IAM y secretos

El rol de EC2 confía solo en el servicio EC2, usa la política administrada de Session Manager y una política inline limitada a `ssm:GetParameter` para el path de contraseña de aplicación. Terraform construye el ARN en tiempo de plan usando la identidad de la cuenta; ningún ID de cuenta, contraseña ni valor SecureString se escribe en Git.

## Límite de plan

El ID de la prefix list CloudFront es obligatorio y específico de la cuenta/región. No se inventa ni tiene valor por defecto. Su consulta y la resolución de identidad ocurrirán solo durante un plan aprobado; esta fase solo ejecuta validación estática.
