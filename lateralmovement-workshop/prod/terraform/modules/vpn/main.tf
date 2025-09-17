resource "aws_instance" "bastion"{
  ami                         = data.aws_ami.openvpn.id
  instance_type               = "t2.medium"
  key_name                    = var.key_pair_name
  
  network_interface {
    network_interface_id = aws_network_interface.bastion_public.id
    device_index         = 0
  }
 
  network_interface {
    network_interface_id = aws_network_interface.bastion_private.id
    device_index         = 1
  }
  root_block_device {
    delete_on_termination = true
  }
  
  tags = {
    Name = "565-playground-bastion"
  }

  provisioner "file" {
    source      = "${path.module}/../../../files/manage_openvpn.sh"
    destination = "/tmp/manage_openvpn.sh"
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${var.ssh_key_path}_${var.aws_region}_${var.lab_version_tag}")
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo amazon-linux-extras install epel -y",
      "sudo chmod +x /tmp/manage_openvpn.sh",
      "sudo /tmp/manage_openvpn.sh -i ",
      "sudo /tmp/manage_openvpn.sh -a student",
      "sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE",
      "sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth1 -j MASQUERADE",
      #cidr blocks of the subnets, this will have to be changed if you change the locals.
      "sudo ip route add 10.0.100.0/24 via 10.0.10.1 dev eth1",
      "sudo ip route add 10.0.200.0/24 via 10.0.10.1 dev eth1"
      

    ]
    connection {
      host        = aws_instance.bastion.*.public_ip[0]
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${var.ssh_key_path}_${var.aws_region}_${var.lab_version_tag}")
    }
  }

  provisioner "local-exec" {
    command = "scp -o IdentitiesOnly=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${var.ssh_key_path}_${var.aws_region}_${var.lab_version_tag} ec2-user@${self.public_ip}:/etc/openvpn/student.ovpn ${path.module}/../../../files/student.ovpn"
  }
}

 

resource "aws_network_interface" "bastion_public" {
 subnet_id = var.public_subnet_id
 security_groups = [ var.external_sec_group_id ]
 source_dest_check       = false
 private_ip_list         = [
 "10.0.1.10"
 ]
}

resource "aws_network_interface" "bastion_private" {
 source_dest_check       = false
 subnet_id               = var.private_subnet_sandbox_PWNZONE_id
 private_ips         = [
 "10.0.10.100"
 ]
}

resource "aws_eip" "bastion_eip"{
  domain = "vpc"
  network_interface         = aws_network_interface.bastion_public.id
}
