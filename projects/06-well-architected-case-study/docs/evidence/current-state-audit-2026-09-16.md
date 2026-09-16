# Resultado de auditoría actual — P1

**Fecha:** 2026-09-16

## Método

Se ejecutó `Get-Project06CurrentState.ps1` con una sesión AWS válida. La
consulta fue exclusivamente de lectura y omitió endpoints, IDs, dominios,
cuentas, secretos y cabeceras privadas.

## Estado observado

| Componente | Resultado |
| --- | --- |
| VPC P1 | Una VPC en estado `available`. |
| ASG P1 | Presente; mínimo 1, deseado 1, máximo 2; una instancia `InService`. |
| RDS P1 | Presente y `available`; Single-AZ, un día de backup, deletion protection desactivada y no pública. |
| ALB P1 | Presente, `active` e internet-facing. |
| CloudFront P1 | Presente, habilitado y `Deployed`. |
| Alarma P1 | Presente, `OK` y sin acciones configuradas. |
| Log group P1 | Presente, con retención de siete días. |

## Interpretación

La fotografía actual confirma que el workload de demostración P1 sigue
desplegado y conserva los trade-offs de confiabilidad, seguridad y costo
descritos en el assessment. No prueba la disponibilidad histórica, un restore
de RDS, el rendimiento bajo carga ni el costo acumulado.

## Límites respetados

- No se generó tráfico ni se ejecutaron pruebas funcionales.
- No se modificaron P1–P5, IAM, datos, capacidad ni configuración de alarmas.
- Esta evidencia no contiene información sensible ni identificadores de cuenta.
