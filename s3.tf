# create s3 bucket
resource "aws_s3_bucket" "web_bucket" {
  bucket = local.s3_bucket_name
  acl = "private"
  force_destroy = true

  tags = merge(local.common_tags, { Name = "${local.env_name}-web-bucket" })
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