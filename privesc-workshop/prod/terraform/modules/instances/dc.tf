resource "aws_instance" "dc_PWNZONE" {
  ami           = data.aws_ami.dc_pwnzone.id
  instance_type = var.instance_type
  subnet_id     = var.private_subnet_PWNZONE_id
  private_ip    = "10.0.100.10"
  key_name      = var.key_pair_name


  root_block_device {
    delete_on_termination = true
  }

  tags = {
    Name = "${var.instance_prefix}-PLAYGROUND-DC-PWNZONE"
  }

}

resource "aws_network_interface_sg_attachment" "dc_PWNZONE_attachment" {
  security_group_id    = var.lab_security_group_id
  network_interface_id = aws_instance.dc_PWNZONE.primary_network_interface_id
}