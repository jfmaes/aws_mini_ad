resource "aws_key_pair" "key_pair" {
  key_name_prefix = "vpn"
  public_key      = file("${path.module}/../../../files/ssh_key.pub")
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "sec565-playground"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id #
  cidr_block = var.public_subnet_cidr_block
  tags = {
    Name = "sec565-playground-public-subnet"
  }
}

resource "aws_subnet" "private_subnet_sandbox_PWNZONE" {
  availability_zone = aws_subnet.public_subnet.availability_zone
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_sandbox_subnet_cidr_block
  tags = {
    Name = "sec565-playground-private-subnet-sandboxpwnzone"
  }
}

resource "aws_subnet" "private_subnet_PWNZONE" {
  depends_on        = [aws_subnet.public_subnet]
  availability_zone = aws_subnet.public_subnet.availability_zone
  vpc_id            = aws_vpc.main.id

  cidr_block = var.private_subnet_pwnzone_cidr_block
  tags = {
    Name = "sec565-playground-private-subnet-pwnzone"
  }
}

resource "aws_subnet" "private_subnet_TREASUREISLAND" {
  depends_on        = [aws_subnet.public_subnet]
  availability_zone = aws_subnet.public_subnet.availability_zone
  vpc_id            = aws_vpc.main.id

  #this CIDR block does matter as this is where our AD is gonna live.
  cidr_block = var.private_subnet_treasureisland_cidr_block
  tags = {
    Name = "sec565-playground-private-subnet-treasureisland"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "sec565-playground-internet-gateway"
  }
}

resource "aws_route_table" "internet_gateway" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

resource "aws_route_table_association" "internet_gateway" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.internet_gateway.id
}


//need bastion host added so we have internet via the bastion
resource "aws_route_table" "private_subnet" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gateway.id
  }
  #Add the VPN route here
  route {
    cidr_block           = "10.8.0.0/24"
    network_interface_id = var.bastion_private_id
  }
}

resource "aws_route_table_association" "private_subnet_PWNZONE" {
  subnet_id      = aws_subnet.private_subnet_PWNZONE.id
  route_table_id = aws_route_table.private_subnet.id
}

resource "aws_route_table_association" "private_subnet_sandbox_PWNZONE" {
  subnet_id      = aws_subnet.private_subnet_sandbox_PWNZONE.id
  route_table_id = aws_route_table.private_subnet.id
}

resource "aws_route_table_association" "private_subnet_TREASUREISLAND" {
  subnet_id      = aws_subnet.private_subnet_TREASUREISLAND.id
  route_table_id = aws_route_table.private_subnet.id
}

resource "aws_eip" "nat_gateway" {
  domain = "vpc"
}

resource "aws_nat_gateway" "gateway" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "NAT Gateway"
  }
}