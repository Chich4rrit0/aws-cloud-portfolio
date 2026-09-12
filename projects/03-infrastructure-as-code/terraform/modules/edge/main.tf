resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${var.project_prefix}-frontend-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_ssm_parameter" "origin_header" {
  name  = var.origin_header_parameter_name
  type  = "SecureString"
  value = var.origin_header_value

  tags = {
    Name        = "${var.project_prefix}-cloudfront-origin-header"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  default_root_object  = "index.html"
  price_class          = "PriceClass_100"

  origin {
    domain_name              = "${var.frontend_bucket_name}.s3.amazonaws.com"
    origin_id                = "frontend-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "application-alb"
    custom_header {
      name  = "X-Portfolio-Origin-Verify"
      value = var.origin_header_value
    }
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }
  default_cache_behavior {
    target_origin_id = "frontend-s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }
  ordered_cache_behavior {
    path_pattern = "/api/*"
    target_origin_id = "application-alb"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods = ["GET", "HEAD"]
    min_ttl = 0
    default_ttl = 0
    max_ttl = 0
    forwarded_values {
      query_string = true
      headers = ["*"]
      cookies { forward = "all" }
    }
  }
  ordered_cache_behavior {
    path_pattern = "/health"
    target_origin_id = "application-alb"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    min_ttl = 0
    default_ttl = 0
    max_ttl = 0
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }
  restrictions {
    geo_restriction { restriction_type = "none" }
  }
  viewer_certificate { cloudfront_default_certificate = true }
}

data "aws_iam_policy_document" "frontend_read" {
  statement {
    actions = ["s3:GetObject"]
    resources = ["${var.frontend_bucket_arn}/*"]
    principals {
      type = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test = "StringEquals"
      variable = "AWS:SourceArn"
      values = [aws_cloudfront_distribution.this.arn]
    }
  }
}
resource "aws_s3_bucket_policy" "frontend" {
  bucket = var.frontend_bucket_name
  policy = data.aws_iam_policy_document.frontend_read.json
}
resource "aws_lb_listener_rule" "origin_guard" {
  listener_arn = var.listener_arn
  priority     = 10
  action {
    type = "forward"
    target_group_arn = var.target_group_arn
  }
  condition {
    http_header {
      http_header_name = "X-Portfolio-Origin-Verify"
      values           = [var.origin_header_value]
    }
  }
}
