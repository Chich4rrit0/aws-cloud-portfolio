data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "database_password_read" {
  statement {
    sid       = "ReadDatabasePasswordOnly"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.database_password_parameter_name}"]
  }
}

resource "aws_security_group" "load_balancer" {
  name        = "${var.project_prefix}-sg-alb"
  description = "Allow CloudFront HTTP traffic only and minimal egress to the application tier."
  vpc_id      = var.vpc_id
  ingress     = []
  egress      = []

  tags = { Name = "${var.project_prefix}-sg-alb" }
}

resource "aws_security_group" "application" {
  name        = "${var.project_prefix}-sg-app"
  description = "Allow application traffic only from the ALB and explicit outbound dependencies."
  vpc_id      = var.vpc_id
  ingress     = []
  egress      = []

  tags = { Name = "${var.project_prefix}-sg-app" }
}

resource "aws_security_group" "database" {
  name        = "${var.project_prefix}-sg-db"
  description = "Allow PostgreSQL only from the application security group."
  vpc_id      = var.vpc_id
  ingress     = []
  egress      = []

  tags = { Name = "${var.project_prefix}-sg-db" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_from_cloudfront" {
  security_group_id = aws_security_group.load_balancer.id
  description       = "HTTP from the regional CloudFront origin-facing prefix list."
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  prefix_list_id    = var.cloudfront_origin_prefix_list_id
}

resource "aws_vpc_security_group_egress_rule" "alb_to_application" {
  security_group_id            = aws_security_group.load_balancer.id
  description                  = "HTTP application port to App security group only."
  ip_protocol                  = "tcp"
  from_port                    = 3000
  to_port                      = 3000
  referenced_security_group_id = aws_security_group.application.id
}

resource "aws_vpc_security_group_ingress_rule" "application_from_alb" {
  security_group_id            = aws_security_group.application.id
  description                  = "Application port from ALB security group only."
  ip_protocol                  = "tcp"
  from_port                    = 3000
  to_port                      = 3000
  referenced_security_group_id = aws_security_group.load_balancer.id
}

resource "aws_vpc_security_group_egress_rule" "application_to_database" {
  security_group_id            = aws_security_group.application.id
  description                  = "PostgreSQL to Database security group only."
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.database.id
}

resource "aws_vpc_security_group_egress_rule" "application_http" {
  security_group_id = aws_security_group.application.id
  description       = "HTTP egress required by the no-NAT development topology."
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "application_https" {
  security_group_id = aws_security_group.application.id
  description       = "HTTPS egress required by the no-NAT development topology."
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "database_from_application" {
  security_group_id            = aws_security_group.database.id
  description                  = "PostgreSQL from the application security group only."
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.application.id
}

resource "aws_iam_role" "ec2_runtime" {
  name               = "${var.project_prefix}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ec2_runtime_ssm" {
  role       = aws_iam_role.ec2_runtime.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "database_password_read" {
  name   = "ReadDatabasePasswordOnly"
  role   = aws_iam_role.ec2_runtime.name
  policy = data.aws_iam_policy_document.database_password_read.json
}

resource "aws_iam_instance_profile" "ec2_runtime" {
  name = "${var.project_prefix}-ec2-profile"
  role = aws_iam_role.ec2_runtime.name
}
