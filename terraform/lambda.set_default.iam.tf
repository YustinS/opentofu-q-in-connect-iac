
resource "aws_iam_role" "set_default_lambda_role" {
  name               = "${local.set_default_function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "set_default_python_role_lambda" {
  name   = local.set_default_function_name
  role   = aws_iam_role.set_default_lambda_role.name
  policy = data.aws_iam_policy_document.set_default_python_lambda_policy.json
}

data "aws_iam_policy_document" "set_default_python_lambda_policy" {
  statement {
    sid = "AllowCWAccess"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.function_logs.arn}:*"]
  }
}

resource "aws_iam_role_policy" "set_default_lambda_role_wisdom" {
  name   = "${var.account_shortname}-wisdom-set-default-wisdom-${var.environment}"
  role   = aws_iam_role.set_default_lambda_role.name
  policy = data.aws_iam_policy_document.wisdom_set_default.json
}

data "aws_iam_policy_document" "wisdom_set_default" {
  statement {
    sid = "AllowWisdomAccess"
    actions = [
      "wisdom:UpdateAssistantAIAgent"
    ]
    resources = [
      "arn:aws:wisdom:${var.aws_region}:${data.aws_caller_identity.current.account_id}:assistant/*"
    ]
  }
}