# random integer
resource "random_integer" "rand" {
  min = 10000
  max = 99999
}

# variables
variable "aws_access_key" {
    
}
variable "aws_secret_key" {

}
variable "private_key_path" {

}
variable "key_name" {

}
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
variable "bucket_name_prefix" {

}
variable "billing_code_tag" {

}

# locals
locals {
  env_name = lower(terraform.workspace) //get current workspace

  common_tags = {
    BillingCode = var.billing_code_tag
    Environment = local.env_name
  }
  s3_bucket_name = "${var.bucket_name_prefix}-${local.env_name}-${random_integer.rand.result}"
}
