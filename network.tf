# vpc, internet gateways, subnets, route tables and security groups

# vpc from vpc module, creates the vpc, subnets, routing and internet gateway
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "${local.env_name}-vpc"
  version = "2.15.0"

  cidr = var.network_address_space[terraform.workspace]
  azs = slice(data.aws_availability_zones.available.names, 0, var.subnet_count[terraform.workspace])
  public_subnets = data.template_file.public_cidrsubnet[*].rendered
  private_subnets = []

  tags = local.common_tags
}

# security group

# for elb
resource "aws_security_group" "elb-sg" {
  name = "nginx_elb_sg"
  vpc_id = module.vpc.vpc_id

  # allow http from anywhere
  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  # allow all outbound
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

# for instances
resource "aws_security_group" "nginx-instance-sg" {
    name = "nginx_komen_sg"
    description = "allow ports for nginx komen"
    vpc_id = module.vpc.vpc_id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [var.network_address_space[terraform.workspace]]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}