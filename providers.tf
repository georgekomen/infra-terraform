# Providers
provider "aws" {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    region = var.region
}

# Data
data "aws_availability_zones" "available" {

}

data "aws_ami" "aws-linux" {
  most_recent = true
  owners = ["amazon"]

  filter {
      name = "name"
      values = ["amzn-ami-hvm*"]
  }

  filter {
      name = "root-device-type"
      values = ["ebs"]
  }

  filter {
      name = "virtualization-type"
      values = ["hvm"]
  }
}
