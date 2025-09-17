data "aws_ami" "openvpn" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  owners = ["amazon"]  # This is the correct way to filter by owner
}
