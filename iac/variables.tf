variable "aws_region" {
  description = "AWS Region that this is run in"
  type        = string
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "The environment this is running against"
  type        = string
}

variable "aws_profile" {
  description = "The named profile used to deploy the resources"
  type        = string
}

variable "account_shortname" {
  description = "Shortname for account, that will be used with ensuring naming is consistent"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to resources. The application of these is on a per-resource config"
  type        = map(any)
  default     = {}
}

variable "url_to_webcrawl" {
  description = "Full URL to webcrawl to extract the Q Knowledgebase. It is your responsiblity to follow guidance as laid out by AWS at https://docs.aws.amazon.com/connect/latest/adminguide/enable-q.html#enable-q-step-3"
  type        = string
}