\# AWS Cloud Portfolio



Portafolio práctico de arquitectura cloud en AWS, construido de forma incremental con foco en seguridad, costos, automatización, observabilidad e infraestructura reproducible.



\## Proyecto actual



\*\*01 — Web Task Manager\*\*



Una aplicación web pequeña para demostrar una arquitectura AWS profesional. La prioridad no es la complejidad funcional, sino las decisiones de arquitectura, seguridad, despliegue, operación y documentación.



\## Principios de trabajo



1\. Entender antes de implementar.

2\. Evaluar costos antes de crear recursos.

3\. Aplicar mínimo privilegio y no guardar secretos en Git.

4\. Verificar cada cambio.

5\. Documentar decisiones relevantes.

6\. Realizar commits pequeños y descriptivos.



\## Estado actual



\- Fase 0: preparación del entorno local.

\- AWS CLI configurada con credenciales temporales.

\- MFA habilitado para la cuenta root.

\- Presupuesto de alerta temprana configurado.

\- No existen recursos de infraestructura de la aplicación.



\## Estructura



```text

docs/       Arquitectura, ADRs, capturas y controles de costo

projects/   Aplicaciones y su infraestructura

scripts/    Automatización PowerShell y AWS CLI

shared/     Componentes reutilizables

