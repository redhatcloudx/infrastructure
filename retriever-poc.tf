# Cloud items required for the retriever proof of concept.
# https://github.com/redhatcloudx/cloud-image-retriever

resource "aws_s3_bucket" "cloudx_json_bucket" {
  bucket = "cloudx-json-bucket"
}

resource "aws_s3_bucket_acl" "cloudx_json_bucket" {
  bucket = aws_s3_bucket.cloudx_json_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_website_configuration" "cloudx_json_bucket" {
  bucket = aws_s3_bucket.cloudx_json_bucket.bucket

  index_document {
    suffix = "index.json"
  }
}