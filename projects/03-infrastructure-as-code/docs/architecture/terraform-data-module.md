# Diseño Terraform — Data module

## Equivalencia

`terraform/modules/data` define el DB subnet group y RDS PostgreSQL de desarrollo: `db.t3.micro`, 20 GiB `gp3` cifrados, Single-AZ, red privada, backup de un día y Security Group exclusivo de Database.

## Secretos y lifecycle

La contraseña maestra es una variable `sensitive` obligatoria sin valor por defecto y no aparece en el archivo de ejemplo, outputs ni documentación. La configuración mantiene `skip_final_snapshot = true` y deletion protection desactivada para el laboratorio; no es una política adecuada para producción.

## Guardrails

El engine version `18.3` expresa el baseline del Proyecto 1, pero se debe confirmar su disponibilidad regional antes de cualquier plan. RDS es un recurso con costo recurrente y la capa no se desplegará sin un Cost Check y una decisión explícita de cleanup.
