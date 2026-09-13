# Diseño Terraform — Network module

## Equivalencia

`terraform/modules/network` reproduce el CloudFormation Network stack: VPC /16, Internet Gateway, ruta pública por `0.0.0.0/0`, route table privada de base de datos y seis subredes distribuidas en dos AZ.

Las seis subredes `/24` se derivan de `vpc_cidr` mediante `cidrsubnet`, con los
índices 0, 1, 10, 11, 20 y 21. Así, el root `lab` con `10.20.0.0/16` conserva
el baseline `10.20.x.0/24`, mientras que E2E con `10.30.0.0/16` recibe
`10.30.x.0/24` sin copiar ni editar CIDRs fijos.

Las cuatro subredes Edge/App reciben IP pública al lanzar instancias, tal como el baseline de desarrollo sin NAT Gateway. Las dos subredes Database no tienen ruta pública ni asignación de IP pública.

## Controles

Las AZ se reciben como variables obligatorias porque sus etiquetas son específicas de cada cuenta AWS. El ejemplo local usa las AZ previamente verificadas para esta cuenta, pero cualquier despliegue debe confirmarlas antes de ejecutar un plan.

No se define NAT Gateway, Elastic IP, endpoint VPC, peering, Flow Logs ni recursos fuera del alcance. El módulo solo se validará estáticamente en esta fase; no se aplicará.
