# terraform-infra/environments/prod/terragrunt.hcl
include {
  path = find_in_parent_folders()
}

inputs = {
  environment     = "prod"
  vpc_cidr        = "10.1.0.0/16"
  public_subnets  = ["10.1.1.0/24"]
  private_subnets = ["10.1.2.0/24"]
  instance_type   = "t2.micro"
  bucket_name     = "my-terragrunt-prod-app-bucket-123"
}


