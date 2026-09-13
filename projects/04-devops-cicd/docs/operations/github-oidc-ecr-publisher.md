# Diseño de publicación ECR mediante GitHub OIDC

## Estado

Diseñado y pendiente de autorización AWS. No existe todavía un proveedor OIDC,
un rol de publicación ni un workflow que pueda escribir en ECR.

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
| Confianza | `repo:Chich4rrit0/aws-cloud-portfolio:ref:refs/heads/main` | Solo el repositorio y rama principal indicados. |

El ARN de la cuenta no se fija en archivos versionados: el script de creación
lo obtendrá en tiempo de ejecución mediante STS.

## Política de confianza propuesta

El proveedor federado será el ARN de OIDC de la cuenta y el rol aceptará
únicamente `sts:AssumeRoleWithWebIdentity`. Las condiciones serán:

```json
{
  "StringEquals": {
    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
    "token.actions.githubusercontent.com:sub": "repo:Chich4rrit0/aws-cloud-portfolio:ref:refs/heads/main"
  }
}
```

Esto excluye ramas, repositorios y organizaciones diferentes. No se usará
ningún comodín en el sujeto.

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

Se creará un workflow separado, activado solo mediante `workflow_dispatch`.
Usará `id-token: write` y `contents: read`, intercambiará el token OIDC por
credenciales temporales y publicará solo `sha-${{ github.sha }}`. El ARN del
rol se entregará mediante una variable de repositorio de GitHub, no como
secreto ni valor embebido en código.

Crear el workflow no publicará nada por sí mismo. La primera ejecución manual
se planificará y aprobará separadamente porque almacenará una imagen en ECR.

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
