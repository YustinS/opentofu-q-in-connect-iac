resource "awscc_wisdom_assistant" "wisdom_assistant" {
  name        = "${var.account_shortname}-wisdom-assistant"
  description = "Assistant for demo purposes"
  type        = "AGENT"
  server_side_encryption_configuration = {
    kms_key_id = aws_kms_alias.q_encryption_key_alias.target_key_arn
  }

  tags = local.tags_to_cc_tags

  # Ignore tag changes as attaching to Connect adds a new tag AmazonConnectEnabled
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "awscc_wisdom_knowledge_base" "q_knowlegde_base" {
  name                = "${var.account_shortname}-wisdom-kb"
  knowledge_base_type = "MANAGED"
  description         = "Wisdom KB for showing automation"

  server_side_encryption_configuration = {
    kms_key_id = aws_kms_alias.q_encryption_key_alias.target_key_arn
  }

  source_configuration = {
    managed_source_configuration = {
      web_crawler_configuration = {
        crawler_limits = {
          rate_limit = 300
        }
        exclusion_filters = null
        inclusion_filters = null
        scope             = null
        url_configuration = {
          seed_urls = [
            {
              url = var.url_to_webcrawl
            }
          ]
        }
      }
    }
  }

  tags = local.tags_to_cc_tags

  # Ignore tag changes as attaching to Connect adds a new tag AmazonConnectEnabled
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "awscc_wisdom_assistant_association" "wisdom_assistant_integration" {
  assistant_id = awscc_wisdom_assistant.wisdom_assistant.assistant_id # assistant_id works as well.
  association = {
    knowledge_base_id = awscc_wisdom_knowledge_base.q_knowlegde_base.id # knowledge_base_id works as well.
  }
  association_type = "KNOWLEDGE_BASE"

  tags = local.tags_to_cc_tags

  # Ignore tag changes as attaching to Connect adds a new tag AmazonConnectEnabled
  lifecycle {
    ignore_changes = [tags]
  }
}

# Once the API is updated the lambda calls in lambda.associate.tf will not be required.
# For now they are provided as a reference

# resource "awscc_connect_integration_association" "wisdom_assistant" {
#   instance_id      = aws_connect_instance.poc_instance.arn
#   integration_arn  = awscc_wisdom_assistant.wisdom_assistant.assistant_arn
#   integration_type = "WISDOM_ASSISTANT"
# }

# resource "awscc_connect_integration_association" "knowledge_base" {
#   instance_id      = aws_connect_instance.poc_instance.arn
#   integration_arn  = awscc_wisdom_knowledge_base.q_knowlegde_base.knowledge_base_arn
#   integration_type = "WISDOM_KNOWLEDGE_BASE"
# }

resource "awscc_wisdom_ai_prompt" "self_service" {
  name         = "CustomPreProcessing-SelfService"
  description  = "Example AI Prompt created using AWSCC provider"
  assistant_id = awscc_wisdom_assistant.wisdom_assistant.assistant_id

  api_format    = "MESSAGES"
  # This may need changing depending on your region. Check https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-resource-wisdom-aiprompt.html,
  # model ID. Note that by default QiC uses cross region inference, hence the ID is not tied to a single AWS Region
  model_id      = "apac.amazon.nova-pro-v1:0"
  type          = "SELF_SERVICE_PRE_PROCESSING"
  template_type = "TEXT"

  template_configuration = {
    text_full_ai_prompt_edit_template_configuration = {
      text = file("${path.module}/files/self_service/self-service-custom-prompt.yaml")
    }
  }
}

# Time providers are used to ensure we force the update
# without these the versioning would sometimes not trigger correctly
# meaning updates not applied. Due to API issues we also set a 2 minute sleep,
# as this is much more consistent
resource "time_sleep" "self_service_update" {
  create_duration = "120s"
  triggers = {
    prompt_updated = awscc_wisdom_ai_prompt.self_service.template_configuration.text_full_ai_prompt_edit_template_configuration.text
  }
}

resource "awscc_wisdom_ai_prompt_version" "self_service_version" {
  assistant_id = awscc_wisdom_assistant.wisdom_assistant.assistant_id
  ai_prompt_id = awscc_wisdom_ai_prompt.self_service.ai_prompt_id

  lifecycle {
    create_before_destroy = true
    replace_triggered_by = [
      time_sleep.self_service_update.id
    ]
  }
}


resource "awscc_wisdom_ai_prompt" "self_service_answer_generation" {
  name         = "CustomAnswerGeneration-SelfService"
  description  = "Example AI Prompt created using AWSCC provider"
  assistant_id = awscc_wisdom_assistant.wisdom_assistant.assistant_id

  api_format    = "TEXT_COMPLETIONS"
  # This may need changing depending on your region. Check https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-resource-wisdom-aiprompt.html,
  # model ID. Note that by default QiC uses cross region inference, hence the ID is not tied to a single AWS Region
  model_id      = "apac.amazon.nova-pro-v1:0"
  type          = "SELF_SERVICE_ANSWER_GENERATION"
  template_type = "TEXT"

  template_configuration = {
    text_full_ai_prompt_edit_template_configuration = {
      text = file("${path.module}/files/self_service/self-service-answer-generation.yaml")
    }
  }
}

# Time providers are used to ensure we force the update
# without these the versioning would sometimes not trigger correctly
# meaning updates not applied. Due to API issues we also set a 2 minute sleep,
# as this is much more consistent
resource "time_sleep" "self_service_answer_generation_update" {
  create_duration = "120s"
  triggers = {
    prompt_updated = awscc_wisdom_ai_prompt.self_service_answer_generation.template_configuration.text_full_ai_prompt_edit_template_configuration.text
  }
}

resource "awscc_wisdom_ai_prompt_version" "self_service_answer_generation" {
  assistant_id = awscc_wisdom_assistant.wisdom_assistant.assistant_id
  ai_prompt_id = awscc_wisdom_ai_prompt.self_service_answer_generation.ai_prompt_id

  lifecycle {
    create_before_destroy = true
    replace_triggered_by = [
      time_sleep.self_service_answer_generation_update.id
    ]
  }
}

# This creates the agent with the above config.
# Note that due to the way CC works this may require a redploy due to transient errors that
# don't make it clear what the exact issue was

resource "awscc_wisdom_ai_agent" "custom_self_service_agent" {
  assistant_id = awscc_wisdom_assistant.wisdom_assistant.assistant_id

  type = "SELF_SERVICE"
  name = "Custom-SelfService-Bot"

  description = "Custom created self service bot"

  configuration = {
    self_service_ai_agent_configuration = {
      self_service_answer_generation_ai_prompt_id = awscc_wisdom_ai_prompt_version.self_service_answer_generation.ai_prompt_version_id
      self_service_pre_processing_ai_prompt_id    = awscc_wisdom_ai_prompt_version.self_service_version.ai_prompt_version_id
    }
  }
}

resource "awscc_wisdom_ai_agent_version" "custom_self_service_agent_version" {
  ai_agent_id  = awscc_wisdom_ai_agent.custom_self_service_agent.ai_agent_id
  assistant_id = awscc_wisdom_assistant.wisdom_assistant.assistant_id

  lifecycle {
    create_before_destroy = true
    replace_triggered_by = [
      awscc_wisdom_ai_prompt_version.self_service_answer_generation.ai_prompt_version_id,
      awscc_wisdom_ai_prompt_version.self_service_version.ai_prompt_version_id
    ]
  }
}