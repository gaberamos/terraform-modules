# CLAUDE.md

This file provides guidance to AI assistants working with the terraform-modules repository.

## Repository Overview

This is a collection of reusable Terraform modules for AWS infrastructure, focused on static website hosting via CloudFront and S3. The modules are designed to be consumed by other Terraform configurations.

## Repository Structure

```
terraform-modules/
├── modules/
│   ├── acm/                    # AWS Certificate Manager module
│   ├── cloudfront_s3/          # CloudFront + S3 static hosting module
│   │   └── files/              # CloudFront Function source files
│   │       ├── request/        # Aggregated viewer-request handler
│   │       ├── response/       # Aggregated viewer-response handler
│   │       ├── add-cache-control-header/
│   │       ├── add-cors-header/
│   │       ├── add-origin-header/
│   │       ├── add-security-headers/
│   │       ├── add-true-client-ip-header/
│   │       ├── redirect-based-on-country/
│   │       ├── url-rewrite-single-page-apps/
│   │       └── verify-jwt/
│   └── s3_redirect/            # S3-based HTTP redirect module
├── .gitignore
└── README.md
```

## Modules

### `modules/acm`

Creates an ACM certificate with DNS validation via Route53.

**Resources created:**
- `aws_acm_certificate` — Certificate for the domain and `*.domain` wildcard
- `aws_route53_record` — DNS validation records
- `aws_acm_certificate_validation` — Waits for validation to complete

**Variables:**

| Variable | Default | Description |
|---|---|---|
| `domain_name` | `example.com` | The domain to issue the certificate for |

**Outputs:** `acm` — the full `aws_acm_certificate_validation` object

---

### `modules/cloudfront_s3`

Deploys a CloudFront distribution backed by a private S3 bucket for static website hosting.

**Resources created:**
- `aws_s3_bucket` — Private bucket named after `domain_name`, with `force_destroy = true`
- `aws_s3_bucket_public_access_block` — All public access blocked
- `aws_s3_object` (html/css/jpg) — Uploads files from `../../<domain_name>/files/` relative to the module path, with correct `content_type` per extension
- `aws_s3_bucket_policy` — Grants CloudFront OAC read access via `cloudfront.amazonaws.com` service principal
- `aws_cloudfront_origin_access_control` — SigV4-signed OAC for S3
- `aws_cloudfront_origin_access_identity` — Legacy OAI (kept alongside OAC)
- `aws_cloudfront_distribution` — CDN with two cache behaviors, geo-restriction, and HTTPS redirect
- `aws_cloudfront_function` — One function per entry in `local.cloudfront_functions`
- `aws_route53_record` (A + CNAME for `www`) — Alias records pointing to the distribution

**Variables:**

| Variable | Required | Default | Description |
|---|---|---|---|
| `domain_name` | No | `example.com` | Domain name; used as bucket name, distribution comment, and alias |
| `acm_certificate_arn` | Yes | — | ARN of an ACM certificate (must be in `us-east-1` for CloudFront) |

**Outputs:** `aws_cloudfront_distribution`, `aws_cloudfront_origin_access_control`, `aws_route53_record-www`, `aws_route53_record-a`, `aws_s3_bucket`

**Cache behavior:**
- Default: `min_ttl=0`, `default_ttl=3600`, `max_ttl=86400`, HTTP→HTTPS redirect
- Ordered (`*`): `default_ttl=86400`, `max_ttl=31536000`, compression enabled, `Origin` header forwarded

**Geo-restriction:** Whitelist — `US`, `CA`, `GB` (update in `cloudfront.tf` as needed)

**Price class:** `PriceClass_100` (US, Canada, Europe edge locations only)

**TLS:** SNI-only, minimum `TLSv1.2_2021`

---

### `modules/s3_redirect`

Redirects one domain to another using S3 website hosting redirect rules and Route53.

**Variables:**

| Variable | Required | Description |
|---|---|---|
| `domain_name` | Yes | The source domain to redirect from |
| `redirect_to_hostname` | Yes | The target hostname to redirect to |

---

## CloudFront Functions

Functions live in `modules/cloudfront_s3/files/`. Each subdirectory contains an `index.js` written in the **CloudFront JS 1.0** runtime (a restricted ES5.1 subset — no `fetch`, no Node.js APIs).

### Active Functions

The `cloudfront_functions.tf` local map controls which functions are deployed. Currently active:

| Key | Event Type | Source File |
|---|---|---|
| `request` | `viewer-request` | `files/request/index.js` |
| `response` | `viewer-response` | `files/response/index.js` |

The `request` and `response` handlers are the **aggregated** entry points. The named subdirectories (`add-security-headers`, `verify-jwt`, etc.) are standalone reference implementations.

### Available Function Library

