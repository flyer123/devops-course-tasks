terraform {
  backend "s3" {
    bucket         = "shju-terraform-state-bucket-2024-11"
    key            = "terraform/state"
    region         = "eu-north-1"
    dynamodb_table = "terraform-lock-table"
  }
}