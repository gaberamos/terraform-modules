resource "aws_s3_bucket" "main" {
  bucket        = var.domain_name
  force_destroy = true
  acl           = "private"
}

# resource "aws_s3_bucket_acl" "main" {
#   bucket = aws_s3_bucket.main.id
#   acl    = "private"
# }

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# resource "aws_s3_object" "files" {
#   for_each      = fileset("${path.module}/../../${var.domain_name}/files/", "**/*")
#   bucket        = aws_s3_bucket.main.id
#   key           = each.value
#   source        = "${path.module}/../../${var.domain_name}/files/${each.value}"
#   content_type  = "text/html"
#   force_destroy = true
#   # etag          = filemd5("${path.module}/../../${var.domain_name}/files/${each.value}")
# }

resource "aws_s3_object" "html" {
  for_each      = fileset("${path.module}/../../${var.domain_name}/files/", "**/*.html")
  bucket        = aws_s3_bucket.main.id
  key           = each.value
  source        = "${path.module}/../../${var.domain_name}/files/${each.value}"
  content_type  = "text/html"
  force_destroy = true
  etag          = filemd5("${path.module}/../../${var.domain_name}/files/${each.value}")
}

resource "aws_s3_object" "css" {
  for_each      = fileset("${path.module}/../../${var.domain_name}/files/", "**/*.css")
  bucket        = aws_s3_bucket.main.id
  key           = each.value
  source        = "${path.module}/../../${var.domain_name}/files/${each.value}"
  content_type  = "text/css"
  force_destroy = true
  etag          = filemd5("${path.module}/../../${var.domain_name}/files/${each.value}")
}

resource "aws_s3_object" "jpg" {
  for_each      = fileset("${path.module}/../../${var.domain_name}/files/", "**/*.jpg")
  bucket        = aws_s3_bucket.main.id
  key           = each.value
  source        = "${path.module}/../../${var.domain_name}/files/${each.value}"
  content_type  = "image/jpeg"
  force_destroy = true
  etag          = filemd5("${path.module}/../../${var.domain_name}/files/${each.value}")
}
