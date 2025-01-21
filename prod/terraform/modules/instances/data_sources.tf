# This is a clean Windows Server 2022

data "aws_ami" "clean_server2022_base" {
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base*"]
  }
  owners = ["801119661308"]
}


//AMI SEARCHER LOGIC

data "aws_ami" "dc_pwnzone" {
  most_recent = true
  filter {
    name   = "name"
    values = ["AMI-SEC565-DC-PWNZONE*-${var.lab_version_tag}"]
  }
  owners = [var.ami_owner]
}


data "aws_ami" "dc_sandbox" {
  most_recent = true
  filter {
    name   = "name"
    values = ["AMI-SEC565-dc-sandbox-PWNZONE*-${var.lab_version_tag}"]
  }
  owners = [var.ami_owner]
}

data "aws_ami" "dc_treasureisland" {
  most_recent = true
  filter {
    name   = "name"
    values = ["AMI-SEC565-PLAYGROUND-DC-TREASUREISLAND*-${var.lab_version_tag}"]
  }
  owners = [var.ami_owner]
}

data "aws_ami" "ws01_sandbox" {
  most_recent = true
  filter {
    name   = "name"
    values = ["AMI-SEC565-ws01-sandbox-PWNZONE*-${var.lab_version_tag}"]
  }
  owners = [var.ami_owner]
}