# Cost Check — Fase 00: base local

## Recursos creados

Ninguno en AWS. Esta fase contiene solo estructura y documentación local.

## Recursos con costo

Ninguno creado por el Proyecto 5.

## Riesgos a vigilar en fases posteriores

- alarmas CloudWatch mientras existan;
- almacenamiento/retención de logs;
- Container Insights, métricas personalizadas, synthetics y notificaciones;
- recursos fuente ya activos, especialmente ALB y Fargate del Proyecto 4.

## Control

Antes de desplegar se inventariarán las fuentes, se definirá el mínimo de alarmas y se documentará su estrategia de eliminación. El budget es una alerta con posible retraso de Billing, no un interruptor automático.
