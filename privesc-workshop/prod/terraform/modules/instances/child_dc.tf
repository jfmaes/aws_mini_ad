resource "aws_instance" "dc_sandbox_PWNZONE" {
  ami           = data.aws_ami.dc_sandbox.id
  instance_type = var.instance_type
  subnet_id     = var.private_subnet_sandbox_PWNZONE_id
  private_ip    = "10.0.10.10"
  key_name      = var.key_pair_name


  root_block_device {
    delete_on_termination = true
  }

  tags = {
    Name = "${var.instance_prefix}-dc-sandbox-PWNZONE"
  }

}

resource "aws_network_interface_sg_attachment" "dc_sandbox_PWNZONE_attachment" {
  security_group_id    = var.lab_security_group_id
  network_interface_id = aws_instance.dc_sandbox_PWNZONE.primary_network_interface_id
}
