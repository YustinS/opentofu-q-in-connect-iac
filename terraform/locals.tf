locals {
  tags_to_cc_tags = [for k, v in var.tags : { "key" = k, "value" = v } if k != null && v != null]

  associate_function_name   = "${var.account_shortname}-wisdom-associater-${var.environment}"
  set_default_function_name = "${var.account_shortname}-wisdom-set-default-${var.environment}"

  bot_name = "${var.account_shortname}-qic-bot-${var.environment}"
}

data "aws_caller_identity" "current" {}