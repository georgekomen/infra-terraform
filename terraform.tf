# Variables
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}
variable "key_name" {}
variable "region" {
  default = "ap-southeast-1"
}
variable "network_address_space" {
  type = map(string)
}
variable "subnet_count" {
  type = map(number)
}
variable "instance_size" {
  type = map(string)
}
variable "instance_count" {
  type = map(number)
}
variable "bucket_name_prefix" {}
variable "billing_code_tag" {}
variable "environment_tag" {}

# Providers
provider "aws" {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    region = var.region
}

# Locals
locals {
  env_name = lower(terraform.workspace) //get current workspace

  common_tags = {
    BillingCode = var.billing_code_tag
    Environment = local.env_name
  }
  s3_bucket_name = "${var.bucket_name_prefix}-${local.env_name}-${random_integer.rand.result}"
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

# Resources

#random integer
resource "random_integer" "rand" {
  min = 10000
  max = 99999
}

resource "aws_vpc" "vpc" {
  cidr_block = var.network_address_space[terraform.workspace]
  enable_dns_hostnames = true

  tags = merge(local.common_tags, { Name = "${var.environment_tag}-vpc" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.common_tags, { Name = "${var.environment_tag}-igw" })
}

resource "aws_subnet" "subnet" {
  count = var.subnet_count[terraform.workspace]
  cidr_block = cidrsubnet(var.network_address_space[terraform.workspace], 8, count.index)
  vpc_id = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, { Name = "${var.environment_tag}-subnet${count.index + 1}" })
}

# Routing
resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta-subnet1" {
  count = var.subnet_count[terraform.workspace]
  subnet_id = aws_subnet.subnet[count.index].id
  route_table_id = aws_route_table.rtb.id
}

# Security groups
resource "aws_security_group" "elb-sg" {
  name = "nginx_elb_sg"
  vpc_id = aws_vpc.vpc.id

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

resource "aws_security_group" "nginx-instance-sg" {
    name = "nginx_komen_sg"
    description = "allow ports for nginx komen"
    vpc_id = aws_vpc.vpc.id

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
# Load balancer
resource "aws_elb" "web" {
  name = "nginx-elb"

  subnets = aws_subnet.subnet[*].id
  security_groups = [aws_security_group.elb-sg.id]
  instances = aws_instance.nginx[*].id

  listener {
      instance_port = 80
      instance_protocol = "http"
      lb_port = 80
      lb_protocol = "http"
  }
}

# Instance
resource "aws_instance" "nginx" {
  count = var.instance_count[terraform.workspace]
  ami = data.aws_ami.aws-linux.id
  instance_type = var.instance_size[terraform.workspace]
  subnet_id = aws_subnet.subnet[count.index % var.subnet_count[terraform.workspace]].id
  key_name = var.key_name
  vpc_security_group_ids = [aws_security_group.nginx-instance-sg.id]
  iam_instance_profile = aws_iam_instance_profile.nginx_profile.name
  depends_on = [aws_iam_role_policy.allow_s3_all]

  connection {
      type = "ssh"
      host = self.public_ip
      user = "ec2-user"
      private_key = file(var.private_key_path)
  }

  provisioner "file" {
    content = <<EOF
access_key =
secret_key =
security_token =
use_https = True
bucket_location = US

EOF
    destination = "/home/ec2-user/.s3cfg"
  }

  provisioner "file" {
    content = <<EOF
/var/log/nginx/*log {
    daily
    rotate 10
    missingok
    compress
    sharedscripts
    postrotate
    endscript
    lastaction
        sudo /usr/local/bin/s3cmd sync --config=/home/ec2-user/.s3cfg /var/log/nginx/ s3://${aws_s3_bucket.web_bucket.id}/nginx/${count.index + 1}/
    endscript
}

EOF
    destination = "/home/ec2-user/nginx"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install nginx -y",
      "sudo service nginx start",
      "sudo cp /home/ec2-user/.s3cfg /root/.s3cfg",
      "sudo cp /home/ec2-user/nginx /etc/logrotate.d/nginx",
      # "sudo pip install --upgrade pip",
      "sudo pip install s3cmd",
      "s3cmd get s3://${aws_s3_bucket.web_bucket.id}/website/index.html .",
      "s3cmd get s3://${aws_s3_bucket.web_bucket.id}/website/pic.png .",
      "sudo cp /home/ec2-user/index.html /usr/share/nginx/html/index.html",
      "sudo cp /home/ec2-user/pic.png /usr/share/nginx/html/pic.png",
      "sudo logrotate -f /etc/logrotate.conf"

    ]
  }

  tags = merge(local.common_tags, { Name = "${var.environment_tag}-nginx${count.index + 1}" })
}

# S3 bucket config
resource "aws_iam_role" "allow_nginx_s3" {
  name = "${local.env_name}_allow_nginx_s3"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
  EOF
}

resource "aws_iam_instance_profile" "nginx_profile" {
  name = "${local.env_name}_nginx_profile"
  role = aws_iam_role.allow_nginx_s3.name
}

resource "aws_iam_role_policy" "allow_s3_all" {
  name = "${local.env_name}_allow_s3_all"

  role = aws_iam_role.allow_nginx_s3.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${local.s3_bucket_name}",
        "arn:aws:s3:::${local.s3_bucket_name}/*"
      ]
    }
  ]
}
  EOF
}

# create s3 bucket
resource "aws_s3_bucket" "web_bucket" {
  bucket = local.s3_bucket_name
  acl = "private"
  force_destroy = true

  tags = merge(local.common_tags, { Name = "${var.environment_tag}-web-bucket" })
}

# upload objects
resource "aws_s3_bucket_object" "website" {
  bucket = aws_s3_bucket.web_bucket.bucket
  key = "/website/index.html"
  source = "./assets/index.html"
}

resource "aws_s3_bucket_object" "graphic" {
  bucket = aws_s3_bucket.web_bucket.bucket
  key = "/website/pic.png"
  source = "./assets/pic.png"
}

# Output
output "aws_instance_public_dns" {
  value = aws_elb.web.dns_name
}