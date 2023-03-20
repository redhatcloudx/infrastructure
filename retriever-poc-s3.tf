# Cloud items required for the retriever proof of concept.
# https://github.com/redhatcloudx/cloud-image-retriever

# Create a policy for the S3 bucket that allows CloudFront to read objects.
data "aws_iam_policy_document" "read_cloudx_json_bucket" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.cloudx_json_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.retriever_poc.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.cloudx_json_bucket.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.retriever_poc.iam_arn]
    }
  }
}

# Create a bucket for the JSON files.
resource "aws_s3_bucket" "cloudx_json_bucket" {
  bucket = "cloudx-json-bucket"
}

# Add our CloudFront bucket policy.
resource "aws_s3_bucket_policy" "cloudx_json_bucket" {
  bucket = aws_s3_bucket.cloudx_json_bucket.id
  policy = data.aws_iam_policy_document.read_cloudx_json_bucket.json
}

# Set the bucket to private. We expose this bucket later via CloudFront.
resource "aws_s3_bucket_acl" "cloudx_json_bucket" {
  bucket = aws_s3_bucket.cloudx_json_bucket.id
  acl    = "private"
}