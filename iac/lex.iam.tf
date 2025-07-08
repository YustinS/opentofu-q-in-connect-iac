data "aws_iam_policy_document" "lex_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lexv2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "qic_bot_lambda_role" {
  name               = "${var.account_shortname}-qconnect-bot-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.lex_assume_role.json
}


resource "aws_iam_role_policy" "qic_bot_standard_config" {
  name   = "${var.account_shortname}-qconnect-bot-${var.environment}-permissions"
  role   = aws_iam_role.qic_bot_lambda_role.name
  policy = data.aws_iam_policy_document.qic_bot_lex_permissions.json
}

data "aws_iam_policy_document" "qic_bot_lex_permissions" {
  statement {
    sid = "AllowPollyAccess"
    actions = [
      "polly:SynthesizeSpeech",
    ]
    resources = ["*"]
  }

  statement {
    sid = "AllowComprehendAccess"
    actions = [
      "comprehend:DetectSentiment",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "qic_bot_qic_access" {
  name   = "${var.account_shortname}-qconnect-bot-${var.environment}-qic-access"
  role   = aws_iam_role.qic_bot_lambda_role.name
  policy = data.aws_iam_policy_document.qic_bot_qic_access.json
}

# Full permissions set for Lex to query QiC
data "aws_iam_policy_document" "qic_bot_qic_access" {
  statement {
    sid = "QInConnectAssistantPolicy"
    actions = [
      "wisdom:CreateSession",
      "wisdom:GetAssistant"
    ]
    resources = [
      awscc_wisdom_assistant.wisdom_assistant.assistant_arn,
      "${awscc_wisdom_assistant.wisdom_assistant.assistant_arn}/*"
    ]
  }

  statement {
    sid = "QInConnectSessionsPolicy"
    actions = [
      "wisdom:SendMessage",
      "wisdom:GetNextMessage"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:wisdom:*:${data.aws_caller_identity.current.account_id}:session/${awscc_wisdom_assistant.wisdom_assistant.assistant_id}/*"
    ]
  }
}
