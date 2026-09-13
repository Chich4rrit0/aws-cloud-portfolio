# Diseño de publicación ECR mediante GitHub OIDC

## Estado

Proveedor OIDC y rol IAM creados y verificados. El workflow manual de
publicación se prepara como el siguiente controlado; todavía no se ha publicado
ninguna imagen en ECR.

## Objetivo

Permitir que un workflow manual de GitHub Actions publique una imagen con una
etiqueta inmutable `sha-<commit>` en el repositorio privado
`portfolio-p04-task-manager`, sin guardar Access Keys de AWS en GitHub ni en
el repositorio.

## Recursos IAM propuestos

| Recurso | Nombre o valor | Alcance |
|---|---|---|
| Proveedor IAM OIDC | `https://token.actions.githubusercontent.com` | Una vez por cuenta AWS; audiencia `sts.amazonaws.com`. |
| Rol IAM | `portfolio-p04-github-actions-ecr-publisher` | Solo publicación al repositorio ECR del Proyecto 4. |
| Confianza | Sujeto inmutable del repositorio y `main` | Solo el repositorio y rama principal indicados. |

El ARN de la cuenta no se fija en archivos versionados: el script de creación
lo obtendrá en tiempo de ejecución mediante STS. Los identificadores públicos
e inmutables de GitHub del propietario y repositorio sí se usan para impedir
que un cambio futuro de nombre o namespace amplíe la confianza.

## Política de confianza propuesta

El proveedor federado es el ARN de OIDC de la cuenta y el rol acepta únicamente
`sts:AssumeRoleWithWebIdentity`. Las condiciones aplicadas son:

```json
{
  "StringEquals": {
    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
    "token.actions.githubusercontent.com:sub": "repo:Chich4rrit0@OWNER-ID/aws-cloud-portfolio@REPOSITORY-ID:ref:refs/heads/main",
    "token.actions.githubusercontent.com:repository_owner_id": "OWNER-ID",
    "token.actions.githubusercontent.com:repository_id": "REPOSITORY-ID",
    "token.actions.githubusercontent.com:ref": "refs/heads/main"
  }
}
```

Esto excluye ramas, repositorios y organizaciones diferentes. No se usa ningún
comodín en el sujeto. El script contiene los IDs públicos reales obtenidos del
repositorio, pero este documento conserva marcadores para no convertirlos en
datos copiados manualmente.

## Permisos de publicación propuestos

El rol tendrá una política en línea, no una política administrada amplia.
Permitirá sobre el ARN del repositorio objetivo únicamente:

- `ecr:BatchCheckLayerAvailability`
- `ecr:BatchGetImage`
- `ecr:CompleteLayerUpload`
- `ecr:InitiateLayerUpload`
- `ecr:PutImage`
- `ecr:UploadLayerPart`

Además, `ecr:GetAuthorizationToken` debe tener recurso `*` porque ECR no
permite restringir esa acción a un ARN de repositorio. No se concederán
permisos para borrar imágenes o repositorios, administrar políticas de ECR,
crear recursos, ni acceder a ECS.

## Workflow posterior

El workflow separado `project-04-publish-ecr.yml` se activa solo mediante
`workflow_dispatch`. Usa `id-token: write` y `contents: read`, intercambia el
token OIDC por credenciales temporales y publica solo `sha-${{ github.sha }}`.
El ARN del rol se entrega mediante la variable de repositorio de GitHub
`AWS_P04_ECR_PUBLISH_ROLE_ARN`, no como secreto ni valor embebido en código.

Crear o publicar el workflow no publica una imagen por sí mismo. La primera
ejecución manual se planificará y aprobará separadamente porque almacenará una
imagen en ECR.

## Cost Check

- El proveedor OIDC y el rol IAM no son recursos de cómputo ni almacenan
  imágenes; no se espera un cargo directo por crearlos.
- La publicación posterior sí puede generar almacenamiento ECR y solicitudes
  asociadas. El repositorio está vacío ahora.
- La lifecycle policy limita crecimiento, pero no sustituye una revisión de
  facturación ni el presupuesto existente.

## Fuentes

- [GitHub: configuración OIDC en AWS](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws)
- [AWS IAM: rol para proveedor GitHub OIDC](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html)
- [AWS ECR: permisos mínimos para publicar una imagen](https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-push-iam.html)