| Directory | Event Type | Purpose |
|---|---|---|
| `add-cache-control-header` | viewer-response | Sets `Cache-Control` header for browser caching |
| `add-cors-header` | viewer-response | Injects CORS headers |
| `add-origin-header` | viewer-request | Adds/modifies `Origin` header |
| `add-security-headers` | viewer-response | Adds HSTS, CSP, X-Frame-Options, X-XSS-Protection, X-Content-Type-Options |
| `add-true-client-ip-header` | viewer-request | Passes real client IP to origin |
| `redirect-based-on-country` | viewer-request | Geo-based redirects using `CloudFront-Viewer-Country` header |
| `url-rewrite-single-page-apps` | viewer-request | Rewrites paths without extensions to `index.html` (SPA support) |
| `verify-jwt` | viewer-request | Validates JWT via SHA256 HMAC; uses constant-time comparison |

### Enabling/Disabling Functions

Edit the `cloudfront_functions` local in `cloudfront_functions.tf`. Comment out entries to disable; uncomment to enable:

```hcl
locals {
  cloudfront_functions = {
    # add-security-headers = "viewer-response"   # uncomment to enable
    request  = "viewer-request"
    response = "viewer-response"
  }
}
```

The function name in AWS is generated as `<key>_<domain_name with dots replaced by underscores>`.

### Testing CloudFront Functions

Each function directory contains test event JSON files and a README with the corresponding AWS CLI test command:

```bash
aws cloudfront test-function \
  --name <function-name> \
  --event-object fileb://test-event.json \
  --if-match <etag>
```

The `verify-jwt` directory also includes `generate-jwt.sh` for creating test tokens.

---

## File Upload Conventions

The `cloudfront_s3` module uploads static files from a directory located at `../../<domain_name>/files/` relative to the module path (i.e., a sibling directory to `modules/` named after your domain).

Files are uploaded by extension with the correct MIME type:

| Pattern | `content_type` |
|---|---|
| `**/*.html` | `text/html` |
| `**/*.css` | `text/css` |
| `**/*.jpg` | `image/jpeg` |

To support additional file types (`.js`, `.png`, `.svg`, etc.), add new `aws_s3_object` resources following the same pattern in `s3.tf`.

---

## Development Conventions

### File Organization

Each module follows this structure:

```
module-name/
├── variables.tf     # Input variable declarations
├── <service>.tf     # Resource definitions (named after the AWS service)
├── data.tf          # Data sources and derived resources (policies, zone lookups)
├── output.tf        # Output value declarations
└── locals.tf        # Local values (if needed)
```

### Naming Conventions

- Resource names default to `main` for the primary resource in a module (e.g., `aws_s3_bucket.main`)
- CloudFront function names: `<key>_<domain_underscored>` (auto-generated)
- Variable `domain_name` is the primary identifier passed through all modules

### Terraform State

State files (`.tfstate`, `.tfstate.*`) are **not** gitignored — they may be stored in this repo or managed externally. Lock files (`.terraform.lock.hcl`) and local provider caches (`.terraform/`) are ignored.

### Sensitive Files

`.tfvars` files are gitignored. Never commit secrets, credentials, or environment-specific variable values.

---

## Common Operations

### Initialize a module

```bash
terraform init
```

### Plan changes

```bash
terraform plan -var="domain_name=example.com" -var="acm_certificate_arn=arn:aws:acm:..."
```

### Apply changes

```bash
terraform apply -var="domain_name=example.com" -var="acm_certificate_arn=arn:aws:acm:..."
```

### Using modules from another Terraform configuration

```hcl
module "acm" {
  source      = "github.com/gaberamos/terraform-modules//modules/acm"
  domain_name = "example.com"
}

module "website" {
  source              = "github.com/gaberamos/terraform-modules//modules/cloudfront_s3"
  domain_name         = "example.com"
  acm_certificate_arn = module.acm.acm.certificate_arn
}
```

> **Note:** ACM certificates for CloudFront must be created in the `us-east-1` region regardless of where other resources are deployed.

---

## Known Limitations and Notes

- **S3 ACL deprecation:** `acl = "private"` is set directly on `aws_s3_bucket`. The separate `aws_s3_bucket_acl` resource is commented out as an alternative approach. For newer AWS provider versions, this may need to be split into a separate resource.
- **OAI vs OAC:** Both `aws_cloudfront_origin_access_identity` (legacy) and `aws_cloudfront_origin_access_control` (current) are defined. The bucket policy uses OAC. The OAI is retained but not wired to the distribution policy.
- **Geo-restriction:** The whitelist in `cloudfront.tf` is hardcoded to `["US", "CA", "GB"]`. Adjust or parameterize as needed.
- **File type coverage:** Only `.html`, `.css`, and `.jpg` are uploaded. Other common types (`.js`, `.png`, `.woff2`) require additional `aws_s3_object` blocks.
- **CloudFront JS runtime:** Functions use `cloudfront-js-1.0`, which lacks modern JavaScript features. Keep function logic ES5-compatible.
