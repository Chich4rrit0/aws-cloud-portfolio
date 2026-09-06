\# ADR-002 — Región principal de AWS



\- Estado: Aceptado

\- Fecha: 2026-09-06



\## Contexto



El Proyecto 1 se desarrolla desde Chile y utiliza AWS Free Plan con créditos limitados. Debemos equilibrar latencia, disponibilidad de servicios, documentación y consumo de créditos.



\## Decisión



La región principal del Proyecto 1 será `us-east-1` (US East, N. Virginia).



\## Razones



\- Amplia disponibilidad de servicios y características de AWS.

\- Costos generalmente más competitivos que regiones sudamericanas.

\- Amplio material técnico, ejemplos y compatibilidad para un portafolio AWS.

\- Adecuada para un entorno de aprendizaje y demostración.



\## Consecuencias



\- La latencia hacia usuarios ubicados en Chile será mayor que en `sa-east-1`.

\- Los comandos AWS del proyecto deberán indicar `us-east-1` de forma explícita cuando corresponda.

\- No se diseñarán componentes multi-región durante la primera versión.

