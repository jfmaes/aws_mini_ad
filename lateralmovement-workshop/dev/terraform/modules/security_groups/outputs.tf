output "external_security_group_id" {
    value = aws_security_group.external_sec_group.id
}

output "lab_security_group_id" {
    value = aws_security_group.lab_security_group.id
}
