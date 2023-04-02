# Some basic changes for the Fedora PoC.
# https://github.com/redhatcloudx/fedora-image-directory/

# Verify fedora.imagedirectory.cloud with GitHub Pages.
resource "aws_route53_record" "fedora_poc_github_verify" {
  zone_id = data.aws_route53_zone.imagedirectory_cloud.zone_id
  name    = "_github-pages-challenge-redhatcloudx.fedora"
  type    = "TXT"

  records = [
    "dcb857a3685b744f668e07360ecba4",
  ]

  ttl = "3600"
}
