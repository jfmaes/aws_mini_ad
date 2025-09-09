resource "aws_instance" "dc_treasureisland" {
  ami           = data.aws_ami.clean_server2022_base.id
  instance_type = var.instance_type
  subnet_id     = var.private_subnet_TREASUREISLAND_id
  private_ip    = "10.0.200.10"
  key_name      = var.key_pair_name
  user_data     = file("${path.module}/../../../files/userdata_script")

  root_block_device {
    delete_on_termination = true
  }

  tags = {
    Name = "${var.instance_prefix}-PLAYGROUND-DC-TREASUREISLAND"
  }

}

resource "aws_network_interface_sg_attachment" "dc_treasure_attachment" {
  security_group_id    = var.lab_security_group_id
  network_interface_id = aws_instance.dc_treasureisland.primary_network_interface_id
}