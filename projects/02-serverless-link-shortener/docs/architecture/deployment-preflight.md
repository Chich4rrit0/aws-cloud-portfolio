# Preflight de despliegue — Project 02

## Objetivo

Convertir el código local probado en una API serverless mínima, sin modificar el Proyecto 1 ni añadir infraestructura de red. Este documento es un plan; **no autoriza la creación de recursos**.

## Cambio de runtime

La máquina local conserva Node.js 20 para desarrollo y pruebas. El runtime propuesto para Lambda es `nodejs22.x` sobre Amazon Linux 2023, porque el runtime `nodejs20.x` figura como deprecado en la documentación vigente de Lambda. El código y las pruebas no utilizan características exclusivas de Node 20, por lo que son compatibles con Node 22.

Fuente: [AWS Lambda runtimes](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html).

## Recursos propuestos

| Orden | Recurso | Configuración propuesta | Motivo | Costo potencial |
| --- | --- | --- | --- | --- |
| 1 | CloudWatch Log Group | `/aws/lambda/portfolio-p02-link-shortener`, retención 7 días. | Controlar retención desde el inicio. | Ingesta y almacenamiento de logs. |
| 2 | DynamoDB table | On-Demand; PK `shortCode` (String); TTL `expiresAt`; PITR, streams y GSI desactivados. | Persistencia mínima sin capacidad aprovisionada. | Solicitudes, almacenamiento y operaciones opcionales. |
| 3 | IAM role Lambda | Trust solo para `lambda.amazonaws.com`; logs del grupo anterior y `GetItem`/`PutItem`/`DeleteItem` sobre la tabla. | Mínimo privilegio. | Sin cargo directo esperado. |
| 4 | Lambda | `portfolio-p02-link-shortener`; `nodejs22.x`; `arm64`; 128 MiB; timeout 3 s; concurrencia reservada 2; variable `LINKS_TABLE_NAME`. | Ejecutar el handler con un límite de consumo. | Invocaciones y duración. |
| 5 | Cognito User Pool + app client | Registro autónomo deshabilitado; username; app client sin secreto para pruebas API; JWT issuer/audience. | Proteger mutaciones sin contraseñas en la aplicación. | Usuarios activos mensuales y funciones opcionales, según uso/precios vigentes. |
| 6 | API Gateway HTTP API | Stage `$default`; integración Lambda payload v2; rutas públicas y JWT; throttle 5 rps, burst 10. | Exponer una API HTTPS de bajo volumen. | Solicitudes y transferencia aplicable. |
| 7 | Lambda permission | Permitir invocación solo al API Gateway creado. | Evitar invocación pública directa de Lambda. | Sin cargo directo esperado. |

No se crearán VPC, NAT Gateway, EC2, ALB, RDS, S3, CloudFront, Route 53, WAF, Secrets Manager, KMS personalizado, dashboards, alarmas, GSI, streams ni API keys.

## Empaquetado local

El ZIP de Lambda incluirá `src/`, `node_modules/`, `package.json` y `package-lock.json`; el handler será `src/lambda-handler.handler`. Se usará el SDK versionado dentro del paquete, no la versión incluida en el runtime. Antes de subirlo se ejecutará `npm test` y se inspeccionará el contenido del ZIP para excluir pruebas, `.git`, credenciales y archivos locales.

## Autorización y secretos

- API Gateway aplicará el JWT authorizer solo a `POST /urls` y `DELETE /urls/{code}`.
- `GET /r/{code}` queda público intencionalmente y no expone owner ni URL en logs.
- Cognito no tendrá auto-registro; el usuario administrador de laboratorio se creará después de que el pool exista, mediante un comando explícito y sin guardar su contraseña en Git.
- La función no requiere Access Keys, contraseñas ni Secrets Manager: obtiene autorización del JWT y nombre de tabla desde configuración.

## Orden operativo propuesto

1. Preparar y verificar el ZIP local.
2. Crear Log Group y tabla DynamoDB; verificar TTL y tags.
3. Crear rol y política IAM; inspeccionar solo los permisos esperados.
4. Crear Lambda con concurrencia limitada; probar configuración, sin exponerla públicamente todavía.
5. Crear User Pool y app client; crear un usuario administrador de laboratorio por un paso separado.
6. Crear HTTP API, integración, authorizer, rutas y permiso acotado de Lambda.
7. Ejecutar pruebas API manuales; borrar el enlace de prueba y completar Cost Check.

Cada paso que cree recursos se detendrá para aprobación y verificación antes del siguiente.

## Limpieza planificada

La limpieza será destructiva y requerirá confirmación. El orden será: eliminar HTTP API; eliminar permiso de Lambda; eliminar Lambda; borrar app client, usuario de laboratorio y User Pool; borrar tabla DynamoDB y datos; borrar Log Group; eliminar política y rol IAM. Primero se revisarán recursos y datos reales para evitar afectar el Proyecto 1.

## Fuentes de precio

Los precios dependen de región, uso, Free Plan y créditos; este documento no establece un costo real. Antes de crear recursos se revisarán las páginas vigentes de [Lambda](https://aws.amazon.com/lambda/pricing/), [DynamoDB](https://aws.amazon.com/dynamodb/pricing/), [API Gateway](https://aws.amazon.com/api-gateway/pricing/) y Cognito, además de la calculadora si corresponde.
