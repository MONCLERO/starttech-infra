
# ----- OAC CONFIG ----- #

# Allow CloudFront to securely access the private S3 bucket.
resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${var.project_name}-frontend-oac"
  description                       = "Secure access to the frontend S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ----- POLICIES ----- #

resource "aws_cloudfront_cache_policy" "api" {
  name        = "${var.project_name}-api-no-cache"
  comment     = "Disable caching for dynamic API responses"
  min_ttl     = 0
  default_ttl = 0
  max_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

resource "aws_cloudfront_origin_request_policy" "api" {
  name    = "${var.project_name}-api-origin-request"
  comment = "Forward API request headers, cookies and query strings"

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
    header_behavior = "allExcept"

    headers {
      items = ["Host"]
    }
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

# ----- CLOUDFRONT DIST ----- #

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  comment             = "${var.project_name} application distribution"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  # Frontend origin: private S3 bucket
  origin {
    domain_name              = var.frontend_bucket_regional_domain_name
    origin_id                = "S3-Frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  # Backend origin: Application Load Balancer
  origin {
    domain_name = var.backend_origin_domain_name
    origin_id   = "ALB-Backend"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default behavior: serve the React frontend.
  default_cache_behavior {
    target_origin_id       = "S3-Frontend"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # API behavior: send API requests to the backend.
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "ALB-Backend"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "DELETE",
      "GET",
      "HEAD",
      "OPTIONS",
      "PATCH",
      "POST",
      "PUT"
    ]

    cached_methods = ["GET", "HEAD"]

    # AWS managed CachingDisabled policy.
    cache_policy_id = aws_cloudfront_cache_policy.api.id

    # Forward viewer headers, cookies and query strings.
    origin_request_policy_id = aws_cloudfront_origin_request_policy.api.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.api_rewrite.arn
    }
  }

  # React single-page application routing.
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name      = "${var.project_name}-cloudfront"
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

# ----- CLOUDFRONT FUNCTION ----- #

# Rewrite /api/... to /... before forwarding requests to the backend.
resource "aws_cloudfront_function" "api_rewrite" {
  name    = "${var.project_name}-api-rewrite"
  runtime = "cloudfront-js-2.0"
  comment = "Remove the /api prefix before forwarding to the backend"
  publish = true

  code = <<-EOT
    function handler(event) {
      var request = event.request;
      request.uri = request.uri.replace(/^\/api/, "");
      return request;
    }
  EOT
}

# ----- S3 Bucket Policy ----- #

# Permit only this CloudFront distribution to read the frontend bucket.
resource "aws_s3_bucket_policy" "frontend" {
  bucket = var.frontend_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontServicePrincipalReadOnly"
      Effect = "Allow"

      Principal = {
        Service = "cloudfront.amazonaws.com"
      }

      Action   = "s3:GetObject"
      Resource = "${var.frontend_bucket_arn}/*"

      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
        }
      }
    }]
  })
}
