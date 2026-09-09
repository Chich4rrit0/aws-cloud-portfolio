# ADR-014 — Demostración controlada de Auto Scaling

- Estado: Aceptado
- Fecha: 2026-09-08

## Contexto

Project 01 debe demostrar un scale-out real causado por carga, sin mantener una segunda instancia como costo permanente ni introducir una herramienta de generación de carga adicional.

## Decisión

La demostración crea temporalmente una política target tracking basada en `ASGAverageCPUUtilization` con objetivo de 30%. La carga se genera mediante dos procesos de CPU en la instancia actual, iniciados con Session Manager y limitados automáticamente a quince minutos. El objetivo se redujo desde 50% después de verificar que la carga controlada alcanzaba aproximadamente 42%, insuficiente para activar la primera versión de la política.

El ASG conserva `min=1`, `desired=1` y `max=2`. El éxito exige dos instancias saludables y dos targets saludables detrás del ALB. Después se detiene la carga y se espera hasta quince minutos por el scale-in automático. La política temporal se elimina al finalizar.

## Consecuencias

- La prueba puede crear una segunda `t3.micro` durante un período acotado.
- Una instancia T3 en modo Unlimited puede generar cargos de créditos CPU si mantiene uso sobre su baseline. La carga está limitada para reducir ese riesgo, pero el monto real depende del uso y créditos disponibles.
- Target tracking crea alarmas CloudWatch administradas por AWS durante la demostración; desaparecen junto con la política.
- Si el scale-in no ocurre dentro del límite, el proceso no termina instancias por sí mismo. Se requiere aprobación explícita antes de una reducción forzada.

## Resultado de la ejecución

La primera ejecución con objetivo de 50% no escaló: la carga controlada alcanzó aproximadamente 42% de CPU. Con el objetivo temporal ajustado a 30%, el ASG escaló de una a dos instancias y ambos targets del ALB quedaron saludables.

Después de detener la carga, AWS no redujo automáticamente dentro de la ventana de quince minutos. La política temporal y sus alarmas administradas se eliminaron para evitar nuevos scale-outs. Con aprobación explícita, la capacidad deseada se redujo de dos a una y se verificó que permanecían una instancia y un target saludables.
