resource "aws_route53_record" "www-a" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_s3_bucket.main-www.website_domain
    zone_id                = aws_s3_bucket.main-www.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "a" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_s3_bucket.main.website_domain
    zone_id                = aws_s3_bucket.main.hosted_zone_id
    evaluate_target_health = false
  }
}
