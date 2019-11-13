# Load balancers and instances

# elb
resource "aws_elb" "web" {
  name = "nginx-elb"

  subnets = module.vpc.public_subnets
  security_groups = [aws_security_group.elb-sg.id]
  instances = aws_instance.nginx[*].id

  listener {
      instance_port = 80
      instance_protocol = "http"
      lb_port = 80
      lb_protocol = "http"
  }
}

# instance
resource "aws_instance" "nginx" {
  count = var.instance_count[terraform.workspace]
  ami = data.aws_ami.aws-linux.id
  instance_type = var.instance_size[terraform.workspace]
  subnet_id = module.vpc.public_subnets[count.index % var.subnet_count[terraform.workspace]]
  key_name = var.key_name
  vpc_security_group_ids = [aws_security_group.nginx-instance-sg.id]
  iam_instance_profile = module.bucket.instance_profile.name
  depends_on = [module.bucket]

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
        sudo /usr/local/bin/s3cmd sync --config=/home/ec2-user/.s3cfg /var/log/nginx/ s3://${module.bucket.bucket.id}/nginx/${count.index + 1}/
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
      "s3cmd get s3://${module.bucket.bucket.id}/website/index.html .",
      "s3cmd get s3://${module.bucket.bucket.id}/website/pic.png .",
      "sudo cp /home/ec2-user/index.html /usr/share/nginx/html/index.html",
      "sudo cp /home/ec2-user/pic.png /usr/share/nginx/html/pic.png",
      "sudo logrotate -f /etc/logrotate.conf"

    ]
  }

  tags = merge(local.common_tags, { Name = "${local.env_name}-nginx${count.index + 1}" })
}

# s3 module
module "bucket" {
  name = local.s3_bucket_name

  source = ".//modules//s3"
  common_tags = local.common_tags
}

# upload objects
resource "aws_s3_bucket_object" "website" {
  bucket = module.bucket.bucket.id
  key = "/website/index.html"
  source = "./assets/index.html"
}

resource "aws_s3_bucket_object" "graphic" {
  bucket = module.bucket.bucket.id
  key = "/website/pic.png"
  source = "./assets/pic.png"
}

# output

# dns name
output "aws_instance_public_dns" {
  value = aws_elb.web.dns_name
}