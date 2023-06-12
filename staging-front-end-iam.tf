# This file is almost exactly the same as retriever-poc-iam.tf.
# Even though permissions and roles are near identical,
# the seperation of concerns is worth the slight code duplication.

# IAM policy document for managing static content in the bucket.
data "aws_iam_policy_document" "push_to_staging" {
  statement {
    sid    = "PushStaticFrontEnd"
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
      "arn:aws:s3:::${aws_s3_bucket.cid_bucket_staging.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.cid_bucket_staging.bucket}/*"
    ]
  }
}

# Load the IAM policy document into a policy that we can use with a role.
resource "aws_iam_policy" "push_to_staging" {
  name = "push_static_files_to_staging"

  policy = data.aws_iam_policy_document.push_to_staging.json
}

# IAM policy document that allows actions in the cloud-image-* repos to
# assume the role.
data "aws_iam_policy_document" "github_cloud_image_directory_staging" {
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
      values = ["repo:redhatcloudx/cloud-image-directory-frontend:*",
        "repo:redhatcloudx/cloud-image-retriever:*",
        "repo:redhatcloudx/transformer:*"
      ]
    }
  }
}

resource "aws_iam_role" "github_actions_cloud_image_directory_staging" {
  name = "github_actions_cloud_image_directory_staging"

  managed_policy_arns = [aws_iam_policy.push_to_staging.arn]
  assume_role_policy  = data.aws_iam_policy_document.github_cloud_image_directory_staging.json
}

