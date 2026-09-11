# Diseño Terraform — Network module

## Equivalencia

`terraform/modules/network` reproduce el CloudFormation Network stack: VPC `10.20.0.0/16`, Internet Gateway, ruta pública por `0.0.0.0/0`, route table privada de base de datos y seis subredes distribuidas en dos AZ.

Las cuatro subredes Edge/App reciben IP pública al lanzar instancias, tal como el baseline de desarrollo sin NAT Gateway. Las dos subredes Database no tienen ruta pública ni asignación de IP pública.

## Controles

Las AZ se reciben como variables obligatorias porque sus etiquetas son específicas de cada cuenta AWS. El ejemplo local usa las AZ previamente verificadas para esta cuenta, pero cualquier despliegue debe confirmarlas antes de ejecutar un plan.

No se define NAT Gateway, Elastic IP, endpoint VPC, peering, Flow Logs ni recursos fuera del alcance. El módulo solo se validará estáticamente en esta fase; no se aplicará.
