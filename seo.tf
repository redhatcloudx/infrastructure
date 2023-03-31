# Add record for Google Webmaster Tools verification.
resource "aws_route53_record" "google_webmaster_tools_verification" {
  zone_id = data.aws_route53_zone.imagedirectory_cloud.zone_id
  name    = local.imagedirectory_domain
  type    = "TXT"

  records = [
    "google-site-verification=GhRM6zenYo0UAlisdemk7u_J_j_J4ue8wBNwdzmmUdw",
  ]

  ttl = "3600"
}
