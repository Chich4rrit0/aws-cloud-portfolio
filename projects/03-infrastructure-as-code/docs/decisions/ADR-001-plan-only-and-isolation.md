# ADR-001 — Modo plan e aislamiento del entorno existente

## Estado

Aceptada.

## Contexto

Los Proyectos 1 y 2 están cerrados y poseen recursos AWS existentes. Recrear de inmediato el stack completo del Proyecto 1 duplicaría componentes con costo recurrente, como ALB, RDS y cómputo. Importar o gestionar los recursos existentes desde una herramienta IaC también podría cambiar su estado y contradice el cierre de esos proyectos.

## Decisión

El Proyecto 3 construirá CloudFormation y Terraform completos, pero en esta etapa solo ejecutará validaciones estáticas, validación de templates y planes sin apply. Los nombres, parámetros y estado se diseñarán para un entorno aislado futuro. No se importarán recursos existentes ni se crearán recursos AWS.

Terraform usará inicialmente backend local ignorado por Git. Un backend remoto S3 será una decisión futura separada porque añade recursos, permisos y consideraciones de estado compartido.

## Alternativas consideradas

### Desplegar una copia completa ahora

Ventaja: evidencia inmediata de apply real.

Desventaja: duplica costos y recursos del Proyecto 1 mientras el baseline sigue disponible.

### Importar los recursos cerrados

Ventaja: no duplica infraestructura.

Desventaja: es una operación de alto riesgo para recursos ya cerrados, con complejidad de estado y potencial drift.

### Modo plan aislado

Ventaja: entrega IaC revisable, reproducible y validable sin costo de infraestructura ni cambios a entornos cerrados.

Desventaja: la evidencia de un `apply` se difiere a una fase futura explícitamente aprobada.

## Consecuencias

Las plantillas y módulos deben declarar todos los recursos del alcance, manejar dependencias y no contener secretos. Toda propuesta de `deploy`, `apply`, importación, backend remoto o cleanup requerirá un Cost Check y aprobación independiente.
