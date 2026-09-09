# Cost Check — Fase 14: demostración controlada de Auto Scaling

## Recursos temporales

- Una política target tracking de Auto Scaling.
- Alarmas CloudWatch administradas por AWS para esa política.
- Hasta una segunda EC2 `t3.micro`, dentro del máximo existente de dos.

## Límite operativo

- Dos procesos CPU se detienen automáticamente después de quince minutos.
- El ASG nunca puede superar dos instancias.
- Después de verificar el scale-out se detiene la carga y se espera por scale-in automático.
- La política y sus alarmas administradas se eliminan al terminar la prueba.

## Costos y riesgos

- La segunda instancia añade costo por los minutos que permanezca activa.
- El modo T3 Unlimited puede generar cargos por créditos CPU cuando el uso sostenido supera baseline; el costo real debe revisarse en Billing, no inferirse desde esta estimación.
- Si el ASG no reduce capacidad automáticamente, no se fuerza la terminación. Se detiene el avance y se solicita autorización para la acción destructiva.

## Resultado y limpieza

- La demostración logró scale-out real de una a dos instancias con dos targets ALB saludables.
- El objetivo de CPU se ajustó de 50% a 30% después de comprobar que la carga controlada alcanzaba aproximadamente 42%.
- La carga fue detenida y la política temporal, con sus alarmas administradas, fue eliminada.
- El scale-in automático no se completó dentro de la ventana. Se solicitó y obtuvo aprobación explícita para reducir `desired` de dos a una.
- Estado final validado: `min=1`, `desired=1`, `max=2`, una instancia saludable y un target saludable.
