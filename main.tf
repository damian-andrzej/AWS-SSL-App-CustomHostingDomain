terraform {
  backend "s3" {
    bucket         = "damian-andrzej-bucket9"      # Replace with your actual S3 bucket name
    key            = "terraform/state.tfstate"      # Path to store the state file
    region         = "us-east-1"                    # Region of the S3 bucket
    encrypt        = true                            # Enable encryption for security
  }
}


provider "aws" {
  region = "us-east-1" # ACM for CloudFront must be in us-east-1
}

# S3 bucket for hosting the static website
resource "aws_s3_bucket" "static_website" {
  bucket = "damian-andrzej-bucket9" # Globally unique bucket name
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    Name = "DamianAndrzejS3Bucket"
  }
}



# CloudFront distribution
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = "${aws_s3_bucket.static_website.bucket}.s3-website-us-east-1.amazonaws.com" # Use S3 website endpoint
    origin_id   = "S3-${aws_s3_bucket.static_website.bucket}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
    }
  }

  enabled             = true
  default_root_object = "index.html"

  aliases = ["damian-andrzej.com", "www.damian-andrzej.com"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.static_website.bucket}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_100"

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method              = "sni-only"
    minimum_protocol_version        = "TLSv1.2_2019"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "DamianAndrzejCloudFront"
  }
}

# ACM Certificate
resource "aws_acm_certificate" "certificate" {
  domain_name       = "damian-andrzej.com"
  validation_method = "DNS"
  subject_alternative_names = ["www.damian-andrzej.com"]

  tags = {
    Name = "DamianAndrzejCertificate"
  }
}

# Route 53 Hosted Zone for damian-andrzej.com
resource "aws_route53_zone" "primary" {
  name = "damian-andrzej.com"
}

# DNS validation for ACM certificate
resource "aws_route53_record" "cert_validation_records" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.primary.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 300
}

# ACM Certificate Validation
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_records : record.fqdn]
}

# CloudFront Origin Access Identity (OAI) for S3
resource "aws_cloudfront_origin_access_identity" "s3_access" {
  comment = "Access for CloudFront to S3 bucket"
}

# Update S3 Bucket Policy for CloudFront OAI
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.static_website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.s3_access.iam_arn
        }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_website.arn}/*"
      }
    ]
  })
}

# Route 53 records for domain and www subdomain
resource "aws_route53_record" "root_domain" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "damian-andrzej.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_subdomain" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.damian-andrzej.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

output "website_endpoint" {
  value = aws_cloudfront_distribution.cdn.domain_name
}
