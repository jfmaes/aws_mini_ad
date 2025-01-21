#need to get our own pub IP whitelisted.
data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

resource "aws_security_group" "external_sec_group" {
  name        = "security group for all external facing VMS"
  description = "sec565-playground-external-sec-group"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow all ingress from our own IP and from internal subnet"
    protocol    = "-1"
    to_port     = 0
    from_port   = 0
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32",
      var.private_subnet_pwnzone_cidr_block,
      var.private_subnet_sandbox_cidr_block,
      var.private_subnet_treasureisland_cidr_block,
      var.public_subnet_cidr_block]
  }

  egress {
    description = "Allow all egress"
    protocol    = "-1"
    to_port     = 0
    from_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sec565-playground-external-sec-group"
  }
}

resource "aws_security_group" "lab_security_group" {
  name        = "sec group for all non internet facing assets"
  description = "sec565-playground-lab-sec-group"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow all ingress from private subnet and the bastion host"
    protocol    = "-1"
    to_port     = 0
    from_port   = 0
    #since this is not internet facing, any any is fine.
    #cidr_blocks = ["${aws_instance.bastion.private_ip}/32",
    # aws_subnet.private_subnet_PWNZONE.cidr_block,
    #  aws_subnet.private_subnet_sandbox_PWNZONE.cidr_block,
    #aws_subnet.private_subnet_TREASUREISLAND.cidr_block]
    cidr_blocks = ["0.0.0.0/0"]
    }
    

  egress {
    description = "Allow all egress"
    protocol    = "-1"
    to_port     = 0
    from_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sec565-playground-lab-sec-group"
  }
}
