data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "associate_lambda_role" {
  name               = "${local.associate_function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "python_lambda_role_logging" {
  name   = local.associate_function_name
  role   = aws_iam_role.associate_lambda_role.name
  policy = data.aws_iam_policy_document.python_lambda_policy.json
}

resource "aws_iam_role_policy" "python_lambda_role_wisdom" {
  name   = "${var.account_shortname}-wisdom-associater-wisdom-${var.environment}"
  role   = aws_iam_role.associate_lambda_role.name
  policy = data.aws_iam_policy_document.connect_integration_policy.json
}

data "aws_iam_policy_document" "python_lambda_policy" {
  statement {
    sid = "AllowCWAccess"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.function_logs.arn}:*"]
  }
}

data "aws_iam_policy_document" "connect_integration_policy" {
  statement {
    sid = "AllowKMSCreateGrant"
    actions = [
      "kms:CreateGrant"
    ]
    resources = [
      aws_kms_alias.q_encryption_key_alias.target_key_arn
    ]
  }

  statement {
    sid = "AllowRolePolicyAccess"
    actions = [
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy",
      "iam:CreateServiceLinkedRole"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/connect.amazonaws.com/*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/wisdom.amazonaws.com/*"
    ]
  }

  statement {
    sid = "AllowConnectAccess"
    actions = [
      "connect:DescribeInstance",
      "connect:CreateIntegrationAssociation",
      "connect:ListIntegrationAssociations",
      "connect:DeleteIntegrationAssociation",
      "connect:ListTagsForResource",
      "connect:TagResource",
      "connect:UntagResource"
    ]
    resources = [
      aws_connect_instance.poc_instance.arn,
      "${aws_connect_instance.poc_instance.arn}/integration-association/*"
    ]
  }

  statement {
    sid = "AllowWisdomAccess"
    actions = [
      "wisdom:ListAssistantAssociations",
      "wisdom:GetAssistant",
      "wisdom:GetKnowledgeBase",
      "wisdom:CreateAssistantAssociation",
      "wisdom:DeleteAssistant",
      "wisdom:DeleteKnowledgeBase",
      "wisdom:DeleteAssistantAssociation"
    ]
    resources = [
      "arn:aws:wisdom:${var.aws_region}:${data.aws_caller_identity.current.account_id}:assistant/*",
      "arn:aws:wisdom:${var.aws_region}:${data.aws_caller_identity.current.account_id}:knowledge-base/*",
      "arn:aws:wisdom:${var.aws_region}:${data.aws_caller_identity.current.account_id}:association/*/*",
    ]
  }

  statement {
    sid = "AllowBroadList"
    actions = [
      "ds:DescribeDirectories", # Required for connect:DescribeInstance, connect:ListIntegrationAssociations"
      "wisdom:ListAssistants",
      "wisdom:ListKnowledgeBases",
      "wisdom:ListTagsForResource",
      "wisdom:TagResource",
      "wisdom:UntagResource",
      # The following allow deletions if experiments have been done
      "app-integrations:DeleteApplicationAssociation",
      "app-integrations:DeleteEventIntegrationAssociation",
      "app-integrations:UntagResource",
      "events:DeleteRule",
      "events:ListTargetsByRule",
      "events:RemoveTargets",
    ]
    resources = [
      "*",
    ]
  }
}