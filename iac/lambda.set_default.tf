# Set the default AI agent in Connect
# This can be removed or changed to handle the other agent
# types as needed

data "archive_file" "set_default_associate" {
  type        = "zip"
  source_dir  = "${path.module}/functions/set-default-ai-agent"
  output_path = "${path.module}/functions/set-default-ai-agent.zip"
}

resource "aws_cloudwatch_log_group" "set_default_function_logs" {
  # checkov:skip=CKV_AWS_338:Log retention is a user decided input
  # Because of the way the log groups are created before the function
  # we cannot programmatically retrieve the name
  name              = "/aws/lambda/${local.set_default_function_name}"
  retention_in_days = 7
  kms_key_id        = aws_kms_alias.q_encryption_key_alias.target_key_arn
}

resource "aws_lambda_function" "set_default" {
  filename         = data.archive_file.set_default_associate.output_path
  function_name    = local.set_default_function_name
  role             = aws_iam_role.set_default_lambda_role.arn
  handler          = "app.lambda_handler"
  source_code_hash = data.archive_file.set_default_associate.output_base64sha256
  timeout          = 29

  runtime = "python3.12"

  kms_key_arn = aws_kms_alias.q_encryption_key_alias.target_key_arn
}

resource "aws_lambda_invocation" "set_default_self_service" {
  function_name = aws_lambda_function.set_default.function_name

  input = jsonencode({
    assistant_id = awscc_wisdom_assistant.wisdom_assistant.assistant_id
    agent_type   = "SELF_SERVICE"
    configuration = {
      "aiAgentId" : awscc_wisdom_ai_agent_version.custom_self_service_agent_version.ai_agent_version_id
    }
  })
}
