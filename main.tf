variable "vpc_cidr" {}
variable "vpc_subnetA" {}
variable "vpc_name"  {}
variable "availability_zoneA" {}

variable "ec2_jenkins_ami_id" {}
variable "ec2_jenkins_instance_type" {}


provider "aws" {
  region = "us-east-1"  # Укажите ваш регион
}

module "networking" {
  source               = "./networking"
  vpc_cidr             = var.vpc_cidr
  vpc_name             = var.vpc_name
  vpc_subnet           = var.vpc_subnetA
  availability_zone    = var.availability_zoneA

} 



# Create pub key 
resource "tls_private_key" "proj_1" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Add key pair
resource "aws_key_pair" "deployer" {
  key_name   = "my-key"
  public_key = tls_private_key.proj_1.public_key_openssh
}


module "ec2_jenkins" {
  source = "./ec2_jenkins"
  # vpc_id                  = aws_vpc.proj_1.id
  subnet_id               = module.networking.subnet_id
  vpc_security_group_ids  = [module.networking.security_group_id]
  key_name                = aws_key_pair.deployer.key_name
  ami_id                  = var.ec2_jenkins_ami_id
  instance_type           = var.ec2_jenkins_instance_type
}


# SSH 
output "private_key_pem" {
  value     = tls_private_key.proj_1.private_key_pem
  sensitive = true
}

# output "jenkins_public_ip" {
#   value = aws_instance.jenkins-machine.public_ip
# }


output "jenkins_public_ip" {
  value = module.ec2_jenkins.jenkins_public_ip
}


# terraform output -raw private_key_pem > key.pem