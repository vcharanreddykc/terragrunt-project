# terraform-infra/environments/dev/terragrunt.hcl
include {
  path = find_in_parent_folders()
}

inputs = {
  environment     = "dev"
  vpc_cidr        = "10.0.0.0/16"
  public_subnets  = ["10.0.1.0/24"]
  private_subnets = ["10.0.2.0/24"]
  instance_type   = "t2.micro"
  bucket_name     = "mytest-terragrunt-s3-bucket-123"
}

