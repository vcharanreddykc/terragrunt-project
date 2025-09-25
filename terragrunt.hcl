# terraform-infra/terragrunt.hcl
terraform {
  source = "./modules//"
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "my-terraform-states-123"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}

