resource "aws_cloudwatch_log_group" "lex_logs" {
  name              = "/aws/lexv2/${local.bot_name}"
  retention_in_days = 30
  kms_key_id        = aws_kms_alias.q_encryption_key_alias.target_key_arn
}

# Deploys the most simple QiC Bot to Lex. This can be chatted with
# in Lex, or added to a Contact Flow after attaching to Connect as needed

resource "aws_cloudformation_stack" "async_social_chatbots" {
  # checkov:skip=CKV_AWS_124: Notifications are not relevant
  name = "${local.bot_name}-deployment"

  template_body = templatefile(
    "${path.module}/files/lex/lex-cloudformation.yaml.tftpl",
    {}
  )

  parameters = {
    BotName                = local.bot_name
    BotAlias               = "connect"
    BotRoleArn             = aws_iam_role.qic_bot_lambda_role.arn
    QinConnectAssistantArn = awscc_wisdom_assistant.wisdom_assistant.assistant_arn
    BotVersionDescription  = "Bot version for file hash: ${filesha512("${path.module}/files/lex/lex-cloudformation.yaml.tftpl")}"
    LogGroupArn            = aws_cloudwatch_log_group.lex_logs.arn
    NluConfidence          = "0.7"
  }
}
