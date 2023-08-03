locals {
  # all files named index.js
  cloudfront_functions = {
    # add-cache-control-header  = "viewer-response"
    # add-cors-header           = "viewer-response"
    # add-origin-header    = "viewer-request"
    # add-security-headers = "viewer-response"
    # add-true-client-ip-header = "viewer-request"
    # redirect-based-on-country = viewer-request
    # url-rewrite-single-page-apps = 
    # verify-jwt = 
    request  = "viewer-request"
    response = "viewer-response"
  }
}

resource "aws_cloudfront_function" "main" {
  for_each = local.cloudfront_functions
  name     = "${each.key}_${replace(var.domain_name, ".", "_")}"
  runtime  = "cloudfront-js-1.0"
  comment  = each.key
  publish  = true
  code     = file("${path.module}/files/${each.key}/index.js")
}
