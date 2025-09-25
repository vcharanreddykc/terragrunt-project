resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  acl    = "private"

  tags = {
    Name = "${var.environment}-bucket"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.bucket.id
}

