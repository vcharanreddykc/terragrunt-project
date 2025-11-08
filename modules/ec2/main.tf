resource "aws_instance" "app" {
  ami           = "ami-0157af9aea2eef346" # Amazon Linux 2 us-east-1
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_id

  tags = {
    Name = "${var.environment}-ec2"
  }
}

output "ec2_id" {
  value = aws_instance.app.id
}

