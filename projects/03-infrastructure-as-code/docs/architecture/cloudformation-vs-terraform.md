# CloudFormation vs Terraform — Comparativa final

| Capa | CloudFormation | Terraform | Controles equivalentes |
| --- | --- | --- | --- |
| Network | `01-network.yaml` | `modules/network` | VPC, seis subredes, IGW, sin NAT. |
| Security | `02-security.yaml` | `modules/security` | SG mínimos, Session Manager, SSM acotado. |
| Data | `03-data.yaml` | `modules/data` | RDS privado de desarrollo y cifrado. |
| Storage | `04-storage.yaml` | `modules/storage` | Buckets privados, ownership y SSE-S3. |
| Compute | `05-compute.yaml` | `modules/compute` | ALB, ASG 1/1/2, IMDSv2 y logs. |
| Edge | `06-edge.yaml` | `modules/edge` | OAC, CloudFront, API sin caché y origin guard. |
| Operations | `07-operations.yaml` | `modules/operations` | Alarma HealthyHostCount sin acciones. |

CloudFormation divide el despliegue por stacks y outputs; Terraform divide la misma arquitectura por módulos y outputs. Ninguna implementación importa ni administra recursos de los Proyectos 1 o 2.
