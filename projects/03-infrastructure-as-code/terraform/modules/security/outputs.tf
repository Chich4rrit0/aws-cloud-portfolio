output "load_balancer_security_group_id" { value = aws_security_group.load_balancer.id }
output "application_security_group_id" { value = aws_security_group.application.id }
output "database_security_group_id" { value = aws_security_group.database.id }
output "ec2_role_arn" { value = aws_iam_role.ec2_runtime.arn }
output "ec2_role_name" { value = aws_iam_role.ec2_runtime.name }
output "ec2_instance_profile_name" { value = aws_iam_instance_profile.ec2_runtime.name }
