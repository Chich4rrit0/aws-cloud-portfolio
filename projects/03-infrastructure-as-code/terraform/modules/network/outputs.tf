output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_edge_subnet_ids" {
  value = [aws_subnet.this["edge_a"].id, aws_subnet.this["edge_b"].id]
}

output "public_application_subnet_ids" {
  value = [aws_subnet.this["app_a"].id, aws_subnet.this["app_b"].id]
}

output "private_database_subnet_ids" {
  value = [aws_subnet.this["database_a"].id, aws_subnet.this["database_b"].id]
}
