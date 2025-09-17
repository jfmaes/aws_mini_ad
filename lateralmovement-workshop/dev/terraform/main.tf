module "vpc"{ 
  source = "./modules/vpc"
  vpc_cidr_block = local.vpc_cidr_block
  public_subnet_cidr_block = local.public_subnet_cidr_block
  private_sandbox_subnet_cidr_block = local.private_subnet_sandbox_cidr_block
  private_subnet_pwnzone_cidr_block = local.private_subnet_pwnzone_cidr_block
  private_subnet_treasureisland_cidr_block = local.private_subnet_treasureisland_cidr_block
  bastion_private_id  = module.vpn.bastion_private_id
}

module "security_groups"{ 
  source = "./modules/security_groups"
  vpc_id = module.vpc.vpc_id
  public_subnet_cidr_block = local.public_subnet_cidr_block
  private_subnet_sandbox_cidr_block = local.private_subnet_sandbox_cidr_block
  private_subnet_pwnzone_cidr_block = local.private_subnet_pwnzone_cidr_block
  private_subnet_treasureisland_cidr_block = local.private_subnet_treasureisland_cidr_block  

}

module "instances" { 
 source = "./modules/instances"
 private_subnet_sandbox_PWNZONE_id = module.vpc.private_subnet_sandbox_PWNZONE_id
 private_subnet_PWNZONE_id = module.vpc.private_subnet_PWNZONE_id
 private_subnet_TREASUREISLAND_id = module.vpc.private_subnet_TREASUREISLAND_id
 key_pair_name = module.vpc.key_pair_name
 lab_security_group_id  = module.security_groups.lab_security_group_id
}

module "vpn"{
  source = "./modules/vpn"
  ssh_key_path = local.ssh_key_path
  key_pair_name = module.vpc.key_pair_name
  public_subnet_id  = module.vpc.public_subnet_id
  external_sec_group_id = module.security_groups.external_security_group_id
  private_subnet_sandbox_PWNZONE_id = module.vpc.private_subnet_sandbox_PWNZONE_id
}


