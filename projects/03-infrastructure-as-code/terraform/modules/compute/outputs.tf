output "load_balancer_dns_name" { value = aws_lb.application.dns_name }
output "load_balancer_arn" { value = aws_lb.application.arn }
output "load_balancer_full_name" { value = aws_lb.application.arn_suffix }
output "listener_arn" { value = aws_lb_listener.http.arn }
output "target_group_arn" { value = aws_lb_target_group.application.arn }
output "target_group_full_name" { value = aws_lb_target_group.application.arn_suffix }
output "autoscaling_group_name" { value = aws_autoscaling_group.application.name }
output "application_log_group_name" { value = aws_cloudwatch_log_group.application.name }
