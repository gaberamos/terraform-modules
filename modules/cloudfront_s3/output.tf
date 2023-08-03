output "aws_cloudfront_distribution" {
  value = aws_cloudfront_distribution.main
}

output "aws_cloudfront_origin_access_control" {
  value = aws_cloudfront_origin_access_control.main
}

output "aws_route53_record-www" {
  value = aws_route53_record.www-a
}

output "aws_route53_record-a" {
  value = aws_route53_record.a
}

output "aws_s3_bucket" {
  value = aws_s3_bucket.main
}
