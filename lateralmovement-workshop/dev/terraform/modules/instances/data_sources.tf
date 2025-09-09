# This is a clean Windows Server 2022

data "aws_ami" "clean_server2022_base" {
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base*"]
  }
  owners = ["801119661308"]
}

# data source for Ubuntu Server 22.04 LTS (Jammy Jellyfish)
data "aws_ami" "ubuntu_lts" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  owners = ["099720109477"] # Canonical's AWS account ID
}