# Plan Terraform — Compute module

## Alcance siguiente

El módulo Terraform Compute reproducirá el ALB, Target Group HTTP `3000` con health check `/health`, listener con respuesta `403` por defecto, Launch Template y ASG `min=1`, `desired=1`, `max=2`.

La instancia usará Amazon Linux 2023 resuelto en tiempo de plan, IMDSv2 obligatorio, volumen raíz gp3 cifrado de 8 GiB y Log Group con retención de siete días. El release ZIP, endpoint RDS y path de contraseña se recibirán como valores de integración; ningún secreto se versionará.

## Dependencias

Consume Network, Security, Data y Storage. Edge agregará después la regla origin-only al listener y Operations consumirá los nombres técnicos de ALB/Target Group para la alarma.

## Guardrail

ALB, ASG/EC2, EBS y CloudWatch Logs pueden generar costos si se aplican. En esta fase se escribirá y validará código local, sin `plan` ni `apply`.
