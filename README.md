# QiC Automation Example

A sample of QiC automation using interfaces and capabilities as at the start of July 2025.
This contains a mix of regular AWS provider, the AWS Cloud Control provider, and some of the Terraform/OpenTofu utilities to make consistent.

**Note the sleep resources to version the AI Prompts. These are required (potentially not that long, but 60 seconds continued to fail, hence the 120 seconds) as the API would return errors without the wait**

The sample provided uses the webcrawler to simply the configuration even further, however you should align with AWS guidance including limiting scope on public sites or ensuring that you are allowed to scrape a website to get data.

## Requirements

- OpenTofu 1.10

## Running

1. Update `terraform.tfvars` with your values
2. Update the backend configuration in `versions.tf`
3. Run the standard openTofu loop of `tofu init`, `tofu plan`, and `tofu apply`
4. Try chatting to Q in Connect.
   - You can do this in AWS Lex v2 console by testing your bot
   - Alternately add the Lex bot to Connect, create a Contact Flow, and go for it
