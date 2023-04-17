# S3 configuration required to host the CID staging environment

# Create a policy for the S3 bucket that allows CloudFront to read objects.
data "aws_iam_policy_document" "read_cid_bucket_staging" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.cid_bucket_staging.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.retriever_poc.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.cid_bucket_staging.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.retriever_poc.iam_arn]
    }
  }
}

# Create a bucket for the JSON files.
resource "aws_s3_bucket" "cid_bucket_staging" {
  bucket = "cloudx-json-bucket"
}

# Add CORS to the bucket.
resource "aws_s3_bucket_cors_configuration" "cid_bucket_staging" {
  bucket = aws_s3_bucket.cid_bucket_staging.id

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

# Add our CloudFront bucket policy.
resource "aws_s3_bucket_policy" "cid_bucket_staging" {
  bucket = aws_s3_bucket.cid_bucket_staging.id
  policy = data.aws_iam_policy_document.read_cid_bucket_staging.json
}

# Set the bucket to private. We expose this bucket later via CloudFront.
resource "aws_s3_bucket_acl" "cid_bucket_staging" {
  bucket = aws_s3_bucket.cid_bucket_staging.id
  acl    = "private"
}
