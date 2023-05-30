# Resources for monitoring the cloud image directory.

# DNS records for upptime monitoring on GitHub Pages.
resource "aws_route53_record" "github_pages_upptime" {
  zone_id = data.aws_route53_zone.imagedirectory_cloud.zone_id
  name    = "status"
  type    = "CNAME"

  records = [
    "redhatcloudx.github.io",
  ]

  lifecycle {
    create_before_destroy = true
  }

  ttl = "3600"
}

# Verify status domain for GitHub Pages.
resource "aws_route53_record" "github_pages_upptime_verification" {
  zone_id = data.aws_route53_zone.imagedirectory_cloud.zone_id
  name    = "_github-pages-challenge-redhatcloudx.status"
  type    = "TXT"

  records = [
    "6032bd6825549735214b9280b7f1e6",
  ]

  lifecycle {
    create_before_destroy = true
  }

  ttl = "3600"
}
