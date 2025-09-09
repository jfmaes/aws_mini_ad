variable "instance_prefix" {
  type        = string
  default     = "SEC565"
}

variable "ami_owner" {
  type        = string
  default     = "201554634916"
}

variable "private_subnet_sandbox_PWNZONE_id" {
  type        = string
  description = "ID of the private subnet for sandbox PWNZONE"
}

variable "private_subnet_PWNZONE_id" {
  type        = string
  description = "ID of the private subnet for PWNZONE"
}

variable "private_subnet_TREASUREISLAND_id" {
  type        = string
  description = "ID of the private subnet for TREASUREISLAND"
}

variable "lab_security_group_id" {
  type        = string
  description = "ID of the lab security group"
}

variable "key_pair_name" {
  type        = string
  description = "Name of the key pair to ssh into boxes."
}

variable "instance_type" {
  type        = string
  default = "t2.medium"
}


variable "lab_version_tag" {
  type        = string
  default = "v0.1"
}

