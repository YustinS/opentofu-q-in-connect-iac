terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = ">= 1.48.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 1.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.13.1"
    }
  }

  # Add your backend configuration here.
  # This is highly recommended
  # backend "s3" {
  #   bucket  = ""
  #   key     = "q-in-connect-automated/terraform.tfstate"
  #   region  = "ap-southeast-2"
  #   profile = ""
  # }
}