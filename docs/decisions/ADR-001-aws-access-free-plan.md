\# ADR-001 — Acceso AWS durante el Free Plan



\- Estado: Aceptado

\- Fecha: 2026-09-06



\## Contexto



La cuenta AWS utiliza Free Plan y conserva créditos promocionales. Habilitar AWS Organizations o IAM Identity Center actualizaría la cuenta a Paid Plan y afectaría esos créditos.



\## Decisión



Durante el bootstrap se utilizará `aws login` con una sesión temporal autenticada mediante la cuenta root protegida con MFA.



No se crearán access keys para root ni se guardarán credenciales permanentes en archivos, scripts o Git.



\## Consecuencias



\- El acceso CLI tiene privilegios root y requiere atención manual.

\- No se usarán automatizaciones desatendidas con este perfil.

\- Todos los comandos AWS indicarán explícitamente el perfil temporal.

\- Cuando las condiciones de la cuenta lo permitan, se migrará a una identidad con menor privilegio.

