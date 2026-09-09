# Contrato HTTP — Project 02

Base path: la URL entregada por API Gateway. Todas las respuestas usan JSON excepto el redirect, que solo devuelve la cabecera `Location`.

## Rutas

| Método y ruta | Autorización | Respuesta exitosa |
| --- | --- | --- |
| `GET /r/{code}` | Pública | `302 Found` con `Location` hacia la URL guardada. |
| `POST /urls` | JWT Cognito | `201 Created` con el enlace creado. |
| `DELETE /urls/{code}` | JWT Cognito | `204 No Content`. |

## `POST /urls`

Solicitud:

```json
{
  "url": "https://example.com/article",
  "expiresAt": 1798761600
}
```

`expiresAt` es opcional y representa Epoch seconds UTC. `url` debe ser absoluta, usar `https`, no contener credenciales y no superar 2.048 caracteres.

Respuesta `201`:

```json
{
  "shortCode": "aB3dE9kL",
  "shortUrlPath": "/r/aB3dE9kL",
  "createdAt": "2026-09-09T00:00:00.000Z",
  "expiresAt": 1798761600
}
```

## Errores normalizados

| Estado | Código | Cuándo |
| --- | --- | --- |
| `400` | `VALIDATION_ERROR` | JSON inválido, URL inválida, código inválido o TTL fuera de rango. |
| `401` | `UNAUTHORIZED` | Falta JWT o es inválido; normalmente lo rechaza API Gateway. |
| `404` | `NOT_FOUND` | Código inexistente. |
| `410` | `EXPIRED` | El enlace ya venció. |
| `429` | `RATE_LIMITED` | Se superó el límite de API Gateway o Lambda. |
| `500` | `INTERNAL_ERROR` | Fallo inesperado; sin detalles internos en la respuesta. |

El contrato no revelará si un código pertenece a otra persona durante un `DELETE`: devolverá `404` también en ese caso, para no confirmar su existencia. El log estructurado conservará únicamente el tipo de resultado.
