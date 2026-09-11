output "terraform_state_mode" {
  description = "State remains local until a separate remote-backend decision is approved."
  value       = "local-default-backend"
}

output "deployment_scope" {
  description = "Confirms that this root configuration is for the isolated Project 03 lab."
  value       = "project-03-${var.environment}-${var.aws_region}"
}
