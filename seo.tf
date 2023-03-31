# Add record for Google Webmaster Tools verification.
resource "aws_route53_record" "google_webmaster_tools_verification" {
  zone_id = data.aws_route53_zone.imagedirectory_cloud.zone_id
  name    = local.imagedirectory_domain
  type    = "TXT"

  records = [
    "google-site-verification=TFyddpFgC1auolmDtAWAjXfj6THpP4w9aQv2uD5EAjI",
  ]

  ttl = "3600"
}
