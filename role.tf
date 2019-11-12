# roles, policies and instance profiles

# role
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

# instance profile
resource "aws_iam_instance_profile" "nginx_profile" {
  name = "${local.env_name}_nginx_profile"
  role = aws_iam_role.allow_nginx_s3.name
}

# role policy
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