variable "vpc_name" {
  description = "The VPC Name for the playground"
  type        = string
  default     = "SEC565"
}

variable "vpc_cidr_block"{
  
  type  = string
}

variable "public_subnet_cidr_block"{
 
  type  = string

}

variable "private_sandbox_subnet_cidr_block" {
  type = string

}


variable "private_subnet_pwnzone_cidr_block" {
  type = string

}

variable "private_subnet_treasureisland_cidr_block" {
  type = string

}

variable "bastion_private_id" {
  type = string

}

variable "ssh_key_path" {
  type = string

}

variable "aws_region" {
  type = string

}

variable "lab_version_tag" {
  type = string

}