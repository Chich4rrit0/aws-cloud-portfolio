locals {
  subnets = {
    edge_a = {
      cidr        = "10.20.0.0/24"
      az          = var.availability_zones[0]
      public      = true
      tier        = "edge"
      name_suffix = "public-edge-a"
    }
    edge_b = {
      cidr        = "10.20.1.0/24"
      az          = var.availability_zones[1]
      public      = true
      tier        = "edge"
      name_suffix = "public-edge-b"
    }
    app_a = {
      cidr        = "10.20.10.0/24"
      az          = var.availability_zones[0]
      public      = true
      tier        = "app"
      name_suffix = "public-app-a"
    }
    app_b = {
      cidr        = "10.20.11.0/24"
      az          = var.availability_zones[1]
      public      = true
      tier        = "app"
      name_suffix = "public-app-b"
    }
    database_a = {
      cidr        = "10.20.20.0/24"
      az          = var.availability_zones[0]
      public      = false
      tier        = "database"
      name_suffix = "private-db-a"
    }
    database_b = {
      cidr        = "10.20.21.0/24"
      az          = var.availability_zones[1]
      public      = false
      tier        = "database"
      name_suffix = "private-db-b"
    }
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_prefix}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project_prefix}-public-rt"
  }
}

resource "aws_route_table" "private_database" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_prefix}-private-db-rt"
  }
}

resource "aws_subnet" "this" {
  for_each = local.subnets

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = each.value.public

  tags = {
    Name = "${var.project_prefix}-${each.value.name_suffix}"
    Tier = each.value.tier
  }
}

resource "aws_route_table_association" "public" {
  for_each = { for name, subnet in local.subnets : name => subnet if subnet.public }

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_database" {
  for_each = { for name, subnet in local.subnets : name => subnet if !subnet.public }

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.private_database.id
}
