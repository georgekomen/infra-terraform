# Resources
resource "aws_vpc" "vpc" {
  cidr_block = var.network_address_space[terraform.workspace]
  enable_dns_hostnames = true

  tags = merge(local.common_tags, { Name = "${local.env_name}-vpc" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.common_tags, { Name = "${local.env_name}-igw" })
}

resource "aws_subnet" "subnet" {
  count = var.subnet_count[terraform.workspace]
  cidr_block = cidrsubnet(var.network_address_space[terraform.workspace], 8, count.index)
  vpc_id = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, { Name = "${local.env_name}-subnet${count.index + 1}" })
}

# Routing
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta" {
  count = var.subnet_count[terraform.workspace]
  subnet_id = aws_subnet.subnet[count.index].id
  route_table_id = aws_route_table.rt.id
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