# Runbook — Project 01 pause and cleanup

## Alcance y advertencia

Este runbook contiene acciones que pueden interrumpir el servicio, eliminar datos o producir cargos residuales. Cada acción requiere aprobación explícita, revisión de dependencias y validación posterior.

## Pausa temporal

| Acción | Ahorro | Consecuencia |
| --- | --- | --- |
| ASG `desired=0` y `min=0` | Elimina costo de EC2/EBS de instancias terminadas. | API deja de estar disponible; el ALB y RDS siguen generando costo. |
| Detener RDS | Reduce cómputo RDS por un período limitado. | Aplicación falla; storage y backups siguen costando; RDS se reinicia automáticamente según los límites de AWS. |
| Deshabilitar CloudFront | Evita servir tráfico nuevo. | Requiere propagación y no elimina los otros recursos. |

No usar una pausa como sustituto de teardown: ALB, RDS storage/backups, S3 y logs pueden seguir generando cargos.

## Teardown completo — orden seguro

1. Confirmar backup o snapshot final de RDS y su costo de almacenamiento.
2. Guardar capturas, resultados de validación y decisiones necesarias para el portfolio.
3. Reducir o eliminar el ASG; esperar terminación de instancias y volúmenes asociados.
4. Eliminar listener, Target Group y ALB.
5. Deshabilitar CloudFront, esperar propagación y eliminar la distribución; luego eliminar OAC y política dependiente.
6. Vaciar y eliminar buckets de frontend y artefactos, considerando objetos retenidos.
7. Eliminar RDS y decidir explícitamente si se crea final snapshot; eliminar DB subnet group solo cuando RDS ya no exista.
8. Eliminar parámetros SecureString, roles, instance profile, Security Groups, Internet Gateway, route tables, subnets y VPC en orden inverso de dependencias.
9. Revisar CloudWatch Log Group, alarmas y Budgets. Conservar el budget si la cuenta seguirá activa.

## Recursos que no se deben olvidar

- CloudFront debe estar deshabilitado antes de eliminarlo.
- Un bucket S3 debe estar vacío antes de borrarlo.
- RDS puede dejar snapshots, backups y storage facturables.
- Elastic IPs, NAT Gateways y VPC endpoints no pertenecen al diseño actual, pero deben revisarse antes de afirmar que la cuenta está limpia.
- La eliminación de un secret o parámetro puede impedir rollback y recuperación.

## Evidencia de cierre

Después del teardown, documentar qué se eliminó, snapshots conservados, recursos residuales y fecha de revisión de Billing. No declarar costo real cero hasta que Billing/Cost Explorer hayan actualizado sus datos.
