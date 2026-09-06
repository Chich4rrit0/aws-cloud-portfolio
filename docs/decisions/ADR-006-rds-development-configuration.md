\# ADR-006 — Configuración RDS PostgreSQL de desarrollo



\- Estado: Aceptado

\- Fecha: 2026-09-06



\## Contexto



El Task Manager requiere PostgreSQL, pero la cuenta usa AWS Free Plan y créditos limitados. Se necesita una base privada, funcional y fácil de eliminar cuando termine una demostración.



\## Decisión



La primera base de datos usará:



\- Amazon RDS for PostgreSQL.

\- Clase `db.t3.micro`.

\- Despliegue Single-AZ.

\- 20 GiB de almacenamiento General Purpose SSD.

\- DB subnet group con las dos subredes privadas de base de datos.

\- Acceso público desactivado.

\- Security Group que permita PostgreSQL (`5432`) solo desde el Security Group de la aplicación.

\- Backups automatizados con retención de un día.

\- Deletion protection desactivada para desarrollo.



\## Consecuencias



\- No existe failover automático; Multi-AZ queda como mejora productiva.

\- El almacenamiento y backups continúan consumiendo uso aunque la instancia esté detenida.

\- No se conservará una snapshot final por defecto al eliminar la base de datos.

\- Antes de borrar RDS con datos valiosos, se realizará una exportación o se solicitará una snapshot de forma explícita.

