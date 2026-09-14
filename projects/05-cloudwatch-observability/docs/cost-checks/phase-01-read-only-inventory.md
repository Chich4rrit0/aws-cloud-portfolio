# Cost Check — Fase 01: inventario de solo lectura

## Recursos creados

Ninguno. Se ejecutaron consultas de inventario contra APIs existentes.

## Recursos con costo creados por P5

Ninguno.

## Hallazgo relevante

P2 conserva componentes serverless desplegados y P4 conserva temporalmente
Fargate/ALB. Estos no fueron creados, detenidos ni modificados por P5; sus
costos se mantienen bajo la responsabilidad y Cost Check de sus proyectos.

## Próximo control

Antes de crear recursos propios, limitar el baseline a señales nativas y
documentar las alarmas y retenciones que puedan generar costos recurrentes.
