# Diseño Terraform — Compute module

`terraform/modules/compute` expresa el ALB, Target Group `/health`, listener con respuesta `403`, Launch Template, ASG `1/1/2`, Log Group de siete días y permisos runtime mínimos para release S3/logs.

El bootstrap usa Amazon Linux 2023, IMDSv2, root gp3 cifrado de 8 GiB, usuario no-login, `systemd`, TLS a RDS y CloudWatch Agent. La contraseña se solicita al iniciar desde el path SSM; no está en Terraform, el artefacto ni los logs.

Edge agregará la regla CloudFront origin-only al listener y Operations consumirá los nombres técnicos de ALB/Target Group. Un despliegue de esta capa tiene costo por ALB, EC2/ASG, EBS y logs, y requiere Cost Check explícito.
