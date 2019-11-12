# output

# dns name
output "aws_instance_public_dns" {
  value = aws_elb.web.dns_name
}