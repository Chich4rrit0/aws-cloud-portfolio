# Controles de abuso y límites operativos — Project 02

## Riesgo y postura inicial

El redirect es público y la aplicación puede generar consumo por solicitud. El presupuesto existente alerta, pero no bloquea cargos ni responde en tiempo real. Por eso el diseño limita simultáneamente superficie, volumen y trabajo por solicitud.

| Capa | Control propuesto | Motivo |
| --- | --- | --- |
| API Gateway HTTP API | Throttling por stage: 5 solicitudes/segundo, burst 10. | Limita picos accidentales y pruebas abusivas de bajo volumen. |
| Lambda | Memoria 128 MiB, timeout 3 segundos y concurrencia reservada 2. | Acota tiempo de cómputo y evita que esta función consuma concurrencia sin límite. |
| Handler | Cuerpo máximo 4 KiB, URL máxima 2.048 caracteres y cinco intentos máximos ante colisión. | Evita trabajo o almacenamiento innecesario. |
| Autorización | JWT Cognito en mutaciones; no hay auto-registro público. | Reduce creación y eliminación no autorizadas. |
| DynamoDB | On-Demand, sin GSI ni streams inicialmente. | No se mantiene capacidad o componentes adicionales sin uso. |
| Logs | Retención de siete días; sin JWT ni URL completa. | Limita persistencia y exposición de datos de diagnóstico. |

No se agregará WAF en la primera versión: es una capa útil para una exposición pública mayor, pero añade costo y complejidad que no se justifican para la demostración inicial. Tampoco se habilitarán usage plans/API keys; no son el modelo de autorización de HTTP API para este caso.

## Autenticación administrativa

Se creará más adelante un Cognito User Pool con registro autónomo deshabilitado y un único usuario administrador de laboratorio. API Gateway validará JWT con issuer y audience del User Pool; Lambda usará el claim `sub` como identidad de propietario.

La contraseña del usuario se establecerá de forma interactiva o mediante un flujo seguro y nunca se añadirá a scripts, archivos `.env` versionados ni documentación. El acceso temporal de root sigue siendo solo para construir el laboratorio; no se incorporará a la aplicación.

## Respuesta ante consumo anómalo

1. Revisar Budget, Cost Explorer cuando los datos estén disponibles y métricas de API Gateway/Lambda.
2. Reducir el throttling o establecer concurrencia reservada en cero para detener invocaciones Lambda temporalmente.
3. Si persiste, eliminar API Gateway, Lambda, DynamoDB y Cognito siguiendo una checklist aprobada; exportar o borrar datos de prueba según corresponda.

Detener Lambda no elimina por sí solo las solicitudes ni los componentes persistentes, y los datos de facturación pueden tener retraso. La limpieza será una decisión explícita y destructiva, nunca automática.
