# Modelo de datos — Project 02

## Tabla propuesta

Una única tabla DynamoDB On-Demand, con nombre aún pendiente de definir al crear la infraestructura. No tendrá índices secundarios en la primera versión: el producto solo necesita resolver un código y verificar la propiedad al eliminarlo.

| Atributo | Tipo DynamoDB | Regla |
| --- | --- | --- |
| `shortCode` | String (partition key) | Ocho caracteres Base62 (`A-Z`, `a-z`, `0-9`); único. |
| `originalUrl` | String | URL absoluta `https://`, máximo 2.048 caracteres. |
| `ownerSub` | String | Claim `sub` del JWT; nunca llega desde el cliente. |
| `createdAt` | String | UTC ISO-8601 generado por Lambda. |
| `expiresAt` | Number, opcional | Epoch seconds; si existe, TTL de DynamoDB y vencimiento lógico. |

No se persistirán JWT, cabeceras `Authorization`, contraseñas, IPs ni analítica de clics en esta versión.

## Operaciones y consistencia

| Caso | Operación | Protección |
| --- | --- | --- |
| Crear | `PutItem` | `attribute_not_exists(shortCode)` evita sobrescribir un enlace por colisión. Lambda intenta otro código con un máximo de cinco intentos. |
| Resolver | `GetItem` | Lectura por clave; `404` si no existe y `410` si venció. |
| Eliminar | `DeleteItem` | `ownerSub = :callerSub` como condición; un tercero no puede borrar el enlace. |

El TTL de DynamoDB elimina elementos de forma eventual. Por ello Lambda verificará `expiresAt` en cada `GET` y devolverá `410 Gone` desde el instante de vencimiento, aun antes de la limpieza física.

## Caducidad propuesta

`expiresAt` es opcional. Si se entrega, debe estar entre un minuto y 365 días en el futuro. No habrá caducidad por defecto: un enlace sin `expiresAt` no expira automáticamente. Esta elección permite demostrar TTL sin convertir la eliminación eventual de DynamoDB en un comportamiento visible e impredecible.

## Fuera de alcance

- Listar enlaces por usuario requeriría un GSI por `ownerSub`; se aplaza hasta que exista una necesidad de producto real.
- Estadísticas de visitas requerirían otro patrón de escritura y una evaluación de costos.
- Códigos elegidos por el usuario, alias y dominios propios no pertenecen a la primera versión.
