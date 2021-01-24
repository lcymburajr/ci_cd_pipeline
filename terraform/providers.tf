provider "aws" {
  region = "us-east-1"
  profile = "terraform"
}

data "aws_availability_zones" "available" {}
