output "key_pair_name" {
    value = aws_key_pair.key_pair.key_name
}

output "vpc_id" {
    value = aws_vpc.main.id
}

output "public_subnet" {
    value = aws_subnet.public_subnet
}

output "public_subnet_id" {
    value = aws_subnet.public_subnet.id
}


output "private_subnet_sandbox_PWNZONE" {
    value = aws_subnet.private_subnet_sandbox_PWNZONE
}

output "private_subnet_sandbox_PWNZONE_id" {
    value = aws_subnet.private_subnet_sandbox_PWNZONE.id
}


output "private_subnet_PWNZONE" {
    value = aws_subnet.private_subnet_PWNZONE
}

output "private_subnet_PWNZONE_id" {
    value = aws_subnet.private_subnet_PWNZONE.id
}

output "private_subnet_TREASUREISLAND" {
    value = aws_subnet.private_subnet_TREASUREISLAND
}

output "private_subnet_TREASUREISLAND_id" {
    value = aws_subnet.private_subnet_TREASUREISLAND.id
}


output "internet_gateway" {
    value = aws_internet_gateway.internet_gateway
}


output "internet_gateway_id" {
    value = aws_internet_gateway.internet_gateway.id
}

output "route_table_internet_gateway_id" {
    value = aws_route_table.internet_gateway.id
}

output "route_table_association_internet_gateway_id" {
    value = aws_route_table_association.internet_gateway.id
}

output "route_table_private_subnet_id" {
    value = aws_route_table.private_subnet.id
}

output "route_table_association_private_subnet_PWNZONE_id" {
    value = aws_route_table_association.private_subnet_PWNZONE.id
}

output "route_table_association_private_subnet_sandbox_PWNZONE_id" {
    value = aws_route_table_association.private_subnet_sandbox_PWNZONE.id
}

output "route_table_association_private_subnet_TREASUREISLAND_id" {
    value = aws_route_table_association.private_subnet_TREASUREISLAND.id
}

output "nat_gateway_id" {
    value = aws_nat_gateway.gateway.id
}