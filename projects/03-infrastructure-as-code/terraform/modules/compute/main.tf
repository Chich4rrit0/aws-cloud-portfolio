data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/aws-cloud-portfolio/project-03/application"
  retention_in_days = 7
}

resource "aws_iam_role_policy" "runtime_additional" {
  name = "ReadArtifactAndWriteApplicationLogs"
  role = var.ec2_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${var.artifact_bucket_arn}/releases/*"
      },
      {
        Effect = "Allow"
        Action = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = [aws_cloudwatch_log_group.application.arn, "${aws_cloudwatch_log_group.application.arn}:*"]
      }
    ]
  })
}

resource "aws_lb_target_group" "application" {
  name        = "${var.project_prefix}-app-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    port                = "3000"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb" "application" {
  name               = "${var.project_prefix}-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.load_balancer_security_group_id]
  subnets            = var.public_edge_subnet_ids
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Direct origin access denied"
      status_code  = "403"
    }
  }
}

# Keep the health endpoint associated with the target group before Edge is
# deployed. The ALB security group still restricts inbound requests to the
# CloudFront managed prefix list; Edge later adds the stricter origin header
# rule with a higher precedence.
resource "aws_lb_listener_rule" "health" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application.arn
  }

  condition {
    path_pattern {
      values = ["/health"]
    }
  }
}

resource "aws_launch_template" "application" {
  name_prefix   = "${var.project_prefix}-app-"
  image_id      = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type = "t3.micro"

  iam_instance_profile { name = var.ec2_instance_profile_name }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.application_security_group_id]
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      encrypted             = true
      volume_size           = 8
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  user_data = base64encode(<<-EOT
    #!/bin/bash
    set -euo pipefail
    dnf install -y nodejs20 unzip amazon-cloudwatch-agent
    useradd --system --shell /sbin/nologin taskmanager || true
    mkdir -p /opt/task-manager /var/log/taskmanager
    touch /var/log/taskmanager/bootstrap.log /var/log/taskmanager/application.log
    chown -R taskmanager:taskmanager /var/log/taskmanager
    exec >>/var/log/taskmanager/bootstrap.log 2>&1
    aws s3 cp s3://${var.artifact_bucket_name}/${var.artifact_key} /tmp/release.zip
    unzip -q /tmp/release.zip -d /opt/task-manager
    cd /opt/task-manager/app && npm ci --omit=dev
    chown -R taskmanager:taskmanager /opt/task-manager
    curl -fsSL https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem \
      -o /etc/pki/ca-trust/source/anchors/rds-global-bundle.pem
    update-ca-trust extract
    cat >/opt/task-manager/start.sh <<'SCRIPT'
    #!/bin/bash
    set -euo pipefail
    export DB_PASSWORD="$(aws ssm get-parameter --name '${var.application_database_password_parameter_name}' --with-decryption --query 'Parameter.Value' --output text)"
    exec /usr/bin/node /opt/task-manager/app/src/server.js
    SCRIPT
    chmod 0750 /opt/task-manager/start.sh
    chown taskmanager:taskmanager /opt/task-manager/start.sh
    cat >/etc/systemd/system/taskmanager.service <<'UNIT'
    [Unit]
    Description=Task Manager API
    After=network-online.target
    Wants=network-online.target

    [Service]
    Type=simple
    User=taskmanager
    Group=taskmanager
    WorkingDirectory=/opt/task-manager/app
    Environment=PORT=3000
    Environment=DB_HOST=${var.database_endpoint_address}
    Environment=DB_PORT=5432
    Environment=DB_NAME=taskmanager
    Environment=DB_USER=taskmanager_app
    Environment=DB_SSL=true
    Environment=DB_SSL_CA_PATH=/etc/pki/ca-trust/source/anchors/rds-global-bundle.pem
    ExecStart=/opt/task-manager/start.sh
    StandardOutput=append:/var/log/taskmanager/application.log
    StandardError=append:/var/log/taskmanager/application.log
    Restart=on-failure
    RestartSec=5
    NoNewPrivileges=true
    PrivateTmp=true

    [Install]
    WantedBy=multi-user.target
    UNIT
    cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'JSON'
    {
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {"file_path":"/var/log/taskmanager/application.log","log_group_name":"${aws_cloudwatch_log_group.application.name}","log_stream_name":"{hostname}/application"},
              {"file_path":"/var/log/taskmanager/bootstrap.log","log_group_name":"${aws_cloudwatch_log_group.application.name}","log_stream_name":"{hostname}/bootstrap"}
            ]
          }
        }
      }
    }
    JSON
    systemctl daemon-reload
    systemctl enable --now taskmanager
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
  EOT
  )

  depends_on = [aws_iam_role_policy.runtime_additional]
}

resource "aws_autoscaling_group" "application" {
  name                      = "${var.project_prefix}-app-asg"
  min_size                  = 1
  desired_capacity          = 1
  max_size                  = 2
  vpc_zone_identifier       = var.public_application_subnet_ids
  target_group_arns         = [aws_lb_target_group.application.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.application.id
    version = "$Latest"
  }

  depends_on = [aws_lb_listener_rule.health]
}
