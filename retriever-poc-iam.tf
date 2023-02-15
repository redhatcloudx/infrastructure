# Cloud items required for the retriever proof of concept.
# https://github.com/redhatcloudx/cloud-image-retriever

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

# IAM policy document that allows actions in the cloud-image-retriever repo to
# assume the role.
data "aws_iam_policy_document" "github_cloud_image_retriever" {
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
      values   = ["repo:redhatcloudx/cloud-image-retriever:*"]
    }
  }
}

data "aws_iam_policy_document" "get_image_data" {
  statement {
    sid    = "GetImageData"
    effect = "Allow"

    actions = [
      "ec2:DescribeImages",
      "ec2:DescribeRegions"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "get_image_data" {
  name = "get_image_data"

  policy = data.aws_iam_policy_document.get_image_data.json
}

resource "aws_iam_role" "github_actions_image_retriever" {
  name = "github_actions_image_retriever"

  managed_policy_arns = [aws_iam_policy.get_image_data.arn, aws_iam_policy.publish_image_data.arn]
  assume_role_policy  = data.aws_iam_policy_document.github_cloud_image_retriever.json
}