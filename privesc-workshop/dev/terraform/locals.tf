#Locals are variables that shouldn't be changed by users.
locals {
  vpc_cidr_block                            = "10.0.0.0/16"                   # Defines the entire CIDR block for the VPC
  public_subnet_cidr_block                  = "10.0.1.0/24"                   # CIDR block for the public subnet
  private_subnet_sandbox_cidr_block         = "10.0.10.0/24"                  # CIDR block for the private sandbox subnet
  private_subnet_pwnzone_cidr_block         = "10.0.100.0/24"                 # CIDR block for the private pwnzone subnet
  private_subnet_treasureisland_cidr_block  = "10.0.200.0/24"                 # CIDR block for the private treasure island subnet
  ssh_key_path				                      = "${path.module}/../files/ssh_key"	    # The SSH key path for the VPN
}
