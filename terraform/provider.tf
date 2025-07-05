provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
  ignore_tags {
    key_prefixes = ["AutoTag_"]
  }
  default_tags {
    tags = var.tags
  }
}


provider "awscc" {
  region  = var.aws_region
  profile = var.aws_profile
}

provider "archive" {}

provider "time" {}

# provider "aws" {
#   region  = "us-east-1"
#   profile = var.aws_profile
#   alias   = "global"
#   ignore_tags {
#     key_prefixes = ["AutoTag_"]
#   }
#   default_tags {
#     tags = var.default_tags
#   }
# }
