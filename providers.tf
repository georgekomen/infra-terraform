# providers and data
provider "aws" {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    region = var.region
}

data "template_file" "public_cidrsubnet" {
    count = var.subnet_count[terraform.workspace]

    template = "$${cidrsubnet(vpc_cidr, 8, current_count)}"

    vars = {
        vpc_cidr = var.network_address_space[terraform.workspace]
        current_count = count.index
    }
}

# availability zones
data "aws_availability_zones" "available" {

}

# amis
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
