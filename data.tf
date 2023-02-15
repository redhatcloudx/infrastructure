# Data lookups that are helpful for multiple terraform plans.

# Retrieve some information about the imagedirectory.cloud hosted DNS zone in
# Route 53.
data "aws_route53_zone" "imagedirectory_cloud" {
  name = "imagedirectory.cloud"
}