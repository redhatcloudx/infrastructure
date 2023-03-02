# This file is almost exactly the same as retriever-poc-iam.tf.
# Even though permissions and roles are near identical,
# the seperation of concerns is worth the slight code duplication.

# Cloud items required for the transformer proof of concept.
# https://github.com/redhatcloudx/cloud-image-transformer

# IAM policy document for managing JSON content in the bucket.
data "aws_iam_policy_document" "transform_image_data" {
  statement {
    sid    = "TransformImageData"
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
      "arn:aws:s3:::${aws_s3_bucket.cloudx_json_bucket.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.cloudx_json_bucket.bucket}/*"
    ]
  }
}

# Load the IAM policy document into a policy that we can use with a role.
resource "aws_iam_policy" "transform_image_data" {
  name = "transform_data"

  policy = data.aws_iam_policy_document.transform_image_data.json
}

# IAM policy document that allows actions in the cloud-image-transformer repo to
# assume the role.
data "aws_iam_policy_document" "github_cloud_image_transformer" {
  statement {
    sid     = "GitHubActionsWebIdentityPolicy"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:redhatcloudx/cloud-image-transformer:*"]
    }
  }
}

resource "aws_iam_role" "github_actions_image_transformer" {
  name = "github_actions_image_transformer"

  managed_policy_arns = [aws_iam_policy.publish_image_data.arn]
  assume_role_policy  = data.aws_iam_policy_document.github_cloud_image_transformer.json
}