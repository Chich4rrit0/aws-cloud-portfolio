# Cost Check — Project 04 / Phase 00 bootstrap

## Recursos creados

- Repositorio ECR privado `portfolio-p04-task-manager` en `us-east-1`, vacío.
- Proveedor IAM OIDC para `token.actions.githubusercontent.com`.
- Rol IAM `portfolio-p04-github-actions-ecr-publisher`, limitado a publicación
  en el repositorio ECR del Proyecto 4 desde GitHub Actions en `main`.

No se crearon tareas ECS/Fargate, ALB, red, logs, secretos, ni imágenes ECR.

Actualización posterior: se publicó una única imagen privada e inmutable en
ECR mediante el workflow OIDC aprobado. Por lo tanto, ECR deja de estar vacío
y existe almacenamiento de imagen que debe considerarse en el siguiente Cost
Check. El presupuesto aún mostraba USD 0.00 al terminar la validación, con la
advertencia habitual de retraso en los datos de facturación.

## Auditoría previa a ECR

Antes de crear ECR se verificó por AWS CLI, de forma exclusiva de lectura, que
no existían repositorios ECR en `us-east-1`. Después de la creación aprobada
se verificó que el repositorio existe, mantiene tags inmutables y contiene cero
imágenes. El presupuesto
`portfolio-zero-spend` mostraba gasto real `0.00` sobre su límite mensual de
USD 1.00.

## Recursos con posible costo futuro

- ECR: almacenamiento de imágenes y solicitudes.
- ECS/Fargate: vCPU y memoria mientras una tarea está activa.
- Application Load Balancer: cargo por tiempo y capacidad.
- CloudWatch Logs: ingestión y almacenamiento.
- Transferencia de datos: depende de uso y región.

IAM OIDC y el rol no ejecutan cómputo ni almacenan imágenes; no se espera un
cargo directo por ellos. ECR no tiene una instancia que se mantenga activa,
pero el almacenamiento de imágenes privadas sí puede generar cargos. AWS
informa 500 MB mensuales de Free Tier para nuevos clientes de ECR privado
durante un año; la elegibilidad real se debe verificar en la cuenta y no se
asume. El almacenamiento, las solicitudes y transferencia fuera de región
siguen siendo riesgos de costo.

## Controles previstos

- Ejecutar una única tarea mínima durante una ventana corta.
- Eliminar servicio, cluster, ALB, target group, ECR e identidades temporales
  tras tomar evidencia.
- Mantener solo imágenes imprescindibles y vaciar/eliminar ECR durante el
  teardown aprobado.
- No crear NAT Gateway, Elastic IP, dominio, ACM o WAF.

## Riesgo de costo inesperado

ALB y Fargate siguen generando cargos mientras estén activos. Un presupuesto
alerta, pero no apaga recursos automáticamente; el teardown validado es el
control principal.
