# Create a simple Connect instance.
# Disable voice channels by default

resource "aws_connect_instance" "poc_instance" {
  identity_management_type = "CONNECT_MANAGED"
  inbound_calls_enabled    = false
  instance_alias           = "${var.account_shortname}-${var.environment}-instance"
  outbound_calls_enabled   = false

  contact_flow_logs_enabled = true
}