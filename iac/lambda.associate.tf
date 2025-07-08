# Associates Q in Connect to the Connect instance
# This is not possible using purely Terraform configs at this time

data "archive_file" "trigger_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/functions/associate-to-connect"
  output_path = "${path.module}/functions/associate-to-connect.zip"
}

resource "aws_cloudwatch_log_group" "function_logs" {
  # checkov:skip=CKV_AWS_338:Log retention is a user decided input
  # Because of the way the log groups are created before the function
  # we cannot programmatically retrieve the name
  name              = "/aws/lambda/${local.associate_function_name}"
  retention_in_days = 7
  kms_key_id        = aws_kms_alias.q_encryption_key_alias.target_key_arn
}

resource "aws_lambda_function" "association" {
  filename         = data.archive_file.trigger_lambda.output_path
  function_name    = local.associate_function_name
  role             = aws_iam_role.associate_lambda_role.arn
  handler          = "app.lambda_handler"
  source_code_hash = data.archive_file.trigger_lambda.output_base64sha256
  timeout          = 29

  runtime = "python3.12"

  kms_key_arn = aws_kms_alias.q_encryption_key_alias.target_key_arn
}

resource "aws_lambda_invocation" "association" {
  function_name = aws_lambda_function.association.function_name

  input = jsonencode({
    instance_id = aws_connect_instance.poc_instance.id
    wisdom_arn  = awscc_wisdom_assistant.wisdom_assistant.assistant_arn
    kb_arn      = awscc_wisdom_knowledge_base.q_knowlegde_base.knowledge_base_arn
  })
}
