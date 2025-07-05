# Create a new key for this deployment.
# Whilst not strictly required maintaining your own KMS keys
# is best practice

resource "aws_kms_key" "q_encryption_key" {
  description             = "Encryption key for connect"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.kms_key_policy.json
}

resource "aws_kms_alias" "q_encryption_key_alias" {
  name          = "alias/connect/${aws_connect_instance.poc_instance.instance_alias}/q-in-connect-key"
  target_key_id = aws_kms_key.q_encryption_key.key_id
}

data "aws_iam_policy_document" "kms_key_policy" {
  statement {
    sid = "Enable IAM User Permissions"

    actions = [
      "kms:*",
    ]

    resources = [
      "*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid = "Allow Connect Access"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = [
      "*",
    ]

    principals {
      type = "Service"
      identifiers = [
        "connect.amazonaws.com"
      ]
    }
  }

  statement {
    sid = "Allow CloudWatch Logs to use this CMK."
    principals {
      type        = "Service"
      identifiers = ["logs.${var.aws_region}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}