resource "aws_cloudwatch_metric_alarm" "no_healthy_targets" {
  alarm_name          = "${var.project_prefix}-${var.environment}-alb-no-healthy-targets"
  alarm_description   = "ALB has no healthy application targets for two consecutive minutes. Actions are intentionally disabled."
  actions_enabled     = false
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HealthyHostCount"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.load_balancer_full_name
    TargetGroup  = var.target_group_full_name
  }
}
