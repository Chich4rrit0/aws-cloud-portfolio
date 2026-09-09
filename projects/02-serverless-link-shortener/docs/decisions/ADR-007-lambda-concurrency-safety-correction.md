# ADR-007 — Pausa de Lambda por cuota de concurrencia

- Estado: Aceptado
- Fecha: 2026-09-09
- Reemplaza la reserva positiva propuesta en ADR-005 para la fase previa a pruebas.

## Contexto

El diseño propuso reservar dos ejecuciones Lambda para limitar consumo. Al aplicarlo, AWS rechazó la configuración porque la cuota de la cuenta debe mantener concurrencia sin reservar y no permite una reserva positiva con el límite actual.

## Decisión

Configurar concurrencia reservada `0` en la función mientras no exista endpoint público ni pruebas autorizadas. No solicitar aumento de cuota. Al habilitar pruebas, quitar el límite mediante una acción aprobada y aplicar throttling de API Gateway como límite de entrada.

## Consecuencias

La función no puede invocarse accidentalmente y no incurre en duración de cómputo mientras está pausada. A cambio, no es posible probarla hasta retirar explícitamente el límite. Esta decisión evita ampliar la cuota de la cuenta solo para una demostración.
