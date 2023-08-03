resource "aws_s3_bucket" "main" {
  bucket = var.domain_name
}

resource "aws_s3_bucket" "main-www" {
  bucket = "www.${var.domain_name}"
}

resource "aws_s3_bucket_website_configuration" "name" {
  bucket = aws_s3_bucket.main.bucket
  redirect_all_requests_to {
    host_name = var.redirect_to_hostname
    protocol  = "https"
  }
}

resource "aws_s3_bucket_website_configuration" "name-www" {
  bucket = aws_s3_bucket.main-www.bucket
  redirect_all_requests_to {
    host_name = var.redirect_to_hostname
    protocol  = "https"
  }
}
