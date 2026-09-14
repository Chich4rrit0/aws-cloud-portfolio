# Validación end-to-end ECS/Fargate — Proyecto 4

## Alcance

Validación temporal del stack `portfolio-p04-ecs-lab` creado desde el template
CloudFormation del Proyecto 4. La imagen inmutable existente en ECR se ejecutó
en una única tarea Fargate detrás de un ALB público HTTP.

## Resultado

| Control | Resultado |
|---|---|
| CloudFormation | Stack alcanzó `CREATE_COMPLETE`. |
| ECS | Servicio activo con una tarea deseada y una tarea ejecutándose. |
| Target group | Un target en estado `healthy`. |
| Endpoint | `/health` respondió con `status: ok`. |
| CloudWatch Logs | Log stream de la tarea presente. |
| Imagen | Tag SHA inmutable validado antes del despliegue. |
| Red | VPC aislada, dos subredes públicas, sin NAT Gateway. |

## Ruta demostrada

```text
GitHub Actions CI
  -> ECR privado con imagen sha-<commit>
  -> CloudFormation
  -> ECS/Fargate
  -> ALB /health
  -> CloudWatch Logs
```

## Límites intencionales

La ventana usa HTTP y una tarea pública temporal para evitar NAT Gateway. No
es un patrón de producción; no incluye TLS, dominio, WAF, auto scaling, base
de datos ni despliegue automático de GitHub hacia ECS. Estos límites se
mantienen explícitos para separar la evidencia de portafolio de una plataforma
productiva.

## Cost Check durante la validación

Al consultar el presupuesto durante la ventana, el gasto reportado seguía en
USD 0.00 sobre USD 1.00. Ese resultado puede retrasarse respecto de cargos
reales; ALB, Fargate, IPv4 pública y logs se consideran costo potencial hasta
confirmar el teardown.
