resource "aws_instance" "soc_machine" {
  ami           = data.aws_ami.soc_machine.id
  instance_type = var.instance_type
  subnet_id     = var.private_subnet_sandbox_PWNZONE_id
  private_ip    = "10.0.10.50"
  key_name      = var.key_pair_name

  root_block_device {
    delete_on_termination = true
  }

  tags = {
    Name = "${var.instance_prefix}-soc-machine"
  }

}

resource "aws_network_interface_sg_attachment" "soc_machine_attachment" {
  security_group_id    = var.lab_security_group_id
  network_interface_id = aws_instance.soc_machine.primary_network_interface_id
}
