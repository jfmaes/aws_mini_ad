resource "aws_instance" "soc_machine" {
  # Use Ubuntu LTS AMI
  ami           = data.aws_ami.ubuntu_lts.id
  instance_type = "t3.large"
  subnet_id     = var.private_subnet_sandbox_PWNZONE_id
  private_ip    = "10.0.10.50" # Fixed private IP for the SOC machine
  key_name      = var.key_pair_name
  user_data     = templatefile("${path.module}/../../../files/soc_userdata.sh.tpl", {
    public_key = file("${path.module}/../../../files/ssh_key.pub")
  })

  root_block_device {
    volume_size = 100 # Increased disk size for ELK stack
    delete_on_termination = true
  }

  tags = {
    Name = "${var.instance_prefix}-SOC"
  }
}

resource "aws_network_interface_sg_attachment" "soc_machine_attachment" {
  security_group_id    = var.lab_security_group_id
  network_interface_id = aws_instance.soc_machine.primary_network_interface_id
}

output "soc_machine_private_ip" {
  value = aws_instance.soc_machine.private_ip
}