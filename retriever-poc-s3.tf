# Cloud items required for the retriever proof of concept.
# https://github.com/redhatcloudx/cloud-image-retriever

# Create a bucket for the JSON files.
resource "aws_s3_bucket" "cloudx_json_bucket" {
  bucket = "cloudx-json-bucket"
}

# Set the bucket to private. We expose this bucket later via CloudFront.
resource "aws_s3_bucket_acl" "cloudx_json_bucket" {
  bucket = aws_s3_bucket.cloudx_json_bucket.id
  acl    = "private"
}