# Logs data from QiC as per https://docs.aws.amazon.com/connect/latest/adminguide/monitor-q-assistants-cloudwatch.html#enable-assistant-logging

resource "aws_cloudwatch_log_group" "wisdom_logs" {
  name              = "/aws/qconnect/${var.account_shortname}-qconnect-logs"
  retention_in_days = 30
  kms_key_id        = aws_kms_alias.q_encryption_key_alias.target_key_arn
}


resource "aws_cloudwatch_log_delivery_source" "wisdom_logs" {
  name         = "${var.account_shortname}-wisdom-assistant-logs"
  log_type     = "EVENT_LOGS"
  resource_arn = awscc_wisdom_assistant.wisdom_assistant.assistant_arn
}

resource "aws_cloudwatch_log_delivery_destination" "wisdom_logs_destination" {
  name          = "${var.account_shortname}-wisdom-assistant-logs-destination"
  output_format = "json"

  delivery_destination_configuration {
    destination_resource_arn = aws_cloudwatch_log_group.wisdom_logs.arn
  }
}

resource "aws_cloudwatch_log_delivery" "wisdom_logs" {
  delivery_source_name     = aws_cloudwatch_log_delivery_source.wisdom_logs.name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.wisdom_logs_destination.arn
}