# This is a clean Windows Server 2022

data "aws_ami" "clean_server2022_base" {
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base*"]
  }
  owners = ["801119661308"]
}