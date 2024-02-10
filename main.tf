terraform {
  required_version = ">= 1.3.7"

  required_providers {
    aws = {
      configuration_aliases = [aws.east]
    }
  }
}

locals {
  lambdas = var.single_page_app == null ? {} : {
    spa_origin_request = {
      event_type = "origin-request"
      lambda_arn = module.single_page_lambda.0.version_arn
    }

    spa_origin_response = {
      event_type = "origin-response"
      lambda_arn = module.single_page_lambda.0.version_arn
    }
  }
}

data "aws_acm_certificate" "cert" {
  provider = aws.east
  domain   = coalesce(var.certificate_domain, replace(var.domain, "/^[^.]+/", "*"))
}

module "single_page_lambda" {
  count              = var.single_page_app == null ? 0 : 1
  source             = "github.com/tfext/terraform-aws-lambda-function?ref=v1"
  name               = "${var.name}-single-page-app"
  runtime            = "nodejs20.x"
  entrypoint         = "index"
  log_retention_days = 1
  source_dir         = "${path.module}/single_page_lambda"

  providers = {
    aws = aws.east
  }
}

resource "aws_cloudfront_origin_access_control" "dist" {
  name                              = var.name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "dist" {
  enabled             = true
  wait_for_deployment = true
  aliases             = [var.domain]
  default_root_object = try(var.single_page_app.home_page, var.default_document, null)
  price_class         = "PriceClass_100"

  default_cache_behavior {
    allowed_methods        = ["HEAD", "GET"]
    cached_methods         = ["HEAD", "GET"]
    compress               = true
    target_origin_id       = "default"
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 900
    default_ttl            = 900
    max_ttl                = 900

    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = true
    }

    dynamic "lambda_function_association" {
      for_each = local.lambdas
      iterator = each
      content {
        event_type = each.value.event_type
        lambda_arn = each.value.lambda_arn
      }
    }
  }

  origin {
    origin_id                = "default"
    domain_name              = var.origin.s3.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.dist.id
    origin_path              = coalesce(var.origin.path, "/")
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.cert.arn
    ssl_support_method  = "sni-only"
  }
}
