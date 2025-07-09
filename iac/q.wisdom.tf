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

# resource "awscc_wisdom_ai_prompt" "test_non_standard_prompt" {
#   name         = "Anthropic-SelfService"
#   description  = "Example AI Prompt created using AWSCC provider"
#   assistant_id = awscc_wisdom_assistant.wisdom_assistant.assistant_id

#   api_format    = "ANTHROPIC_CLAUDE_MESSAGES"
#   # This may need changing depending on your region. Check https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-resource-wisdom-aiprompt.html,
#   # model ID. Note that by default QiC uses cross region inference, hence the ID is not tied to a single AWS Region
#   model_id      = "apac.anthropic.claude-3-haiku-20240307-v1:0"
#   type          = "SELF_SERVICE_PRE_PROCESSING"
#   template_type = "TEXT"

#   template_configuration = {
#     text_full_ai_prompt_edit_template_configuration = {
#       text = file("${path.module}/files/self_service/self-service-custom-prompt.yaml")
#     }
#   }
# }


# This example shows usage with Anthropic models
resource "awscc_wisdom_ai_prompt" "self_service" {
  name         = "CustomPreProcessing-SelfService"
  description  = "Example AI Prompt created using AWSCC provider"
  assistant_id = awscc_wisdom_assistant.wisdom_assistant.assistant_id

  api_format = "ANTHROPIC_CLAUDE_MESSAGES"
  # This may need changing depending on your region. Check https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-resource-wisdom-aiprompt.html,
  # model ID. Note that by default QiC uses cross region inference, hence the ID is not tied to a single AWS Region
  model_id      = "apac.anthropic.claude-3-5-sonnet-20241022-v2:0"
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

# This example shows usage with Amazon Nova
resource "awscc_wisdom_ai_prompt" "self_service_answer_generation" {
  name         = "CustomAnswerGeneration-SelfService"
  description  = "Example AI Prompt created using AWSCC provider"
  assistant_id = awscc_wisdom_assistant.wisdom_assistant.assistant_id

  api_format = "TEXT_COMPLETIONS"
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

# A sample of configurations for Guardrails. Apart from the indicated most features can be
# enabled/disabled, or adjusted as seen fit. In this example consider that the Bot is intended
# for self-service, and as such should be stricter than internal facing
resource "awscc_wisdom_ai_guardrail" "guardrail_configurations" {
  name         = "CustomAiBot-Self-Service-Guardrails"
  description  = "Sample of the guardrails that can be configured to enforce quality of contents"
  assistant_id = awscc_wisdom_assistant.wisdom_assistant.assistant_id

  # Required messaging configurations
  blocked_input_messaging   = "I am unable to respond due to your request containing prohibited content. Please revise and try again."
  blocked_outputs_messaging = "I tried to get you an answer, however policy prevents me from responding back. We can discuss something different however."

  # Content policy configuration
  # https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-properties-wisdom-aiguardrail-aiguardrailcontentpolicyconfig.html
  content_policy_config = {
    filters_config = [
      # https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-properties-wisdom-aiguardrail-guardrailcontentfilterconfig.html
      {
        type            = "HATE"
        input_strength  = "HIGH"
        output_strength = "MEDIUM"
      },
      {
        type            = "VIOLENCE"
        input_strength  = "HIGH"
        output_strength = "LOW"
      },
      {
        type            = "SEXUAL"
        input_strength  = "HIGH"
        output_strength = "LOW"
      },
      {
        type            = "INSULTS"
        input_strength  = "HIGH"
        output_strength = "MEDIUM"
      },
      # 
      {
        type            = "MISCONDUCT"
        input_strength  = "HIGH"
        output_strength = "LOW"
      },
      # Output can only ever be NONE. Setting to any other value
      # raises an error
      {
        type            = "PROMPT_ATTACK"
        input_strength  = "HIGH"
        output_strength = "NONE"
      }
    ]
  }

  # Word policy configuration
  # https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-properties-wisdom-aiguardrail-aiguardrailwordpolicyconfig.html
  word_policy_config = {
    words_config = [
      # https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-properties-wisdom-aiguardrail-guardrailwordconfig.html
      {
        # For some reason the SDK requires this, and if you remove after creation it doesn't detect the diff
        text = "some_super_fake_and_not_hittable_restricted_word"
      }
    ]
    managed_word_lists_config = [
      # https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-properties-wisdom-aiguardrail-guardrailmanagedwordsconfig.html
      {
        type = "PROFANITY"
      }
    ]
  }

  # Topic policy configuration
  # https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-properties-wisdom-aiguardrail-aiguardrailtopicpolicyconfig.html
  topic_policy_config = {
    topics_config = [
      # https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-properties-wisdom-aiguardrail-guardrailtopicconfig.html
      {
        name       = "Discussion Competitors"
        type       = "DENY"
        definition = "Any discussion related to Competitors"
        examples   = ["What are your competitors prices", "A better deal with another company", "Company offers a better product", "Why would I use you over Competitor"]
      }
    ]
  }

  # Sensitive information policy configuration
  # https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-properties-wisdom-aiguardrail-aiguardrailsensitiveinformationpolicyconfig.html
  sensitive_information_policy_config = {
    pii_entities_config = [
      # https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-properties-wisdom-aiguardrail-guardrailpiientityconfig.html
      {
        type   = "INTERNATIONAL_BANK_ACCOUNT_NUMBER"
        action = "BLOCK"
      },
      {
        type   = "PASSWORD"
        action = "BLOCK"
      },
      {
        type   = "CREDIT_DEBIT_CARD_NUMBER"
        action = "BLOCK"
      },
    ]
    regexes_config = [
      # For some reason the SDK requires this, and if you remove after creation it doesn't detect the diff
      # https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-properties-wisdom-aiguardrail-guardrailregexconfig.html
      {
        name        = "Default"
        description = "A simple, untriggeredable default as this needs to exist for the API to not reject"
        pattern     = "Z{24}"
        action      = "BLOCK"
      }
    ]
  }

  # Contextual grounding policy configuration
  # https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-properties-wisdom-aiguardrail-aiguardrailcontextualgroundingpolicyconfig.html
  contextual_grounding_policy_config = {
    filters_config = [
      # https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-properties-wisdom-aiguardrail-guardrailcontextualgroundingfilterconfig.html
      {
        type      = "GROUNDING"
        threshold = 0.7
      },
      {
        type      = "RELEVANCE"
        threshold = 0.5
      }
    ]
  }
}

resource "awscc_wisdom_ai_guardrail_version" "guardrail_configurations_version" {
  assistant_id    = awscc_wisdom_assistant.wisdom_assistant.assistant_id
  ai_guardrail_id = awscc_wisdom_ai_guardrail.guardrail_configurations.ai_guardrail_id

  lifecycle {
    create_before_destroy = true
    replace_triggered_by = [
      # This is technically hacky, but not all fields when updated will trigger an adjustment,
      # and pretty reasonably forces the behaviour that would be desired
      awscc_wisdom_ai_guardrail.guardrail_configurations.content_policy_config,
      awscc_wisdom_ai_guardrail.guardrail_configurations.word_policy_config,
      awscc_wisdom_ai_guardrail.guardrail_configurations.topic_policy_config,
      awscc_wisdom_ai_guardrail.guardrail_configurations.sensitive_information_policy_config,
      awscc_wisdom_ai_guardrail.guardrail_configurations.contextual_grounding_policy_config,
    ]
  }
}



resource "awscc_wisdom_ai_agent" "custom_self_service_agent" {
  assistant_id = awscc_wisdom_assistant.wisdom_assistant.assistant_id

  type = "SELF_SERVICE"
  name = "Custom-SelfService-Bot"

  description = "Custom created self service bot"

  configuration = {
    self_service_ai_agent_configuration = {
      self_service_answer_generation_ai_prompt_id = awscc_wisdom_ai_prompt_version.self_service_answer_generation.ai_prompt_version_id
      self_service_pre_processing_ai_prompt_id    = awscc_wisdom_ai_prompt_version.self_service_version.ai_prompt_version_id
      self_service_ai_guardrail_id                = awscc_wisdom_ai_guardrail_version.guardrail_configurations_version.ai_guardrail_version_id
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
      awscc_wisdom_ai_prompt_version.self_service_version.ai_prompt_version_id,
      awscc_wisdom_ai_guardrail_version.guardrail_configurations_version.ai_guardrail_version_id
    ]
  }
}