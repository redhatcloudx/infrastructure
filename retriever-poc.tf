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

# Allow the bucket to host a website.
resource "aws_s3_bucket_website_configuration" "cloudx_json_bucket" {
  bucket = aws_s3_bucket.cloudx_json_bucket.bucket

  index_document {
    suffix = "index.json"
  }
}

# IAM policy document for managing JSON content in the bucket.
data "aws_iam_policy_document" "publish_image_data" {
  statement {
    sid    = "PublishImageData"
    effect = "Allow"

    actions = [
      "s3:DeleteObjectTagging",
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectAttributes",
      "s3:GetObjectTagging",
      "s3:ListBucket",
      "s3:PutObjectTagging",
      "s3:PutObjectAcl"
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.cloudx_json_bucket.bucket}/*"
    ]
  }
}

# Load the IAM policy document into a policy that we can use with a role.
resource "aws_iam_policy" "publish_image_data" {
  name = "publish_data"

  policy = data.aws_iam_policy_document.publish_image_data.json
}