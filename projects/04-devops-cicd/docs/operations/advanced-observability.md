# Operación — Observabilidad avanzada temporal

El dashboard `portfolio-p04-ecs-lab` contiene métricas AWS nativas para:

- CPU y memoria del servicio ECS;
- solicitudes, latencia, 5XX del ALB y targets no saludables.

El stack también crea las alarmas sin acciones automáticas:

- `portfolio-p04-ecs-lab-unhealthy-target` para un target ALB no saludable;
- `portfolio-p04-ecs-lab-high-cpu` para CPU promedio mayor al 80% durante dos
  periodos de un minuto.

Las alarmas comienzan en `INSUFFICIENT_DATA` hasta que AWS reciba métricas.
No hay SNS, SMS, automatización de recuperación, Container Insights ni
métricas personalizadas. Al eliminar el stack, el dashboard y las alarmas se
eliminan junto con el laboratorio.
